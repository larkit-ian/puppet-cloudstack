# Defined resource type: cloudstack::pod
#
# This defined type is used to identify a CloudStack pod
#
# Parameters:
# (optional) zone_dns - The 1st external DNS server
# (optional) zone_dns2 - The 2nd external DNS server
# (optional) zone_internal_dns - The 1st internal DNS server
# (optional) zone_internal_dns2 - The 2nd internal DNS server
# (optional) networktype - Network type to use for zone.  Valid options are
#
# Actions:
#
# Requires:
#
#
# Sample Usage:
# cloudstack::pod { 'samplezone':
#   zone_dns => 'myinternaldns',
# }
#
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
    command => "/usr/local/bin/cm_createpod \"${name}\" \"${zonename}\" \"${gateway}\" \"${netmask}\" \"${startip}\" \"${endip}\"",
    require => [ Anchor['anchor_dbsetup_end'], Cloudstack::Zone[$zonename] ]
  }
}
