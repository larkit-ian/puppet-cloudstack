#
# == Class: cloudstack::service
#
# This class ensures that the required Cloudstack services
# are running.
#
class cloudstack::service {
  service { 'cloudstack-management':
    ensure    => running,
    enable    => true,
    hasstatus => true,
    require   => Anchor['anchor_misc_end']
  }
}
