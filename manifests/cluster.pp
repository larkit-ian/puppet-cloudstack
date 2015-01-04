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
  $create_cluster   = $::cloudstack::params::create_cluster_cmd

  $teststring = "curl -s \'http://localhost:${mgmt_port}/?command=listClusters&name=${name}&response=default\' | xgrep -s \'cluster:zonename/${zonename}/,podname/${podname}/,name/${name}/\'"

  $createparm1 = "\"${name}\" \"${clustertype}\""
  $createparm2 = "\"${hypervisor}\" \"${podname}\" \"${zonename}\""

  # Validations

  validate_string($zonename)
  validate_string($podname)
  validate_string($hypervisor)
  validate_re($hypervisor, $hypervisortypes)
  validate_string($clustertype)
  validate_re($clustertype, $clustertypetypes)

  # Resource declarations.  Start with includes.

  include ::cloudstack::params
  include ::cloudstack::cloudmonkey

  exec { "create_cluster__${name}__in_pod__${podname}__in_zone__${zonename}":
    command => "${create_cluster} ${createparm1} ${createparm2}",
    unless  => "${teststring} | grep -q ${name} 2>/dev/null",
    path    => $ospath
  }

  # Finally, our dependencies...

  Package['xgrep'] ->
    Exec["create_cluster__${name}__in_pod__${podname}__in_zone__${zonename}"]
  Class['::cloudstack::cloudmonkey'] ->
    Exec["create_cluster__${name}__in_pod__${podname}__in_zone__${zonename}"]
  Cloudstack::Pod[$podname] ->
    Exec["create_cluster__${name}__in_pod__${podname}__in_zone__${zonename}"]
}
