#
# == Class: cloudstack::cloudmonkey
# == Purpose
#   Install cloudmonkey on the management server for configuration
#   operations
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

  File {
    ensure => present,
    mode   => '0700',
    owner  => 'root',
    group  => 'root',
    # FIXME:  SELinux labels needed here.
    require => Exec['install_cloudmonkey']
  }

  file {
    '/usr/local/bin/cm_create_pod.sh':
      source => "puppet:///modules/cloudstack/cm_create_pod.sh";
    '/usr/local/bin/cm_add_cluster.sh':
      source => "puppet:///modules/cloudstack/cm_add_cluster.sh";
  } 
}
