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
  $enable_aws_api = false
  $list_cluster_cmd = 'cm_list_cluster.sh'
  $create_cluster_cmd = 'cm_create_cluster.sh'
  $list_pod_cmd = 'cm_list_pod.sh'
  $create_pod_cmd = 'cm_create_pod.sh'
  $zone_dns = '8.8.8.8'
  $zone_internal_dns = '8.8.8.8'
  $networktype = 'Basic'
  $networktypetypes = [ '^Basic$', '^Advanced$' ]
  $clustertype = 'CloudManaged'
  $clustertypetypes = [ '^CloudManaged$', '^ExternalManaged$' ]
  $hypervisortypes = [ '^XenServer$', '^KVM$', '^VMware$',
    '^Hyperv$', '^BareMetal$', '^Simulator$' ]

  $vhd_url  = 'http://download.cloud.com.s3.amazonaws.com/tools/vhd-util'
  $vhd_path = '/usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver'

  $cs_needed_ports = [
    '80',   # FIXME: Not sure why this is needed, but...
    '3922', # "Secure System secure communication port" - Not my naming!
    '8250', # "System VM to management unsecured communication port"
    '8080',  # "Cloudstack cluster management port"
    '9090'  # "Cloudstack cluster management port"
  ]

  case $::operatingsystem {
    'centos', 'redhat', 'fedora', 'scientific': {
      $libvirt_service_name = 'libvirtd'
      $ospath = '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin'
      $cm_unneeded_pkglist1 = 'python-boto'
      $cm_unneeded_pkglist2 = 'python-requests'
      $cm_unneeded_package_flag = true
    }
    'ubuntu': {
      $libvirt_service_name = 'libvirt-bin'
      $ospath = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
      $cm_unneeded_package_flag = false
    }
    default: { fail('Unsupported operating system') }
  }
}
