#
# == Defined resource type: cloudstack::cluster
#
#   This defined type is used to identify a CloudStack cluster
#
# == Parameters
#
#   zonename (string):  The Cloudstack name of the parent zone.
#
#   podname (string):  The Cloudstack name of the parent pod.
#
#   hypervisor (string):  Type of hypervisor to be used.  Valid values are:
#     'XenServer', 'KVM', 'VMware', 'Hyperv', 'BareMetal', and 'Simulator'. 
#
#   (optional) clustertype (string):  Type of cluster.
#     Set to either 'CloudManaged' (default) or 'ExternalManaged' (for
#     vSphere clusters).
#
# == Actions
#
#   Uses Cloudmonkey to create a cluster within a pod in a Cloudstack
#   zone.
#
# == Requires
#
# == Sample Usage
#
#   cloudstack::cluster { 'samplecluster':
#     zonename    => 'myzone1',
#     podname     => 'mypod1',
#     hypervisor  => 'KVM',
#   }
#
# == Notes
#
define cloudstack::cluster (
  $zonename,
  $podname,
  $hypervisor,
  $clustertype = 'CloudManaged'
) {
  validate_string($zonename)
  validate_string($podname)
  validate_string($hypervisor)
  validate_re($hypervisor, [
    'XenServer', 'KVM', 'VMware',
    'Hyperv', 'BareMetal', 'Simulator'
  ])
  validate_string($clustertype)
  validate_re($clustertype, [ 'CloudManaged', 'ExternalManaged' ])

  # Things we need from the outside
  $mgmt_port = $::cloudstack::mgmt_port

  $createparm1 = "\"${name}\" \"${clustertype}\""
  $createparm2 = "\"${hypervisor}\" \"${podname}\" \"${zonename}\""
  
  include ::cloudstack
  include ::cloudstack::params
  include ::cloudstack::cloudmonkey

  $list_cluster_t = $::cloudstack::params::list_cluster_cmd
  $list_cluster = inline_template("/usr/local/bin/<%= @list_cluster_t %>")
  $create_cluster_t = $::cloudstack::params::create_cluster_cmd
  $create_cluster = inline_template("/usr/local/bin/<%= @create_cluster_t %>")

  #### NEED TO VERIFY THAT ZONEID AND PODID ARE VALID!
#  $teststring_zone = inline_template( "<%= \"http://localhost:\" +
#                 \"${::cloudstack::mgmt_port}/?command=listZones&\" +
#                 \"available=true\" %>" )
#  $teststring_pod = inline_template( "<%= \"http://localhost:\" +
#                 \"${::cloudstack::mgmt_port}/?command=listPods&\" +
#                 \"available=true\" %>" )
#  $teststring_cluster = inline_template( "<%= \"http://localhost:\" +
#                 \"${::cloudstack::mgmt_port}/?command=listClusters&\" +
#                 \"available=true\" %>" )
#  $reststring = inline_template( "<%= \"http://localhost:\" +
#                 \"${::cloudstack::mgmt_port}/?command=addCluster&\" +
#                 \"clustername=${name}&clustertype=${clustertype}&\" +
#                 \"hypervisor=${hypervisor}&zoneid=${zoneid}&\" +
#                 \"podid=${podid}\" %>" )
#
#  exec { "/usr/bin/curl \'${reststring}\'":
#    onlyif  => [
#      "/usr/bin/curl \'${teststring_zone}\' | grep ${zoneid}",
#      "/usr/bin/curl \'${teststring_pod}\' | grep ${podid}",
#      "/usr/bin/curl \'${teststring_cluster}\' | grep -v ${cluster}"
#    ]
#  }
  exec { "create_cluster_${name}_in_pod_${podname}_in_zone_${zonename}":
    command => "${create_cluster} ${createparm1} ${createparm2}",
    unless  => "${list_cluster} ${zonename} ${podname} ${name}",
    require => [
      Class['::cloudstack::cloudmonkey'],
      Cloudstack::Pod[$podname]
    ]
  }
}
