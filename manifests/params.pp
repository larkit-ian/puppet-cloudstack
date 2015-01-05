#
# == Class: cloudstack::params
#
#   This class manages the CloudStack parameter and variable defaults.
#
# == Notes
#
#   All of these variables need to be documented somewhere...
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
  $create_cluster_cmd = 'cm_create_cluster.sh'
  $create_pod_cmd = 'cm_create_pod.sh'
  $zone_dns = '8.8.8.8'
  $zone_internal_dns = '8.8.8.8'
  $networktype = 'Basic'
  $networktypetypes = [ '^Basic$', '^Advanced$' ]
  $clustertype = 'CloudManaged'
  $clustertypetypes = [ '^CloudManaged$', '^ExternalManaged$' ]
  $hypervisortypes = [ '^XenServer$', '^KVM$', '^VMware$',
    '^Hyperv$', '^BareMetal$', '^Simulator$' ]
  $hypervisortypes_small = [ '^xenserver$', '^kvm$', '^vmware$', '^hyperv$' ]
  $manage_firewall = false
  $sysvm_url_kvm = 'http://download.cloud.com/releases/2.2.0/systemvm.qcow2.bz2'
  $sysvm_url_xen = 'http://download.cloud.com/releases/2.2.0/systemvm.vhd.bz2'

  # Want do use Xenserver?  You'll need vhd-util.  Here's the current URL
  # and where we place it on the management server:

  $vhd_url  = 'http://download.cloud.com.s3.amazonaws.com/tools/vhd-util'
  $vhd_path = '/usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver'

  # Documented ports for firewalling...

  $cs_needed_ports = [
    '3922', # "Secure System secure communication port" - Not my naming!
    '8250', # "System VM to management unsecured communication port"
    '8080',  # "Cloudstack cluster management port"
    '9090'  # "Cloudstack cluster management port"
  ]

  # OS-specific items...

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
