#
# == Defined resource type: cloudstack::pod
#
#   This defined type is used to identify a CloudStack pod
#
# == Parameters
#
#   zonename (string): Zone name in which the pod is to reside.
#
#   startip (string): Starting IP address for the pod.
#
#   netmask (string): Netmask for the pod.
#
#   endip (string): Ending IP address for the pod.
#
#   gateway (string): Default Gateway for the pod.
#
# == Actions
#
#   Uses Cloudmonkey to create a pod within a Cloudstack zone.
#
# == Requires
#
# == Sample Usage
#
#   cloudstack::pod { 'samplezone':
#     zonename => 'zone1'
#     startip  => '192.168.99.50',
#     netmask  => '255.255.255.0',
#     endip    => '192.168.99.100',
#     gateway  => '192.168.99.1',
#   }
#
# == Notes
#
#   FIXME:  Make this use the API again rather than cloudmonkey
#
define cloudstack::pod(
  $zonename,
  $startip,
  $netmask,
  $endip,
  $gateway
) {

  validate_string($zonename)
  validate_string($startip)
  validate_string($netmask)
  validate_string($endip)
  validate_string($gateway)

  # Things we need from the outside
  $mgmt_port = $::cloudstack::mgmt_port

  $execparms1 = "\"${name}\" \"${zonename}\""
  $execparms2 = "\"${gateway}\" \"${netmask}\" \"${startip}\" \"${endip}\""

  include ::cloudstack

  #$teststring_zone = inline_template( "<%= \"http://localhost:\" +
  #               \"${::cloudstack::mgmt_port}/?command=listZones&\" +
  #               \"available=true\" %>" )
  #$teststring_pod = inline_template( "<%= \"http://localhost:\" +
  #               \"${::cloudstack::mgmt_port}/?command=listPods&\" +
  #               \"available=true\" %>" )
  #$reststring = inline_template( "<%= \"http://localhost:\" +
  #               \"${::cloudstack::mgmt_port}/?command=createPod&\" +
  #               \"gateway=${gateway}&name=${name}&netmask=${netmask}&\" +
  #               \"startip=${startip}&endip=${endip}&zoneid=${zoneid}\" %>" )

  # Is the zone there?
  #
  exec { "create_pod_${name}_in_zone_${zonename}":
    command => "/usr/local/bin/cm_createpod.sh ${execparms1} ${execparms2}",
    require => [
      Class['::cloudstack::cloudmonkey'],
      Cloudstack::Zone[$zonename]
    ]
  }
}
