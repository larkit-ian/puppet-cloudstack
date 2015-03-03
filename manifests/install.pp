#
# == Class: cloudstack::install
#
#   This class installs the base CloudStack components for a management
#   server.
#
# == Parameters
#
# == Actions
#   Install cloudmonkey.
#   Install cloudstack-management package (and dependencies, including repo
#     setup for $::osfamily == 'RedHat' and additional stuff for Ubuntu).
#   Download and install vhd_util if we’re using Xen.
#     ($::cloudstack::uses_xen = true)
#   If desired, install mysql using (via puppetlabs/mysql) to host the
#     database.
#     ($::cloudstack::localdb = true)
#
# == Requires
#   (optional) puppetlabs/mysql
#
# == Sample Usage
#
#   This class isn't intended to be called directly.
#
# == Notes
#   FIXME: (RHEL only) Need to check for IBM java and fail if it's installed.
# 
class cloudstack::install inherits cloudstack::params {

  # Variables

  $csversion            = $::cloudstack::csversion
  $setup_repo           = $::cloudstack::setup_repo
  $repo_override_url    = $::cloudstack::repo_override_url
  $localdb              = $::cloudstack::localdb
  $uses_xen             = $::cloudstack::uses_xen
  $dbhost               = $::cloudstack::dbhost
  $dbrootpw             = $::cloudstack::dbrootpw
  $install_cloudmonkey  = $::cloudstack::install_cloudmonkey
  $manage_firewall      = $::cloudstack::manage_firewall

  $vhd_url              = $::cloudstack::params::vhd_url
  $vhd_path             = $::cloudstack::params::vhd_path
  $ospath               = $::cloudstack::params::ospath
  $fix_db_bug_43        = $::cloudstack::fix_db_bug_43

  $vhd_download_command = "wget ${vhd_url} -O ${vhd_path}/vhd_util"

  $mysql_override_options = {
    'mysqld' => {
      'innodb_rollback_on_timeout' => '1',
      'innodb_lock_wait_timeout'   => '500',
      'max_connections'            => '350'
    }
  }

  $cs_limits = "cloud soft nproc -1
     cloud hard nproc -1
     cloud hard nofile 4096
     cloud soft nofile 4096
     "


  # Resources

  if $install_cloudmonkey {
    include cloudstack::cloudmonkey
  }

  class { '::cloudstack::common':
    csversion         => $csversion,
    setup_repo        => $setup_repo,
    manage_firewall   => $manage_firewall,
    repo_override_url => $repo_override_url
  }
  
  # Fix for known bug in 4.3 release... I'd love to abstract this out,
  # remove the OS hardcoding, and remove the double-if for this (see the bottom
  # of this manifest), but it would most likely obscure the logic.
  # Not a net win, IMHO, so it stays here...

  if $::operatingsystem == 'Ubuntu' and $csversion == '4.3' {
    package { 'libmysql-java': ensure => installed }
  }

  package { 'cloudstack-management': ensure => installed }
  package { 'lsof': ensure => installed } # For checking if the unauth port
                                        #   is listening

  # Fix for CLOUDSTACK-8157

  if $fix_db_bug_43 and $csversion == '4.3' and $::osfamily == 'RedHat' {
    file { '/usr/share/cloudstack-management/setup/create-schema-premium.sql-CS8157':
      ensure => present,
      source => 'puppet:///modules/cloudstack/create-schema-premium.sql-CS8157'
    }
    exec { 'patch_cs43':
      command => 'cd /usr/share/cloudstack/setup/db ; /bin/cp -f create-schema-premium.sql-CS8157 create-schema-premium.sql',
      unless => 'diff /usr/share/cloudstack-management/setup/create-schema-premium.sql'
    }
  }

  file { '/etc/security/limits.d/cloudstack-limits.conf':
    ensure   => present,
    owner    => 'root',
    group    => 'root',
    mode     => '0644',
    seluser  => 'system_u',
    selrole  => 'object_r',
    seltype  => 'usr_t',
    selrange => 's0',
    content  => $cs_limits
  }

  if $uses_xen {
    exec { 'download_vhd_util':
      command => $vhd_download_command,
      creates => "${vhd_path}/vhd_util",
      path    => $ospath
    }
    file { 'vhd_util':
      ensure   => present,
      path     => "${vhd_path}/vhd_util",
      owner    => 'root',
      group    => 'root',
      mode     => '0755',
      seluser  => 'system_u',
      selrole  => 'object_r',
      seltype  => 'usr_t',
      selrange => 's0'
    }
  }

  $remotedbhost = $localdb ? {
    true  => 'localhost',
    false => $dbhost
  }

  if $localdb == true {
    class { '::mysql::server':
      root_password           => $dbrootpw,
      override_options        => $mysql_override_options,
      remove_default_accounts => true,
      service_enabled         => true
    }
  }

  anchor { 'cs_swinstall_end': }

  # Dependencies

  if $::operatingsystem == 'Ubuntu' and $csversion == '4.3' {
    Package['libmysql-java'] -> Package['cloudstack-management']
  }
  if $setup_repo and $::osfamily == 'RedHat' {
    Yumrepo['cloudstack'] -> Package['cloudstack-management']
  }
  Anchor['cs_common_complete'] ->
    Package['cloudstack-management'] ->
    File['/etc/security/limits.d/cloudstack-limits.conf'] ->
    Anchor['cs_swinstall_end']

  if $fix_db_bug_43 and $csversion == '4.3' and $::osfamily == 'RedHat' {
    Package['cloudstack-mamagement'] ->
      File['/usr/share/cloudstack-management/setup/create-schema-premium.sql-CS8157'] ->
      Exec['patch_cs43'] ->
      Anchor['cs_swinstall_end']
  }

  if $uses_xen {
    #Package['wget'] -> Exec['download_vhd_util']
    Package['cloudstack-management'] ->
      Exec['download_vhd_util'] ->
      File['vhd_util'] ->
      Anchor['cs_swinstall_end']
  }
  if $localdb {
    Anchor['cs_swinstall_end'] -> Class['::mysql::server']
  }
}
