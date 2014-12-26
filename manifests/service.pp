#
# == Class: cloudstack::service
#
# This class ensures that the required Cloudstack services
# are running.
#
class cloudstack::service {

  include ::cloudstack

  service { 'cloudstack-management':
    ensure    => running,
    enable    => true,
    hasstatus => true,
    require   => Anchor['end_of_misc']
  }
}
