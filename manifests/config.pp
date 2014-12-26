#
# == Class: cloudstack::config
#
#   This class manages the CloudStack configuration elements.
#
# == Parameters
#
# == Actions
#
#      Configure the database for CS usage 
#      Configure Tomcat
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
class cloudstack::config {

  # Things we need from the outside...
  $dbuser                    = $::cloudstack::dbuser
  $dbpassword                = $::cloudstack::dbpassword
  $dbhost                    = $::cloudstack::dbhost
  $dbdeployasuser            = $::cloudstack::dbdeployasuser
  $dbrootpw                  = $::cloudstack::dbrootpw
  $mgmt_port                 = $::cloudstack::mgmt_port
  $enable_aws_api            = $::cloudstack::enable_aws_api
  $localdb                   = $::cloudstack::localdb
  $enable_remote_unauth_port = $::cloudstack::enable_remote_unauth_port

  # Part 1 - Items for before the installation of cloudstack-management...

  # Part 2 - Cloudstack is installed.  Now what?
  #

  # FIXME 3:  Need to provide for the possibility of using the
  # "-e", "-m", "-k", and "-i" options.  And securing the database connection
  # with SSL.  This may force the inline template below into a full-blown template for
  # parsing the configuration options.
  #
  $dbstring = inline_template( "<%= \"/usr/bin/cloudstack-setup-databases \" +
              \"${dbuser}:${dbpassword}@${dbhost} --deploy-as=${dbdeployasuser}:${dbrootpw}\" %>" )

  #      Continue on by initializing the database.
  if $localdb == true {
    exec { 'cloudstack_setup_localdb':
      command => $dbstring,
      creates => '/var/lib/mysql/cloud',  # FIXME 4: Hardcoded path alert!
      require => [ Anchor['anchor_swinstall_end'], Class['::mysql::server'], ],
      before  => Anchor['end_of_db']
    }
  } else {
    exec { 'cloudstack_setup_remotedb':
      command => $dbstring,
      # FIXME 5:  How can we tell that the remote db is setup?
      #   What needs to be in place?
      # Answer:  A database query.  Check if the db exists...
      #   Need to verify that this works.
      unless  => "/usr/bin/mysql -u${dbuser} -p${dbpassword} -h ${dbhost} cloud",
      require => Anchor['anchor_swinstall_end'],
      before  => Anchor['end_of_db']
    }
  }

  # Part 3 - Misc bits.
  anchor { 'end_of_db':
    before  => Anchor['end_of_misc']
  }

  exec { 'cs_setup_mgmt':
    command => '/usr/bin/cloudstack-setup-management',
    unless  => '/usr/bin/test -e /etc/sysconfig/cloudstack-management',
    require => Anchor['end_of_db'],
    before  => Anchor['end_of_misc']
  }

  # Tomcat config files

  file { '/etc/cloudstack/management/tomcat6.conf':
    ensure  => 'link',
    group   => '0',
    mode    => '0777',
    owner   => '0',
    target  => 'tomcat6-nonssl.conf',
    require => Exec['cs_setup_mgmt'],
    before  => Anchor['end_of_misc']
  }

  file { '/usr/share/cloudstack-management/conf/server.xml':
    ensure  => 'link',
    group   => '0',
    mode    => '0777',
    owner   => '0',
    target  => 'server-nonssl.xml',
    require => Exec['cs_setup_mgmt'],
    before  => Anchor['end_of_misc']
  }

  anchor { 'end_of_misc':
    require => Anchor['end_of_db']
  }

  # Configure the unauthenticated management port.  Only local for now...
  # FIXME:  Note that this resource may break the server, since it's going to try to restart it right after it comes up the first time...

    # FIXME 6:  Cloudmonkey method - forces use of cloudmonkey.  Not good, but I can't use the REST API (8096) as it's a chicken/egg situation.
    #   Can't use 8080 either as I'd need to go through the "setup an authenticated, signed connection with special parameters" dance.  Ugh.
    #   Cloudmonkey it is.  This means that ${::cloudstack::install_cloudmonkey} is meaningless...
    #
  include ::cloudstack::cloudmonkey
  $setport = "update configuration name=integration.api.port value=${mgmt_port}"
  exec { 'enable_mgmt_port':
    command => "/usr/bin/cloudmonkey ${setport}",

    # Not sure if this is a good idea, so disabling it for now...
    #unless  => "/usr/bin/test `TERM=vt100 /usr/bin/cloudmonkey list configurations name=integration.api.port filter=value display=default` -eq \'${mgmt_port}\'"
    unless  => "/usr/sbin/lsof -i :${mgmt_port}",

    notify  => Service['cloudstack-management'],
    require => [ Class['::cloudstack::cloudmonkey'], Package['lsof'] ]
  }

  # Firewall rules

  firewall { '003 INPUT allow port 80':
    chain  => 'INPUT',
    dport  => '80',
    proto  => 'tcp',
    action => 'accept',
  }

  #
  # Remote database?  No problem.  But if you're doing egress firewalling,
  # you'd better also capture NFS, DNS, and iSCSI.
  #
  #if $localdb == false {
  #  firewall { '100 OUTPUT allow port 3306 out':
  #    chain  => 'OUTPUT',
  #    dport  => '3306',  # FIXME: Hardcoded port alert
  #    proto  => 'tcp',
  #    action => 'accept',
  #  }
  #}
  #
  # FIXME:  What if we want the AWS API server?  We'll need code for that
  # and a firewall rule.  Here's one..
  # 
  # if $enable_aws_api {
  #   firewall { '100 INPUT allow 7080 for AWS API':
  #     chain  => 'INPUT',
  #     dport  => '7080',  # FIXME: Hardcoded port alert
  #     proto  => 'tcp',
  #     action => 'accept',
  #   }
  #

  # Cloudstack-specific ports.  See
  #   https://cwiki.apache.org/confluence/display/CLOUDSTACK/Ports+used+by+CloudStack

  firewall { '120 permit 8080 - web interface':
    chain  => 'INPUT',
    dport  => '8080',  # FIXME: Hardcoded port alert
    proto  => 'tcp',
    action => 'accept',
  }

  #   Unauthenticated API interface.  We don't want to open this by default.
  if $enable_remote_unauth_port {
    notify { 'ALERT:  Opening the unauthenticated port is DANGEROUS!  Please be certain.': } ->
    firewall { '130 permit unauthenticated API':
      chain  => 'INPUT',
      dport  => $mgmt_port,
      proto  => 'tcp',
      action => 'accept',
    }
  }
  
  #   I did not come up with this name.  I swear.  Go look at the web page.
  firewall { '130 permit 3922 Secure System secure communication port':
    chain  => 'INPUT',
    dport  => '3922',
    proto  => 'tcp',
    action => 'accept',
  }

  #   System VM to management unsecured communication port (
  firewall { '8250 CPVM':
    chain  => 'INPUT',
    dport  => '8250',
    proto  => 'tcp',
    action => 'accept',
  }

  # Cloudstack management cluster port
  firewall { '120 permit 9090 cloudstack cluster management port':
    chain  => 'INPUT',
    dport  => '9090',
    proto  => 'tcp',
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
