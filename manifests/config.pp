#
# == Class: cloudstack::config
#
#   This class manages the CloudStack configuration elements.
#
# == Actions
#
#      Configure the database for CS usage 
#      Configure Tomcat
#      Configure some basic Firewall rules
#
# == Sample Usage
#
#   This class isn't intended to be called directly.
#
class cloudstack::config inherits cloudstack::params {

  # Variables

  $mgmt_port                 = $::cloudstack::mgmt_port
  $localdb                   = $::cloudstack::localdb
  $dbuser                    = $::cloudstack::dbuser
  $dbpassword                = $::cloudstack::dbpassword
  $dbhost                    = $::cloudstack::dbhost
  $dbdeployasuser            = $::cloudstack::dbdeployasuser
  $dbrootpw                  = $::cloudstack::dbrootpw
  $force_dbsetup             = $::cloudstack::force_dbsetup
  $manage_firewall           = $::cloudstack::manage_firewall
  $enable_remote_unauth_port = $::cloudstack::enable_remote_unauth_port
  $enable_aws_api            = $::cloudstack::enable_aws_api
  $cs_needed_ports           = $::cloudstack::params::cs_needed_ports
  $ospath                    = $::cloudstack::params::ospath

  $setport = "update configuration name=integration.api.port value=${mgmt_port}"

  #   FIXME:  We should check if $dbpassword is set to the same as default and
  #     offer the ability to generate a random one instead.
  #   FIXME:  Need to provide for the possibility of using the
  #     "-e", "-m", "-k", and "-i" options.  And securing the database
  #     connection with SSL.  This may force the inline template below
  #    into a full-blown template for parsing the configuration options.
  #   FIXME:  Yes, we leak the db password out into the logs.  Not good.
  #
  $dbstring = inline_template("<%= \"cloudstack-setup-databases \" +
    \"${dbuser}:${dbpassword}@${dbhost} --deploy-as=${dbdeployasuser}:${dbrootpw}\" %>" )

  $cycle_cs_mgmt1 = "sleep 20 ; cloudmonkey ${setport} ; service cloudstack-management restart"
  $cycle_cs_mgmt2 = "until nc -w 1 localhost ${mgmt_port} ; do sleep 2 ; done"
  $cycle_cs_mgmt = "${cycle_cs_mgmt1} ; ${cycle_cs_mgmt2}"

  if $localdb {
    # FIXME: Hardcoded path alert!
    $dbunless = 'test -d /var/lib/mysql/cloud'
  } else {
    # FIXME:  We're leaking the db password into the logs.  Not good.
    $dbunless = "mysql -u${dbuser} -p${dbpassword} -h ${dbhost} cloud"
  }
  # Resources

  include ::cloudstack::cloudmonkey

  package { 'nc': ensure => installed }

  exec { 'cloudstack_setup_db':
    command => $dbstring,
    unless  => "${dbunless} || ${force_dbsetup}",
    path    => $ospath
  }

  exec { 'cs_setup_mgmt':
    command => 'cloudstack-setup-management',
    unless  => 'test -e /etc/sysconfig/cloudstack-management',
    path    => $ospath
  }

  #
  #  Possibly unneeded for RHEL/CentOS.  Need to check on Ubuntu...
  #
  file { '/etc/cloudstack/management/tomcat6.conf':
    ensure => 'link',
    group  => '0',
    owner  => '0',
    mode   => '0777',
    target => 'tomcat6-nonssl.conf'
  }

  file { '/usr/share/cloudstack-management/conf/server.xml':
    ensure => 'link',
    group  => '0',
    owner  => '0',
    mode   => '0777',
    target => 'server-nonssl.xml'
  }

  service { 'cloudstack-management':
    ensure    => running,
    enable    => true,
    hasstatus => true
  }

  # Configure the unauthenticated management port.  Only local for now...
  #

  # FIXME:  We're forcing the use of Cloudmonkey here.  It's not desirable,
  #   but I can't very well use the REST API (default 8096/tcp) to enable the
  #   REST API port, can I?  Chicken, meet egg.  To boot, I can't use 8080/tcp
  #   as I'd need to go through the "setup an authenticated, signed connection
  #   with special parameters" dance.  Ugh.  So Cloudmonkey it is.  This means
  #   that for now, ${::cloudstack::install_cloudmonkey} is meaningless...
  #   Note that this resource may break the cloudstack-management service,
  #   since it's going to try to restart it right after it comes up the
  #   first time...  This may be in place until the zone/cluster/pod resources
  #   are able to use the REST API with signed requests and a changed password.

  exec { 'enable_mgmt_port':
    command => $cycle_cs_mgmt,
    unless  => "lsof -i :${mgmt_port}",
    path    => $ospath
  }

  # Firewall rules

  if $manage_firewall {
    #
    # Remote database?  No problem.  But if you're doing egress firewalling,
    # you'd better also capture NFS, DNS, and iSCSI.
    #
    #if $localdb == false {
    #  firewall { '100 OUTPUT allow port 3306 out':
    #    chain  => 'OUTPUT',
    #    dport  => '3306',  # FIXME: Hardcoded port alert
    #    proto  => 'tcp',
    #    action => 'accept'
    #  }
    #}
    #
    # FIXME:  What if we want the AWS API server?  We'll need code for that
    # and a firewall rule.  Here's one (incomplete implementation in this module overall)...
    # 
    # if $enable_aws_api {
    #   firewall { '100 INPUT allow 7080 for AWS API':
    #     chain  => 'INPUT',
    #     dport  => '7080',  # FIXME: Hardcoded port alert
    #     proto  => 'tcp',
    #     action => 'accept'
    #   }
    #

    #   Unauthenticated API interface.  We don't want to open this by default.
    if $enable_remote_unauth_port {
      notify { 'remote_unauth_notify':
        message => 'ALERT: Remote unauthed port is OPEN!  Please be certain.'
      }
      firewall { '130 INPUT cs-mgmt permit unauthenticated API':
        chain  => 'INPUT',
        dport  => $mgmt_port,
        proto  => 'tcp',
        action => 'accept'
      }
    }

    firewall { '130 Cloudstack management ports':
      chain  => 'INPUT',
      dport  => $cs_needed_ports,
      proto  => 'tcp',
      action => 'accept'
    }
  }

  anchor { 'end_of_db': }
  anchor { 'service_hook': }

  # Dependencies

  #   If we're using a local db...
  if $localdb {
    Class['::mysql::server'] -> Exec['cloudstack_setup_db']
  }
  Anchor['cs_swinstall_end'] ->
    Exec['cloudstack_setup_db'] ->
    Anchor['end_of_db']

  #   Setup mgmt + config files
  Anchor['end_of_db'] ->
    Exec['cs_setup_mgmt'] ->
    #File['/etc/cloudstack/management/tomcat6.conf'] ->
    #File['/usr/share/cloudstack-management/conf/server.xml'] ->
    Service['cloudstack-management'] ->
    Anchor['service_hook'] ->
    Exec['enable_mgmt_port']

  Class['::cloudstack::cloudmonkey'] -> Exec['enable_mgmt_port']
  Package['lsof'] -> Exec['enable_mgmt_port']

  if $manage_firewall and $enable_remote_unauth_port {
    Notify['remote_unauth_notify'] ->
      Firewall['130 INPUT cs-mgmt permit unauthenticated API']
  }
}
