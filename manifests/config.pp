# == Class: cloudstack::config
#
# This class manages all of the CloudStack installation configuration elements.
#
# == Parameters
#
# == Actions
#
#      Manage hosts file
#      Manage sudoers entry or cloud user
#      Disable SELinux (unfortunately)
#      Configure the database for CS usage 
#      Configure Tomcat
#      Configure some basic Firewall rules
#
# == Requires
#
# Sample Usage:
#
# TODO:
#   Need to open up the unauthenticated API port JUST for localhost and
#     firewall it from everything else.  But we need it to setup cs objects.
#   This class could use a lot of cleanup love.  FIXME.
#
class cloudstack::config {

  # Fixup for /etc/hosts.  2 parts.
  # Part 1 - Clear out entries from /etc/hosts... this might be a little dangerous...
  resources { 'host':
    name  => 'host',
    purge => true,
  }

  # Part 2 - Ensure the localhost entry.
  host { 'localhost':
    ensure       => present,
    ip           => '127.0.0.1',
    host_aliases => [ $::fqdn, 'localhost.localdomain', $::hostname ],
  }

  # Sudo configuration.
  # FIXME - could this be a stanza in /etc/sudoers.d?  Depends on the OS.
  # Answer: make this more OS-sensitive.  Maybe use the sudo module?
  file_line { 'cs_sudo_rule':
    path => '/etc/sudoers',
    line => 'cloud ALL = NOPASSWD : ALL',
  }

  # FIXME:  No need to replace the config file when disabling SELinux...
  exec { 'disable_selinux':
    command => '/usr/sbin/setenforce 0',
    onlyif  => '/usr/sbin/getenforce | grep Enforcing',
  } ->
  file { '/etc/selinux/config':
    source  => 'puppet:///modules/cloudstack/config',
  }

  # Now we want to configure the database.  Start with an anchor...
  anchor { 'anchor_dbsetup_begin':
    before  => Anchor['anchor_dbsetup_end']
  }

  # FIXME:  Need to provide for the possibility of using the
  # "-e", "-m", "-k", and "-i" options.  And securing the database connection
  # with SSL.
  $dbstring = inline_template( "<%= \"/usr/bin/cloudstack-setup-databases \" +
              \"${::cloudstack::dbuser}:${::cloudstack::dbpassword}@${::cloudstack::dbhost} --deploy-as=${::cloudstack::dbdeployasuser}:${::cloudstack::dbrootpw}\" %>" )

  if $::cloudstack::localdb == true {
    exec { 'cloudstack_setup_localdb':
      command => $dbstring,
      creates => '/var/lib/mysql/cloud',
      require => Class['::mysql::server'],
      before  => Anchor['anchor_dbsetup_end']
    }
  } else {
    exec { 'cloudstack_setup_remotedb':
      command => $dbstring,
      # FIXME:  How can we tell that the remote db is setup?  What needs to be in place?
      # Answer:  A database query.  Check if the db exists...
      #   Need to verify that this works.
      unless  => "/usr/bin/mysql -u${::cloudstack::dbuser} -p${::cloudstack::dbpassword} -h ${::cloudstack::dbhost} cloud",
      require => Anchor['::cloudstack::install::anchor_swinstall_end'],
      before  => Anchor['anchor_dbsetup_end']
    }
  }
  anchor { 'anchor_dbsetup_end':
    require => Anchor['anchor_dbsetup_begin'],
    before  => Anchor['anchor_misc_begin']
  }

  # Misc. stuff...
  anchor { 'anchor_misc_begin':
    require => Anchor['anchor_dbsetup_begin'],
    before  => Anchor['anchor_misc_end']
  }

  # Note that this step is only here because of the order of the
  # installation instructions...
  # FIXME:  Only if using KVM...
  file_line { 'cs_cloud_norequiretty':
    path   => '/etc/sudoers',
    line   => 'Defaults:cloud !requiretty',
    before => Exec['cs_setup_mgmt']
  }
    
  exec { 'cs_setup_mgmt':
    command => '/usr/bin/cloudstack-setup-management',
    unless  => '/usr/bin/test -e /etc/sysconfig/cloudstack-management',
    require => Anchor['anchor_misc_begin'],
    before  => Anchor['anchor_misc_end']
  }

  # Tomcat config files

  file { '/etc/cloudstack/management/tomcat6.conf':
    ensure  => 'link',
    group   => '0',
    mode    => '0777',
    owner   => '0',
    target  => 'tomcat6-nonssl.conf',
    require => Exec['cs_setup_mgmt'],
    before  => Anchor['anchor_misc_end']
  }

  file { '/usr/share/cloudstack-management/conf/server.xml':
    ensure  => 'link',
    group   => '0',
    mode    => '0777',
    owner   => '0',
    target  => 'server-nonssl.xml',
    require => Exec['cs_setup_mgmt'],
    before  => Anchor['anchor_misc_end']
  }

  anchor { 'anchor_misc_end':
    require => Anchor['anchor_misc_begin']
  }


  # FIXME:  Deal with firewall ports
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
  firewall { '003 allow port 80 in':
    proto  => 'tcp',
    dport  => '80',
    action => 'accept',
  }
  firewall { '120 permit 8080 - web interface':
    proto  => 'tcp',
    dport  => '8080',
    action => 'accept',
  }

  # FIXME:  Deal with this somehow...
  ###### this is the unauthed API interface - should be locked down by default.
  # firewall { '130 permit unauthed API':
  #   proto => 'tcp',
  #   dport => '8096',
  #   jump  => 'accept',
  # }
  #

  firewall { '8250 CPVM':    #### Think this is for cpvm, but check for certain.
    proto  => 'tcp',
    dport  => '8250',
    action => 'accept',
  }

  firewall { '9090 unk port':    ######## find out what this does in cloudstack
    proto  => 'tcp',
    dport  => '9090',
    action => 'accept',
  }

  # FIXME:  Need to deal with this stuff...  Potentially move it to zone creation....
########## SecStorage ############
## NOTE: This will take a LONG time to run. Go get a cup of coffee
# exec { 'mount ${cloudstack::cs_sec_storage_nfs_server}:${cloudstack::cs_sec_storage_mnt_point}  /mnt ;
#   ${cloudstack::system_tmplt_dl_cmd} -m /mnt -u ${cloudstack::sysvm_url_kvm} -h kvm -F ;
#   curl 'http://localhost:8096/?command=addSecondaryStorage&url=nfs://${cloudstack::cs_sec_storage_nfs_server}${cloudstack::cs_sec_storage_mnt_point}&zoneid=1' ;
#   touch /var/lib/cloud/ssvm':
#   onlyif => [ 'test ! -e /var/lib/cloud/ssvm', 'curl 'http://localhost:8096/?command=listZones&available=true' | grep Zone1',]
# }

########## Primary Storage ########
### THis needs to add a check for a host to have been added
# exec { 'curl 'http://localhost:8096/?command=createStoragePool&name=PStorage&url=nfs://${cloudstack::pri_storage_nfs_server}${cloudstack::pri_storage_mnt_point}&zoneid=4&podid=1'':
#   onlyif => ['curl 'http://localhost:8096/?command=listPods' | grep Pod1',
#     'curl 'http://localhost:8096/?command=listStoragePools' | grep -v PStorage',
#   ]
# }

}
