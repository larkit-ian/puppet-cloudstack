#
# Class: cloudstack::clourmonkey
# Purpose:  Install cloudmoney on the management server for configuration
#   operations
#
class cloudstack::cloudmonkey {
  $needed_packages = [ 'readline', 'python-setuptools' ]

  package { $needed_packages:
    ensure => installed,
    before => Exec['install_cloudmonkey']
  }

  exec { 'install_cloudmonkey':
    command => '/usr/bin/easy_install cloudmonkey',
    unless  => '/usr/bin/which cloudmonkey 2>/dev/null'
  }
}
