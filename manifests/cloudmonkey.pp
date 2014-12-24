#
# Class: cloudstack::clourmonkey
# Purpose:  Install cloudmoney on the management server for configuration
#   operations
#
# FIXME: Make this an optional component...
#
class cloudstack::cloudmonkey {

  # Prerequisites...
  $needed_packages = [ 'readline', 'python-setuptools' ]

  package { $needed_packages:
    ensure => installed,
    before => Exec['install_cloudmonkey']
  }

  package { 'python-requests':
    ensure => absent,
    before => Exec['install_cloudmonkey']
  }

  # Install Cloudmonkey itself
  exec { 'install_cloudmonkey':
    command => '/usr/bin/pip install cloudmonkey',
    unless  => '/usr/bin/which cloudmonkey 2>/dev/null'
  }

  # Utility scripts, since cloudstack has object IDs that are
  # a real pain to capture/consume via Puppet...
 
  $scriptnames = [ 'cm_create_pod.sh', 'cm_add_cluster.sh' ]

  file { $scriptnames:
    ensure => present,
    path   => "/usr/local/bin/${scriptnames}",
    mode   => '0700',
    owner  => 'root',
    group  => 'root',
    # FIXME:  SELinux labels needed here.
    source => "puppet:///modules/cloudstack/${scriptnames}",
    require => Exec['install_cloudmonkey']
  } 
  } 
}
