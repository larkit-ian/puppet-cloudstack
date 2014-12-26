#
# == Class: cloudstack::kvmagent
#
#   This class installs the base CloudStack KVM agent
#
# == Parameters
#
# == Actions
#
#   Install base cloudstack agent
#   Install Package['cloud-agent']
#   Run script Exec['cloud-setup-agent']
#
# == Requires
#
# == Sample Usage
#
class cloudstack::kvmagent (
  $csversion = '4.2',
  $setup_repo = true,
) {

  class { '::cloudstack::common':
    csversion  => $csversion,
    setup_repo => $setup_repo,
    before     => Package['cloudstack-agent']
  }

  package { [ 'cloudstack-agent', 'wget' ]:
    ensure  => present,
  }

########## We're okay up until this point...

  # FIXME: Need to configure libvirt... the following lines are needed in
  #   /etc/libvirt/libvirtd.conf (and must notify
  #   Service[$libvirt_service_name]:
  #     listen_tls = 0
  #     listen_tcp = 1
  #     tcp_port = "16059"
  #     auth_tcp = "none"
  #     mdns_adv = 0
  #
  #   ($::osfamily == 'RedHat') in /etc/sysconfig/libvirtd (notify after):
  #     LIBVIRTD_ARGS="--listen"
  #
  #   ($::operatingsystem == 'Ubuntu')
  #   	in /etc/default/libvirt-bin (notify after):
  #       libvirtd_opts="-d -l"
  #     in /etc/libvirt/qemu.conf (notify after):
  #       vnc_listen = 0.0.0.0
  #

  # Technically, this may be unnecessary...
  $libvirt_service_name = $::cloudstack::params::libvirt_service_name

  service { $libvirt_service_name:
    ensure    => running,
    hasstatus => true,
  }
  
  package { 'NetworkManager':
    ensure => absent;
  }

  service { 'network':
    ensure    => running,
    hasstatus => true,
    require   => Package['cloudstack-agent'],
  }

  # FIXME
  # Needs params
  #exec { '/usr/bin/cloudstack-setup-agent':
  #  creates  => '/var/log/cloud/setupAgent.log',
  #  require => [
  #    Package[   'cloudstack-agent'                               ],
  #    File[      '/etc/cloudstack/agent/agent.properties'         ],
  #    File_line[ 'cs_sudo_rule'                              ],
  #    Host[      'localhost'                                 ],
  #  ],
  #}


  file { '/etc/cloudstack/agent/agent.properties':
    ensure  => present,
    require => Package['cloudstack-agent'],
    content => template('cloudstack/agent.properties.erb'),
  }

################## Firewall stuff #########################
#

  firewall { '001 first range ':
    proto  => 'tcp',
    dport  => '49152-49216',
    action => 'accept',
  }

  firewall { '191 VNC rules':
    proto  => 'tcp',
    dport  => '5900-6100',
    action => 'accept',
  }

  firewall { '192 port 16509':
    proto  => 'tcp',
    dport  => '16509',
    action => 'accept',
  }

# Need to do something that will take care of KVM - make sure module is loaded
# - need to define what tests cloud-setup-agent actually runs to test for KVM
# and ensure that we do those tests as well, and rectify if needed (reboot?? )
# Need to handle hostname addition as well
#- and probably a def gw and ensuring that DNS is set since


### Require network to be enable
### Require NetworkManager be disabled (Is it installed by default, do we need to do a case?, perhaps we 'ensure absent')
### Make sure we cycle network after deploying a ifcfg.
### Do we handle creation of cloud-br0? I am thinking not, seems like there's a lot of magic there. For now, lets stay away from that.

}
