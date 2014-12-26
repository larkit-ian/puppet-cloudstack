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
#   $setup_repo (boolean): Do we want this module to setup the yum repo?
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
#     Defaults to 'root'.
#
#   $dbrootpw (string): Password for the administrative db user.
#
#   $install_cloudmonkey (boolean): If true, install Cloudmonkey.
#
#   $enable_remote_unauth_port (boolean): If true, allows remote connections to
#     the unauthenticated API port ($mgmt_port).  Defaults to false.
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
#
class cloudstack (
  $csversion                 = '4.2',
  $setup_repo                = true,
  $mgmt_port                 = '8096',
  $localdb                   = true,
  $uses_xen                  = false,
  $dbuser                    = 'cloud',
  $dbpassword                = 'cloud',  # FIXME - this should be either mandatory or generated later.
  $dbhost                    = undef,
  $dbdeployasuser            = 'root',
  $dbrootpw                  = 'rootpw',
  $install_cloudmonkey       = true,
  $enable_remote_unauth_port = false
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
  validate_bool($enable_remote_unauth_port)

  # FIXME - referencing the value of $dbpassword, ideally we should set
  # the default value to '', then if we find that it wasn't specified as a
  # parameter, we should randomly generate a password.

  anchor { '::cloudstack::begin': } ->
  class { '::cloudstack::install': } ->
  class { '::cloudstack::config': } ->
  anchor { '::cloudstack::end': }

}
