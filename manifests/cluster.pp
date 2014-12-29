#
# == Defined resource type: cloudstack::cluster
#
#   Create a Cloudstack Cluster object inside a specified pod and zone
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
  $clustertype = $::cloudstack::params::clustertype
) {

  # Variables

  $mgmt_port        = $::cloudstack::mgmt_port
  $ospath           = $::cloudstack::params::ospath
  $hypervisortypes  = $::cloudstack::params::hypervisortypes
  $clustertypetypes = $::cloudstack::params::clustertypetypes
  $list_cluster     = $::cloudstack::params::list_cluster_cmd
  $create_cluster   = $::cloudstack::params::create_cluster_cmd

  $createparm1 = "\"${name}\" \"${clustertype}\""
  $createparm2 = "\"${hypervisor}\" \"${podname}\" \"${zonename}\""


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

  # Validations

  validate_string($zonename)
  validate_string($podname)
  validate_string($hypervisor)
  validate_re($hypervisor, $hypervisortypes)
  validate_string($clustertype)
  validate_re($clustertype, $clusttertypetypes)

  # Resource declarations.  Start with includes.

  include ::cloudstack::cloudmonkey

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
    path    => $ospath
  }

  # Finally, our dependencies...

  Class['::cloudstack::cloudmonkey'] -> Exec["create_cluster_${name}_in_pod_${podname}_in_zone_${zonename}"]
  Cloudstack::Pod[$podname] -> Exec["create_cluster_${name}_in_pod_${podname}_in_zone_${zonename}"]
}
