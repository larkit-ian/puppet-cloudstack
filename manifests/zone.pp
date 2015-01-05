#
# == Defined resource type: cloudstack::zone
#
#   This defined type is used to create a CloudStack zone
#
# == Parameters
#
#   (optional) zone_dns (string): The 1st external DNS server.
#     Default is '8.8.8.8'.
#
#   (optional) zone_dns2 (string): The 2nd external DNS server.
#
#   (optional) zone_internal_dns (string): The 1st internal DNS server.
#     Default is '8.8.8.8'.
#
#   (optional) zone_internal_dns2 (string): The 2nd internal DNS server.
#
#   (optional) networktype (string): Network type to use for zone.
#     Valid options are 'Advanced' and 'Basic'.  Default is 'Basic'.
#
#   (optional) networkdomain (string): DNS domain to use for zone.
#
# == Actions
#
#   Uses API calls via curl to create a new Cloudstack zone with
#   the specified parameters, unless it already exists.
#
# == Requires
#
# == Sample Usage
#
#   $extdns1 = '8.8.8.8'
#   $extdns2 = '4.2.2.2'
#   $myinternaldns1 = '192.168.1.101'
#   $myinternaldns1 = '192.168.1.102'
#
#   cloudstack::zone { 'samplezone':
#     zone_dns           => $extdns1,
#     zone_dns2          => $extdns2,
#     zone_internal_dns  => $myinternaldns1,
#     zone_internal_dns2 => $myinternaldns2,
#     networktype        => 'Advanced',
#     networkdomain      => 'sample.com'
#   }
#
# == Notes
#
#   There's some Ruby logic in the template used by this class.  It
#   determines whether optional parameters have been passed and adds them
#   to the REST line as needed.
#
define cloudstack::zone (
  $zone_dns              = $::cloudstack::params::zone_dns,
  $zone_dns2             = '',
  $zone_internal_dns     = $::cloudstack::params::zone_internal_dns,
  $zone_internal_dns2    = '',
  $networktype           = $::cloudstack::params::networktype,
  $networkdomain         = ''
) {

  # Variables

  $mgmt_port        = $::cloudstack::mgmt_port
  $ospath           = $::cloudstack::params::ospath
  $networktypetypes = $::cloudstack::params::networktypetypes

  $teststring = "curl -s \'http://localhost:${mgmt_port}/?command=listZones&name=${name}&response=default\' | xgrep -s \'zone:name/${name}/\'"
  $reststring = template('cloudstack/zone-reststring.erb')

  # Validations

  validate_string($zone_dns)
  validate_string($zone_dns2)
  validate_string($zone_internal_dns)
  validate_string($zone_internal_dns2)
  validate_string($networktype)
  validate_re($networktype, $networktypetypes)
  validate_string($networkdomain)

  # Resource declarations.  Start with includes.

  include ::cloudstack
  include ::cloudstack::params

  exec { "create_zone__${name}":
    command => "curl ${reststring}",
    unless  => "${teststring} | grep -q ${name} 2>/dev/null",
    path    => $ospath
  }

  exec { "cache_zone__${name}":
    command => "curl \'http://localhost:${mgmt_port}/?command=listZones&name=${name}&response=default\' | xgrep -s \'zone:name/${name}/\' | grep \'<id>\' | sed -e \'s/<[^>]*>//g\' | awk \'{print \$1}\' > /var/tmp/cs_zoneid__${name}",
    creates => "/var/tmp/cs_zoneid__${name}",
    path    => $ospath
  }

  # Finally, our dependencies...

  Package['xgrep']                 -> Exec["create_zone__${name}"]
  Service['cloudstack-management'] -> Exec["create_zone__${name}"]
  Exec['enable_mgmt_port']         -> Exec["create_zone__${name}"]

  Exec["create_zone__${name}"] -> Exec["cache_zone__${name}"]
}
