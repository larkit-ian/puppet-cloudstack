#
# Class: cloudstack::clourmonkey
# Purpose:  Install cloudmoney on the management server for configuration
#   operations
#
class cloudstack::cloudmonkey {

  # Prerequisites...
  $needed_packages = [ 'readline', 'python-setuptools' ]

  package { $needed_packages:
    ensure => installed,
    before => Exec['install_cloudmonkey']
  }

  # Install Cloudmonkey itself
  exec { 'install_cloudmonkey':
    command => '/usr/bin/easy_install cloudmonkey',
    unless  => '/usr/bin/which cloudmonkey 2>/dev/null'
  }

  # Utility scripts, since cloudstack has object IDs that are
  # a real pain to capture/consume via Puppet...
  file { '/usr/local/bin/cm_createpod.sh':
    ensure => present,
    mode   => '0700',
    owner  => 'root',
    group  => 'root',
    # FIXME:  SELinux labels needed here.
    source => 'puppet:///modules/cloudstack/cm_create_pod.sh',
    require => Exec['install_cloudmonkey']
  } 
}
