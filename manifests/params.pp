#
# == Class: cloudstack::params
#
#   This class manages the CloudStack parameter defaults.
#
class cloudstack::params {
  $csversion = '4.2'
  $setup_repo = true
  $mgmt_port = '8096'
  $localdb = true
  $uses_xen = false
  $dbuser = 'cloud'
  $dbpassword = 'cloud'
  $dbhost = undef
  $dbdeployasuser = 'root'
  $dbrootpw = 'rootpw'
  $install_cloudmonkey = true
  $enable_remote_unauth_port = false

  if $::osfamily == 'RedHat' {
    $libvirt_service_name = 'libvirtd'
  } elsif $::operatingsystem == 'Ubuntu' {
    $libvirt_service_name = 'libvirt-bin'
  } else {
    fail('Unsupported operating system')
  }
}
