#
# == Class: cloudstack::common
#
#   This class manages the CloudStack common elements that are needed
#   both on Management servers AND KVM hypervisors.
#
# == Parameters
#
#   $csversion (string): Set the version of Cloudstack to be used.
#
#   $setup_repo (boolean): Do we want this module to setup the yum repo?
#
# == Actions
#
#      Manage hosts file
#      Manage sudoers entry for cloud user
#      Disable SELinux/apparmor (unfortunately)
#      Configure some basic Firewall rules
#
# == Requires
#
# == Sample Usage
#
# == Notes
#
#   FIXME 1:  Need to cleanup the sudoers bit
#   FIXME 2:  SELinux disabling is a bit drastic.
#   FIXME 3:  Need more options for cloudstack-setup-databases
#   FIXME 4:  Hardcoded path alert - need to take into account
#     alternate locations for the sql db
#   FIXME 5:  Test that the remote db is detected.
#   FIXME 6:  We're currently forced into using cloudmonkey because we
#     need it to enable the unauthenticated API port for configuring
#     Cloudstack objects.  There's got to be a better way to do this.
#   FIXME:  This class could use a lot of cleanup love.
#
class cloudstack::common (
  $csversion  = $cloudstack::params::csversion,
  $setup_repo = $cloudstack::params::setup_repo,
) inherits cloudstack::params {

  if $setup_repo == true and $::osfamily == 'RedHat' {
    yumrepo{ 'cloudstack':
      ensure   => present,
      descr    => "Cloudstack ${csversion} repository",
      baseurl  => "http://cloudstack.apt-get.eu/rhel/${csversion}/",
      enabled  => '1',
      gpgcheck => '0',
    }
  }

  # Part 1 - Items for before the installation of cloudstack-management...

  #   Part 1.1 - Sudo configuration.
  #
  #   FIXME 1: Could this be a stanza in /etc/sudoers.d?  Depends on the OS.
  #     Answer: make this more OS-sensitive.  Maybe use the sudo module?

  file_line { 'cs_sudo_rule':
    path   => '/etc/sudoers',
    line   => 'cloud ALL = NOPASSWD : ALL',
    before => Package['cloudstack-management']
  }

  #   Part 1.2 - Fixup for /etc/hosts.
  #     Part 1.2.1 - Clear out entries from /etc/hosts...
  #       (this might be a little dangerous...)

  resources { 'host':
    name  => 'host',
    purge => true
  }

  #     Part 1.2.2 - Ensure the localhost entry.

  host { 'localhost':
    ensure       => present,
    ip           => '127.0.0.1',
    host_aliases => [ $::fqdn, 'localhost.localdomain', $::hostname ],
    before       => Package['cloudstack-management']
  }

  #   Part 1.3 - Disable SELinux.  I don't like doing this, but Cloudstack
  #     says to do it, so for now...
  #
  #   	FIXME 2:  No need to replace the config file when disabling SELinux...
  if $::osfamily == 'RedHat' {
    exec { 'disable_selinux':
      command => '/usr/sbin/setenforce permissive',
      onlyif  => '/usr/sbin/getenforce | grep Enforcing',
    } ->
    file { '/etc/selinux/config':
      source => 'puppet:///modules/cloudstack/config',
      before => Package['cloudstack-management']
    }
  } elsif $::operatingsystem == 'Ubuntu' {
    exec { 'disable_apparmor_1':
      command => 'ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmord.d/disable/',
      creates => '/etc/apparmord.d/usr.sbin.libvirtd',
      onlyif  => 'dpkg --list \'apparmor\''
    } ->
    exec { 'disable_apparmor_2':
      command => 'ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper /etc/apparmor.d/disable/',
      creates => '/etc/apparmord.d/usr.lib.libvirt.virt-aa-helper',
      onlyif  => 'dpkg --list \'apparmor\''
    } ->
    exec { 'disable_apparmor_3':
      command => [
        'apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd',
        'apparmor_parser -R /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper'
      ],
      onlyif  => 'dpkg --list \'apparmor\''
    }
  }

  # Note that this step is only here because of the order of the
  # installation instructions...
  #
  # (Also note that we cannot know if there will ever be a KVM zone,
  # and since the creation of zones is done via a "define",
  # and since we only want to do this once, everyone gets it...)
  file_line { 'cs_cloud_norequiretty':
    path => '/etc/sudoers',
    line => 'Defaults:cloud !requiretty',
  }

  # Firewall rules

  firewall { '001 INPUT allow icmp':
    chain  => 'INPUT',
    proto  => 'icmp',
    action => 'accept',
  }
  firewall { '002 INPUT allow all to lo interface':
    chain   => 'INPUT',
    iniface => 'lo',
    action  => 'accept',
  }
  firewall { '003 INPUT allow ssh':
    chain  => 'INPUT',
    dport  => '22',
    proto  => 'tcp',
    action => 'accept',
  }
}
