#
# == Class: cloudstack
#
#   This class installs the base CloudStack components for a management
#   server.
#
# == Parameters
#
#   $csversion (string): Set the version of Cloudstack to be used.
#
#   $setup_repo (boolean): Do we want to setup the yum repo?
#
#   $repo_override_url (string):  Override URL for the cloudstack repo.
#
#   $mgmt_port (string): Default port for unauthenticated management.
#
#   $localdb (boolean): If we want this module to install mysql locally
#     using the puppetlabs/mysql module.  If you want a localdb, but
#     prefer to use your own module to install a database, you can
#     set this to false and set $dbhost to 'localhost'.
#
#   $uses_xen (boolean): If we use Xen at all, set this so that we can
#     download vhd_util.
#
#   $dbuser (string): Name of the Cloudstack database user.
#
#   $dbpassword (string): Password for the Cloudstack db user.
#
#   $dbhost (string): hostname of the remote database server.
#     Only used if $localdb is false.
#
#   $dbdeployasuser (string): Administrative user of the database.
#
#   $dbrootpw (string): Password for the administrative db user.
#
#   $force_dbsetup (boolean): Force the run of cloudstack-setup-databases.
#     Normally, this is false, and we assume that any setup where there's
#     an already-existing database means that we're adding an additional
#     manager node.  But if we actually want to redo the db setup, we
#     can force it with this parameter.
#
#   $install_cloudmonkey (boolean): If true, install Cloudmonkey.
#
#   $enable_remote_unauth_port (boolean): If true, allows remote connections to
#     the unauthenticated API port ($mgmt_port).
#     DO NOT ENABLE UNLESS YOU ARE ABSOLUTELY SURE ABOUT THIS!
#
#   $manage_firewall (boolean): If true, add firewall rules.
#
#   $fix_db_bug_43 (boolean): Workaround for CLOUDSTACK-8157 for CS 4.3 users.
#
# == Requires
#
#   Package[ 'sudo' ]
#   (optional) puppetlabs/mysql or whatever other mysql install you desire.
#     Beware of CLOUDSTACK-8157 if using CS 4.3 and either MySQL > 5.6 or
#     Percona.
#
# == Sample Usage
#
#  $dbpassword = 'Password of eight Random Words and Characters!'
#  $dbrootpw = 'A Different Password Random with ten Words and Characters!'
#
#   class { 'cloudstack':
#     csversion           => '4.4',
#     uses_xen            => true,
#     localdb             => false,
#     dbuser              => 'csuser',
#     dbpassword          => $dbpassword,
#     dbhost              => 'dbhost.example.com',
#     dbdeployasuser      => 'sqlroot',
#     dbrootpw            => $dbrootpw,
#     install_cloudmonkey => true,
#   }
#
# == Notes
#
#   FIXME:  Need support overall for the ability to configure other CS
#     parameters from the start, such as LDAP support, and other
#     config settings that require a service restart.restart
#
class cloudstack (
  $csversion                 = $::cloudstack::params::csversion,
  $setup_repo                = $::cloudstack::params::setup_repo,
  $repo_override_url         = 'UNSET',
  $mgmt_port                 = $::cloudstack::params::mgmt_port,
  $localdb                   = $::cloudstack::params::localdb,
  $uses_xen                  = $::cloudstack::params::uses_xen,
  $dbuser                    = $::cloudstack::params::dbuser,
  $dbpassword                = $::cloudstack::params::dbpassword,
  $dbhost                    = $::cloudstack::params::dbhost,
  $dbdeployasuser            = $::cloudstack::params::dbdeployasuser,
  $dbrootpw                  = $::cloudstack::params::dbrootpw,
  $force_dbsetup             = false,
  $install_cloudmonkey       = $::cloudstack::params::install_cloudmonkey,
  $enable_remote_unauth_port = $::cloudstack::params::enable_remote_unauth_port,
  $enable_aws_api            = $::cloudstack::params::enable_aws_api,
  $manage_firewall           = $::cloudstack::params::manage_firewall,
  $fix_db_bug_43             = false
) inherits cloudstack::params {

  # Validations

  validate_string($csversion, '4.[2345]')
  validate_string($mgmt_port)
  validate_string($dbuser)
  validate_string($dbpassword)
  validate_string($dbhost)
  validate_string($dbdeployasuser)
  validate_string($dbrootpw)

  validate_bool($setup_repo,$localdb,$uses_xen,$install_cloudmonkey)
  validate_bool($force_dbsetup,$enable_remote_unauth_port,$enable_aws_api)
  validate_bool($fix_db_bug_43)

  # Resources

  anchor { [ '::cloudstack::begin', '::cloudstack::end' ]: }
  class { [ '::cloudstack::install', '::cloudstack::config']: }

  # Dependencies

  Anchor['::cloudstack::begin'] ->
    Class['::cloudstack::install'] ->
    Class['::cloudstack::config'] ->
    Anchor['::cloudstack::end']
}
