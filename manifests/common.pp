#
# == Class: cloudstack::common
#
#   This class manages the CloudStack common elements that are needed
#   both on CS Management servers and CS KVM hypervisors.
#
# == Parameters
#
#   $csversion (string): Set the version of Cloudstack to be used.
#
#   $setup_repo (boolean): Do we want this module to setup the yum repo?
#
#   $repo_override_url (string): Set an override URL for the cloudstack repo.
#     No variable interpolation is done with this string, so it's on you to
#     ensure that your repo and CS versions match up properly.
#
# == Actions
#
#      Define the yumrepo type for $::osfamily == 'RedHat'
#      Manage hosts file
#      Manage sudoers entries for Cloudstack
#      Disable SELinux/apparmor (unfortunately)
#      Configure some basic Firewall rules
#
# == Sample Usage
# 
#   Internal class.  Not intended to be called directly.
#
class cloudstack::common (
  $csversion         = $::cloudstack::params::csversion,
  $setup_repo        = $::cloudstack::params::setup_repo,
  $manage_firewall   = $::cloudstack::params::manage_firewall,
  $repo_override_url = 'UNSET'
) inherits cloudstack::params {

  # Variables

  $ospath = $::cloudstack::params::ospath

  $repo_url = $repo_override_url ? {
    'UNSET' => "http://cloudstack.apt-get.eu/rhel/${csversion}/",
    default => $repo_override_url
  }

  # Validations

  validate_string($csversion)
  validate_bool($setup_repo)
  validate_string($repo_url)

  # Resources

  #resources { 'host':
  #  name  => 'host',
  #  purge => true
  #}

  if $setup_repo and $::osfamily == 'RedHat' {
    yumrepo { 'cloudstack':
      name     => 'cloudstack',
      #ensure   => present,  # Doesn't work in 3.2.3, so disabling...
      descr    => "Cloudstack ${csversion} repository",
      baseurl  => $repo_url,
      enabled  => '1',
      gpgcheck => '0'
    }
  }

  host { 'localhost':
    ensure       => present,
    ip           => '127.0.0.1',
    host_aliases => [ $::fqdn, 'localhost.localdomain', $::hostname ]
  }

  package { [ 'wget', 'curl', 'xgrep' ]: ensure => installed }

  file { '/etc/sudoers.d/cloudstack':
    ensure   => present,
    mode     => '0440',
    owner    => 'root',
    group    => 'root',
    seluser  => 'system_u',
    selrole  => 'object_r',
    seltype  => 'etc_t',
    selrange => 's0',
    content  => 'cloud ALL=(ALL) NOPASSWD : ALL'
  }

  file_line { 'cs_cloud_norequiretty':
    #
    # Since we cannot know if there will ever be a KVM zone,
    # and since the creation of zones is done via a "define",
    # and since we only want to do this once, everyone gets this...
    #
    path => '/etc/sudoers',
    line => 'Defaults:cloud !requiretty'
  }

  if $::osfamily == 'RedHat' {
    exec { 'disable_selinux':
      command => 'setenforce permissive',
      onlyif  => 'getenforce | grep Enforcing',
      path    => $ospath
    }
    file_line { 'disable_selinux_config':
      path  => '/etc/selinux/config',
      line  => 'SELINUX=permissive',
      match => '^SELINUX='
    }
  } elsif $::operatingsystem == 'Ubuntu' {
    exec { 'disable_aa_libvirtd_link':
      command => 'ln -s /etc/apparmor.d/usr.sbin.libvirtd /etc/apparmord.d/disable/',
      creates => '/etc/apparmord.d/usr.sbin.libvirtd',
      onlyif  => 'dpkg --list \'apparmor\'',
      path    => $ospath
    }
    exec { 'disable_aa_libvirtd_cmd':
      command => 'apparmor_parser -R /etc/apparmor.d/usr.sbin.libvirtd',
      onlyif  => 'dpkg --list \'apparmor\'',
      path    => $ospath
    }
    exec { 'disable_aa_helper_link':
      command => 'ln -s /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper /etc/apparmor.d/disable/',
      creates => '/etc/apparmord.d/usr.lib.libvirt.virt-aa-helper',
      onlyif  => 'dpkg --list \'apparmor\'',
      path    => $ospath
    }
    exec { 'disable_aa_helper_cmd':
      command => 'apparmor_parser -R /etc/apparmor.d/usr.lib.libvirt.virt-aa-helper',
      onlyif  => 'dpkg --list \'apparmor\'',
      path    => $ospath
    }
  }

  if $manage_firewall {
    firewall { '001 INPUT allow icmp':
      chain  => 'INPUT',
      proto  => 'icmp',
      action => 'accept'
    }
    firewall { '002 INPUT allow all to lo interface':
      chain   => 'INPUT',
      iniface => 'lo',
      action  => 'accept'
    }
    firewall { '003 INPUT allow ssh':
      chain  => 'INPUT',
      dport  => '22',
      proto  => 'tcp',
      action => 'accept'
    }
  }

  anchor { 'cs_common_complete': }

  # Dependencies

  Host['localhost']                      -> Anchor['cs_common_complete']
  File['/etc/sudoers.d/cloudstack']      -> Anchor['cs_common_complete']
  File_line['cs_cloud_norequiretty']     -> Anchor['cs_common_complete']
  Package['wget']                        -> Anchor['cs_common_complete']
  Package['curl']                        -> Anchor['cs_common_complete']

  if $::osfamily == 'RedHat' {
      Exec['disable_selinux'] -> Anchor['cs_common_complete']
      File_line['disable_selinux_config'] -> Anchor['cs_common_complete']
  } elsif $::operatingsystem == 'Ubuntu' {
      Exec['disable_aa_libvirt_link'] ->
        Exec['disable_aa_helper_link'] ->
        Exec['disable_aa_libvirt_cmd'] ->
        Exec['disable_aa_helper_cmd'] ->
        Anchor['cs_common_complete']
  }
}
