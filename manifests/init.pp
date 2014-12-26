# == Class: cloudstack
#
# This class installs the base CloudStack components for a management
# server.
#
# == Parameters
#
#   $csversion (string): Set the version of Cloudstack to be used
#   $setup_repo (boolean): Do we want this module to setup the yum repo?
#   $mgmt_port (string): Default port for unauthenticated management.  FIXME - We need to use this to configure the service.
#   $localdb (boolean): Will the mysql database be located on this host?
#   $uses_xen (boolean): If we use Xen at all, set this so that we can download vhd_util.
#   $dbuser (string): Name of the Cloudstack database user
#   $dbpassword (string): Password for the Cloudstack db user
#   $dbhost (string): hostname of the remote database server.  Only used if $localdb is false.
#   $dbdeployasuser (string): Administrative user of the database.  You shouldn't need to change this.
#   $dbrootpw (string): Password for the administrative db user.
#   $install_cloudmonkey (boolean): If true, install Cloudmonkey.
#
# Requires:
#
# Package[ 'sudo' ]
# (optional) puppetlabs/mysql
#
# Sample Usage:
#
#   class { 'cloudstack':
#     csverssion          => '4.4',
#     uses_xen            => true,
#     install_cloudmonkey => true
#   }
#
#   == OR ==
#
#   Configure it via Hiera:
#   (yaml example):
#   cloudstack::csversion: '4.4'
#   cloudstack::setup_repo: true
#   cloudstack::install_cloudmonkey: true
#
#
class cloudstack (
  $csversion           = '4.2',
  $setup_repo          = true,
  $mgmt_port           = '8096',
  $localdb             = true,
  $uses_xen            = false,
  $dbuser              = 'cloud',
  $dbpassword          = 'cloud',
  $dbhost              = undef,
  $dbdeployasuser      = 'root',
  $dbrootpw            = 'rootpw',
  $install_cloudmonkey = false
) {
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

  anchor { '::cloudstack::begin': } ->
  class { '::cloudstack::install': } ->
  class { '::cloudstack::config': } ->
  anchor { '::cloudstack::end': }

}
