#
## Defined resource type: cloudstack::zone
#
# This defined type is used to identify a CloudStack zone
#
# Parameters:
# (optional) zone_dns (string): The 1st external DNS server
# (optional) zone_dns2 (string): The 2nd external DNS server
# (optional) zone_internal_dns (string): The 1st internal DNS server
# (optional) zone_internal_dns2 (string): The 2nd internal DNS server
# (optional) networktype (string): Network type to use for zone.  Valid options are
#   "Advanced" and "Basic".
# (optional) networkdomain (string): DNS domain to use for zone.  Valid options are
#
# Actions:
#
# Requires:
#
#
# Sample Usage:
# cloudstack::zone { 'samplezone':
#   zone_dns => 'myinternaldns',
# }
#
define cloudstack::zone(
  $zone_dns              = '8.8.8.8',
  $zone_dns2             = '4.4.4.4',
  $zone_internal_dns     = '8.8.8.8',
  $zone_internal_dns2    = '4.4.4.4',
  $networktype           = 'Basic',
  $networkdomain         = '',
) {
  validate_string($zone_dns)
  validate_string($zone_dns2)
  validate_string($zone_internal_dns)
  validate_string($zone_internal_dns2)
  validate_string($networktype)
  validate_re($networktype, [ '^Basic$', '^Advanced$' ])
  validate_string($networkdomain)

  include cloudstack::mgmt

  $mgmt_port = $cloudstack::mgmt::mgmt_port

  $teststring = template('cloudstack/zone-teststring.erb')
  $reststring = template('cloudstack/zone-reststring.erb')

  exec { "check_zone_exists_${name}":
    command => "/usr/bin/curl ${reststring}",
    unless  => "/usr/bin/curl -s \"${teststring}\" | /bin/grep -q ${name} 2>/dev/null",
    require => Anchor['anchor_dbsetup_end'],
  }
}
