# == Class: cloudstack::install
#
# This class installs the base CloudStack components for a management
# server.
#
# == Parameters
#
# == Actions
#   Install cloudstack-management package (and dependencies, including repo
#     setup for $::osfamily == 'RedHat' and additional stuff for Ubuntu)
#   Install the cloudstack-management package
#   Download and install vhd_util if we’re using Xen ($::cloudstack::uses_xen = true)
#   Install cloud database only if MySQL is installed and configured ($::cloudstack::localdb = true)
#   Install cloudmonkey
#
# == Requires
#   (optional) puppetlabs/mysql
#
class cloudstack::install {
  # Setup the repo.
  if $::cloudstack::setup_repo == true and $::osfamily == 'RedHat' {
    yumrepo{ 'cloudstack':
      ensure   => present,
      descr    => "Cloudstack ${::cloudstack::csversion} repository",
      baseurl  => "http://cloudstack.apt-get.eu/rhel/${::cloudstack::csversion}/",
      enabled  => '1',
      gpgcheck => '0',
      before   => Package['cloudstack-management']
    }
  }

  # Fix for known bug in 4.3 release...
  if $::operatingsystem == 'Ubuntu' and $::cloudstack::csversion == '4.3' {
    package { 'libmysql-java':
      ensure => installed,
      before => Package['cloudstack-management']
    }
  }

  package { 'cloudstack-management':
    ensure => latest,
    before => Anchor['anchor_swinstall_end']
  }

  package { 'wget': ensure => present } # Not needed after 2.2.9, see bug 11258

  # We may need vhd-util...
  if $::cloudstack::uses_xen == true {
    $vhd_url  = 'http://download.cloud.com.s3.amazonaws.com/tools/vhd-util'
    $vhd_path = '/usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver'
    $vhd_download_command = "/usr/bin/wget ${vhd_url} -O ${vhd_path}/vhd_util"

    exec { 'download_vhd_util':
      command => $vhd_download_command,
      creates => "${vhd_path}/vhd_util",
      require => Package[ 'cloudstack-management', 'wget' ],
      before  => File['vhd_util']
    }
    file { 'vhd_util':
      ensure => present,
      path   => "${vhd_path}/vhd_util",
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      # FIXME:  Need to set SELinux permissions...
      before => Anchor['anchor_swinstall_end']
    }
  }

  # And now we come to the end of software installation.
  anchor { 'anchor_swinstall_end': }

  $remotedbhost = $::cloudstack::localdb ? {
    true  => 'localhost',
    false => $::cloudstack::dbhost
  }

  if $::cloudstack::localdb == true {
    $override_options = {
      'mysqld' => {
        'innodb_rollback_on_timeout' => '1',
        'innodb_lock_wait_timeout'   => '500',
        'max_connections'            => '350'
      }
    }
    class { '::mysql::server':
      root_password           => $::cloudstack::dbrootpw,
      override_options        => $override_options,
      remove_default_accounts => true,
      service_enabled         => true,
      require                 => Anchor['anchor_swinstall_end'],
    }
  }

  # If we want cloudmonkey...
  if $::cloudstack::install_cloudmonkey {
    include cloudstack::cloudmonkey
  }
}
