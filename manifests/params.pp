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
  $list_cluster_cmd = 'cm_list_cluster.sh'
  $create_cluster_cmd = 'cm_create_cluster.sh'
  $list_pod_cmd = 'cm_list_pod.sh'
  $create_pod_cmd = 'cm_create_pod.sh'

  if $::osfamily == 'RedHat' {
    $libvirt_service_name = 'libvirtd'
  } elsif $::operatingsystem == 'Ubuntu' {
    $libvirt_service_name = 'libvirt-bin'
  } else {
    fail('Unsupported operating system')
  }
}
