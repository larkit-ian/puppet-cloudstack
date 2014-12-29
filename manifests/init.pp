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
#   $mgmt_port (string): Default port for unauthenticated management.
#
#   $localdb (boolean): Will the mysql database be located on this host?
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
#   $install_cloudmonkey (boolean): If true, install Cloudmonkey.
#
#   $enable_remote_unauth_port (boolean): If true, allows remote connections to
#     the unauthenticated API port ($mgmt_port).
#     DO NOT ENABLE UNLESS YOU ARE ABSOLUTELY SURE ABOUT THIS!
#
# == Requires
#
#   Package[ 'sudo' ]
#   (optional) puppetlabs/mysql
#
# == Sample Usage
#
#  $dbpassword = 'Password of eight Random Words and Characters!'
#  $dbrootpw = 'A Different Password Random with ten Words and Characters!'
#
#   class { 'cloudstack':
#     csversion           => '4.4',
#     uses_xen            => true,
#     install_cloudmonkey => true,
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
#   FIXME:  I need a "manage_firewall" parameter so I can turn it off...
#
class cloudstack (
  $csversion                 = $::cloudstack::params::csversion,
  $setup_repo                = $::cloudstack::params::setup_repo,
  $mgmt_port                 = $::cloudstack::params::mgmt_port,
  $localdb                   = $::cloudstack::params::localdb,
  $uses_xen                  = $::cloudstack::params::uses_xen,
  $dbuser                    = $::cloudstack::params::dbuser,
  $dbpassword                = $::cloudstack::params::dbpassword,
  $dbhost                    = $::cloudstack::params::dbhost,
  $dbdeployasuser            = $::cloudstack::params::dbdeployasuser,
  $dbrootpw                  = $::cloudstack::params::dbrootpw,
  $install_cloudmonkey       = $::cloudstack::params::install_cloudmonkey,
  $enable_remote_unauth_port = $::cloudstack::params::enable_remote_unauth_port,
  $enable_aws_api            = $::cloudstack::params::enable_aws_api
) inherits cloudstack::params {

  # Validations
  validate_string($csversion, '4.[2345]')
  validate_bool($setup_repo)
  validate_string($mgmt_port)
  validate_bool($localdb)
  validate_bool($uses_xen)
  validate_string($dbuser)
  validate_string($dbpassword)
  validate_string($dbhost)
  validate_string($dbdeployasuser)
  validate_string($dbrootpw)
  validate_bool($install_cloudmonkey)
  validate_bool($enable_remote_unauth_port)
  validate_bool($enable_aws_api)

  # Resources

  anchor { [ '::cloudstack::begin', '::cloudstack::end' ]: }
  class { [ '::cloudstack::install', '::cloudstack::config']: }

  # Dependencies

  Anchor['::cloudstack::begin'] ->
    Class['::cloudstack::install'] ->
    Class['::cloudstack::config'] ->
    Anchor['::cloudstack::end']
}
