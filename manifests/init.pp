# Class: cloudstack
#
# This class installs the base CloudStack components
#
# Parameters:
#
# Actions:
#   Manage sudoers entry for cloud user
#   Manage hosts file
#   Turn off selinux
#   Ensure wget installed
#
# Requires:
#
# Package[ 'sudo' ]
#
# Sample Usage:
# This class should not be included directly.  It is called from other modules.
#
class cloudstack (
  $csversion  = '4.2',
  $setup_repo = true,
) {

  # FIXME - Is this dangerous?  I don't know what it does...
  resources { 'host':
    name  => 'host',
    purge => true,
  }

  if $setup_repo == true and $::osfamily == 'RedHat' {
    yumrepo{ 'cloudstack':
      baseurl  => "http://cloudstack.apt-get.eu/rhel/${csversion}/",
      enabled  => '1',
      gpgcheck => '0',
      before   => Package['cloudstack-management']
    }
  }

  # FIXME - could this be a stanza in /etc/sudoers.d?  Depends on the OS.
  # Answer: make this more OS-sensitive.  Maybe use the sudo module?
  file_line { 'cs_sudo_rule':
    path => '/etc/sudoers',
    line => 'cloud ALL = NOPASSWD : ALL',
  }

  host { 'localhost':
    ensure       => present,
    ip           => '127.0.0.1',
    host_aliases => [ $::fqdn, 'localhost.localdomain', $::hostname ],
  }

  package { 'wget': ensure => present } # Not needed after 2.2.9, see bug 11258

  # Firewall rules

  firewall { '001 allow icmp':
    proto  => 'icmp',
    action => 'accept',
  }
  firewall { '002 allow all to lo interface':
    iniface => 'lo',
    action  => 'accept',
  }

  firewall { '003 allow ssh':
    dport => '22',
    proto => 'tcp',
  }
}
