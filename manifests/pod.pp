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

  $createparm1 = "\"${name}\" \"${zonename}\""
  $createparm2 = "\"${gateway}\" \"${netmask}\" \"${startip}\" \"${endip}\""

  include ::cloudstack
  include ::cloudstack::params
  include ::cloudstack::cloudmonkey

  $list_pod_t = $::cloudstack::params::list_pod_cmd
  $list_pod = inline_template("/usr/local/bin/<%= @list_pod_t %>")
  $create_pod_t = $::cloudstack::params::create_pod_cmd
  $create_pod = inline_template("/usr/local/bin/<%= @create_pod_t %>")

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
    command => "${create_pod} ${createparm1} ${createparm2}",
    unless  => "${list_pod} ${zonename} ${name}",
    require => [
      Class['::cloudstack::cloudmonkey'],
      Cloudstack::Zone[$zonename]
    ]
  }
}
