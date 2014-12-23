#
## Class: cloudstack::mgmt
#
# This class builds the CloudStack management node
#
# Parameters:
#   $csversion (string): Set the version of Cloudstack to be used
#   $setup_repo (boolean): Do we want this module to setup the yum repo?
#   $mgmt_port (string): Default port for unauthenticated management
#   $localdb (boolean): Will the mysql database be located on this host?
#   $setup_ntp (boolean): Setup NTP on this host?  Just an include - you have to configure it
#     yourself.
#   $uses_xen (boolean): If we use Xen at all, set this so that we can download vhd_util.
#   $dbuser (string): Name of the Cloudstack database user
#   $dbpassword (string): Password for the Cloudstack db user
#   $dbhost (string): hostname of the remote database server.  Only used if $localdb is false.
#   $dbdeployasuser (string): Administrative user of the database.  You shouldn't need to change this.
#   $dbrootpw (string): Password for the administrative db user.
#
# FIXME:  Need to rewrite this when finished...
# Actions:
#   Install NTP, if desired
#   Install the cloudstack-management package
#   Download and install vhd_util if we’re using Xen ($uses_xen = true)
#   Install cloud database only if MySQL is installed and configured ($localdb = true)
#   Disable selinux
#   Run cloud-setup-databases
#   Run cloud-setup-management script
#   Add Tomcat symlinks
#   Open appropriate iptables ports
#
# FIXME:  Need to update...
# Requires:
#
# Package[ 'sudo' ]
# puppetlabs/ntp
# puppetlabs/mysql
#
# FIXME:  Need to update...
# Sample Usage:
#
class cloudstack::mgmt (
  $csversion      = '4.2',
  $setup_repo     = true,
  $mgmt_port      = '8096',
  $localdb        = true,
  $setup_ntp      = false,
  $uses_xen       = false,
  $dbuser         = 'cloud',
  $dbpassword     = 'cloud',
  $dbhost         = undef,
  $dbdeployasuser = 'root',
  $dbrootpw       = 'rootpw',
) inherits cloudstack::params {
  validate_string($csversion, '4.[2345]')
  validate_bool($setup_repo)
  validate_bool($localdb)
  validate_bool($setup_ntp)
  validate_bool($uses_xen)
  validate_string($dbuser)
  validate_string($dbpassword)
  validate_string($dbdeployasuser)

  #include cloudstack
  class { 'cloudstack':
    csversion  => $csversion,
    setup_repo => $setup_repo,
    before     => Package['cloudstack-management']
  }

  # We require NTP, somehow...
  if $setup_ntp == true {
    include ::ntp
  }

  # Fix for known bug in 4.3 release...
  if $::operatingsystem == 'Ubuntu' and $csversion == '4.3' {
    package { 'libmysql-java':
      ensure => installed,
      before => Package['cloudstack-management']
    }
  }

  package { 'cloudstack-management':
    ensure => latest,
    before => Anchor['anchor_swinstall_end']
  }

  # We may need vhd-util...
  if $uses_xen == true {
    $vhd_url  = 'http://download.cloud.com.s3.amazonaws.com/tools/vhd-util'
    $vhd_path = '/usr/share/cloudstack-common/scripts/vm/hypervisor/xenserver'
    $vhd_download_command = "/usr/bin/wget ${vhd_url} -O ${vhd_path}/vhd_util"

    exec { 'download_vhd_util':
      command => $vhd_download_command,
      creates => "${vhd_path}/vhd_util",
      require => Package['cloudstack-management'],
      before  => File['vhd_util']
    }
    file { 'vhd_util':
      ensure => present,
      path   => "${vhd_path}/vhd_util",
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      # FIXME:  Need to set SELinux permissions...
      before => Anchor['anchor_swinstall_end']
    }
  }

  # And now we come to the end of software installation.
  anchor { 'anchor_swinstall_end': }

  $remotedbhost = $localdb ? {
    true  => 'localhost',
    false => $dbhost
  }

  if $localdb == true {
    $override_options = {
      'mysqld' => {
        'innodb_rollback_on_timeout' => '1',
        'innodb_lock_wait_timeout'   => '500',
        'max_connections'            => '350'
      }
    }
    #include ::mysql::server
    class { '::mysql::server':
      root_password           => $dbrootpw,
      override_options        => $override_options,
      remove_default_accounts => true,
      service_enabled         => true,
      require                 => Anchor['anchor_swinstall_end'],
      before                  => Anchor['anchor_localdb']
    }
  }
  anchor { 'anchor_localdb':
    before => Anchor['anchor_selinux_begin']
  }

  # We need to disable Selinux...
  anchor { 'anchor_selinux_begin':
    before => Anchor['anchor_selinux_end']
  }
    
  # FIXME:  No need to replace the config file when disabling SELinux...
  file { '/etc/selinux/config':
    source  => 'puppet:///modules/cloudstack/config',
    require => Anchor['anchor_selinux_begin'],
    before  => Anchor['anchor_selinux_end']
  }
  exec { 'disable_selinux':
    command => '/usr/sbin/setenforce 0',
    onlyif  => '/usr/sbin/getenforce | grep Enforcing',
    require => Anchor['anchor_selinux_begin'],
    before  => Anchor['anchor_selinux_end']
  }
  anchor { 'anchor_selinux_end':
    require => Anchor['anchor_selinux_begin']
  }

  # Now we want to configure the database.  Start with an anchor...
  anchor { 'anchor_dbsetup_begin':
    require => Anchor['anchor_selinux_end'],
    before  => Anchor['anchor_dbsetup_end']
  }

  # FIXME:  Need to provide for the possibility of using the
  # "-e", "-m", "-k", and "-i" options.  And securing the database connection.
  $dbstring = inline_template( "<%= \"/usr/bin/cloudstack-setup-databases \" +
              \"${dbuser}:${dbpassword}@${dbhost} --deploy-as=${dbdeployasuser}:${dbrootpw}\" %>" )

  if $localdb == true {
    exec { 'cloudstack_setup_localdb':
      command => $dbstring,
      creates => '/var/lib/mysql/cloud',
      require => Anchor['anchor_dbsetup_begin'],
      before  => Anchor['anchor_dbsetup_end']
    }
  } else {
    exec { 'cloudstack_setup_remotedb':
      command => $dbstring,
      # FIXME:  How can we tell that the remote db is setup?  What needs to be in place?
      #unless '
      require => Anchor['anchor_dbsetup_begin'],
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



  ######################################################
  ############## tomcat section ########################
  ######################################################


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

  # Finally, we start cloudstack...

  service { 'cloudstack-management':
    ensure    => running,
    enable    => true,
    hasstatus => true,
    require   => Anchor['anchor_misc_end']
  }

# FIXME:  Deal with firewall ports
######################################################
############ firewall section ########################
######################################################


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
}
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
