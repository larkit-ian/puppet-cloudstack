# Defined resource type: cloudstack::pod
#
# This defined type is used to identify a CloudStack pod
#
# Parameters:
# gateway - Default Gateway for the pod
# netmask - Netmask for the pod
# startip - Starting IP address for the pod
# endip - Ending IP address for the pod
# zonename - Zone name to use for the pod
#
# Actions:
#
# Requires:
#
#
# Sample Usage:
# cloudstack::pod { 'samplezone':
#   gateway  => '192.168.99.1',
#   netmask  => '255.255.255.0',
#   startip  => '192.168.99.50',
#   endip    => '192.168.99.100',
#   zonename => 'zone1'
# }
#
# FIXME:  Make this use the API again rather than cloudmonkey eventually...
# #
define cloudstack::pod(
  $gateway,
  $netmask,
  $startip,
  $endip,
  $zonename
) {

  validate_string($gateway)
  validate_string($netmask)
  validate_string($startip)
  validate_string($endip)
  validate_string($zonename)

  include cloudstack::mgmt

  $mgmt_port = $cloudstack::mgmt::mgmt_port

  #$teststring_zone = inline_template( "<%= \"http://localhost:\" +
  #               \"${cloudstack::params::mgmt_port}/?command=listZones&\" +
  #               \"available=true\" %>" )
  #$teststring_pod = inline_template( "<%= \"http://localhost:\" +
  #               \"${cloudstack::params::mgmt_port}/?command=listPods&\" +
  #               \"available=true\" %>" )
  #$reststring = inline_template( "<%= \"http://localhost:\" +
  #               \"${cloudstack::params::mgmt_port}/?command=createPod&\" +
  #               \"gateway=${gateway}&name=${name}&netmask=${netmask}&\" +
  #               \"startip=${startip}&endip=${endip}&zoneid=${zoneid}\" %>" )

  # Is the zone there?
  #
  exec { "create_pod_${name}_in_zone_${zonename}":
    command => "/usr/local/bin/cm_createpod.sh \"${name}\" \"${zonename}\" \"${gateway}\" \"${netmask}\" \"${startip}\" \"${endip}\"",
    require => [ Anchor['anchor_dbsetup_end'], Cloudstack::Zone[$zonename] ]
  }
}
