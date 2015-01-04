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

  # Variables

  $mgmt_port  = $::cloudstack::mgmt_port
  $ospath     = $::cloudstack::params::ospath
  $list_pod   = $::cloudstack::params::list_pod_cmd
  $create_pod = $::cloudstack::params::create_pod_cmd

  $teststring = "curl -s \'http://localhost:${mgmt_port}/?command=listPods&name=${name}&response=default\' | xgrep -s \'pod:zonename/${zonename}/,name/${name}/\'"

  $createparm1 = "\"${name}\" \"${zonename}\""
  $createparm2 = "\"${gateway}\" \"${netmask}\" \"${startip}\" \"${endip}\""

  # Validations

  validate_string($zonename)
  validate_string($startip)
  validate_string($netmask)
  validate_string($endip)
  validate_string($gateway)

  # Resource declarations.  Start with includes.

  include ::cloudstack::params
  include ::cloudstack::cloudmonkey

  exec { "create_pod__${name}__in_zone__${zonename}":
    command => "${create_pod} ${createparm1} ${createparm2}",
    #unless  => "${list_pod} ${zonename} ${name}",
    unless  => "${teststring} | grep -q ${name} 2>/dev/null",
    path    => $ospath
  }

  # Finally, our dependencies...

  Package['xgrep']                   -> Exec["create_pod__${name}__in_zone__${zonename}"]
  Class['::cloudstack::cloudmonkey'] -> Exec["create_pod__${name}__in_zone__${zonename}"]
  Cloudstack::Zone[$zonename]        -> Exec["create_pod__${name}__in_zone__${zonename}"]
}
