#
# == Class: cloudstack::install
#
#   This class installs the base CloudStack components for a management
#   server.
#
# == Parameters
#
# == Actions
#   Install cloudstack-management package (and dependencies, including repo
#     setup for $::osfamily == 'RedHat' and additional stuff for Ubuntu)
#   Install the cloudstack-management package
#   Download and install vhd_util if we’re using Xen
#     ($::cloudstack::uses_xen = true)
#   Install cloud database only if MySQL is installed and configured
#     ($::cloudstack::localdb = true)
#   Install cloudmonkey
#
# == Requires
#   (optional) puppetlabs/mysql
#
# == Notes
# 
class cloudstack::install inherits cloudstack::params {

  # Variables

  $csversion            = $::cloudstack::csversion
  $setup_repo           = $::cloudstack::setup_repo
  $localdb              = $::cloudstack::localdb
  $uses_xen             = $::cloudstack::uses_xen
  $dbhost               = $::cloudstack::dbhost
  $dbrootpw             = $::cloudstack::dbrootpw
  $install_cloudmonkey  = $::cloudstack::install_cloudmonkey
  $vhd_url              = $::cloudstack::params::vhd_url
  $vhd_path             = $::cloudstack::params::vhd_path
  $vhd_download_command = "wget ${vhd_url} -O ${vhd_path}/vhd_util"
  $ospath               = $::cloudstack::params::ospath

  $mysql_override_options = {
    'mysqld' => {
      'innodb_rollback_on_timeout' => '1',
      'innodb_lock_wait_timeout'   => '500',
      'max_connections'            => '350'
    }
  }

  # Resources

  if $install_cloudmonkey {
    include cloudstack::cloudmonkey
  }

  class { '::cloudstack::common':
    csversion  => $csversion,
    setup_repo => $setup_repo,
  }
  
  # Fix for known bug in 4.3 release...
  if $::operatingsystem == 'Ubuntu' and $csversion == '4.3' {
    package { 'libmysql-java': ensure => installed }
  }

  package { 'cloudstack-management': ensure => installed }
  package { 'lsof': ensure => installed } # For checking if the unauth port
                                        #   is listening

  if $uses_xen {
    exec { 'download_vhd_util':
      command => $vhd_download_command,
      creates => "${vhd_path}/vhd_util",
      path    => $ospath
    }
    file { 'vhd_util':
      ensure => present,
      path   => "${vhd_path}/vhd_util",
      owner  => 'root',
      group  => 'root',
      mode   => '0755'
      # FIXME:  Need to set SELinux permissions...
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
    Anchor['cs_swinstall_end']

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
