# Defined resource type: cloudstack::cluster
#
# This defined type is used to identify a CloudStack cluster
#
# Parameters:
# zonename (string):  The Cloudstack name of the parent zone
# podname (string):  The Cloudstack name of the parent pod
# clustertype (string):  Type of cluster - Either "CloudManaged" or "ExternalManaged".  The latter
#   is for vSphere clusters
# hypervisor (string):  Type of hypervisor to be used.  Valid values are:
#   XenServer, KVM, VMware, Hyperv, BareMetal, and Simulator 
#
# Actions:
#
# Requires:
#
#
# Sample Usage:
# cloudstack::cluster { 'samplecluster':
#   zone_dns => 'myinternaldns',
# }
#
define cloudstack::cluster (
  $zonename,
  $podname,
  $clustertype = 'CloudManaged',
  $hypervisor
) {
  validate_string($zonename)
  validate_string($podname)
  validate_string($clustertype)
  validate_re($clustertype, [ 'CloudManaged', 'ExternalManaged' ])
  validate_string($hypervisor)
  validate_re($hypervisor, [ 'XenServer', 'KVM', 'VMware', 'Hyperv', 'BareMetal', 'Simulator' ])

  #### NEED TO VERIFY THAT ZONEID AND PODID ARE VALID!
#  $teststring_zone = inline_template( "<%= \"http://localhost:\" +
#                 \"${cloudstack::params::mgmt_port}/?command=listZones&\" +
#                 \"available=true\" %>" )
#  $teststring_pod = inline_template( "<%= \"http://localhost:\" +
#                 \"${cloudstack::params::mgmt_port}/?command=listPods&\" +
#                 \"available=true\" %>" )
#  $teststring_cluster = inline_template( "<%= \"http://localhost:\" +
#                 \"${cloudstack::params::mgmt_port}/?command=listClusters&\" +
#                 \"available=true\" %>" )
#  $reststring = inline_template( "<%= \"http://localhost:\" +
#                 \"${cloudstack::params::mgmt_port}/?command=addCluster&\" +
#                 \"clustername=${name}&clustertype=${clustertype}&\" +
#                 \"hypervisor=${hypervisor}&zoneid=${zoneid}&\" +
#                 \"podid=${podid}\" %>" )
#
#  exec { "/usr/bin/curl \'${reststring}\'":
#    onlyif  => [
#      "/usr/bin/curl \'${teststring_zone}\' | grep ${zoneid}",
#      "/usr/bin/curl \'${teststring_pod}\' | grep ${podid}",
#      "/usr/bin/curl \'${teststring_cluster}\' | grep -v ${cluster}"
#    ],
#    require => Anchor['anchor_dbsetup_end']
#  }
  exec { "create_cluster_${name}_in_pod_${podname}_in_zone_${zonename}":
    command => "/usr/local/bin/cm_addcluster.sh \"${name}\" \"${clustertype}\" \"${hypervisor}\" \"${podname}\" \"${zonename}\"",
    require => [ Anchor['anchor_dbsetup_end'], Cloudstack::Pod[$podname] ]
  }
}
