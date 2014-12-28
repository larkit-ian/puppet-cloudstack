#
# == Class: cloudstack::cloudmonkey
# 
#   Install cloudmonkey (Cloudstack CLI shell tool) configuration
#   operations
#
# == Parameters
#
# == Actions
#
#   Installs some python modules
#   Removes the packaged version of python-requests (if on RedHat-based systems)
#   Install cloudmonkey via pip
#   Install cloudmonkey-based support scripts for CS pod and cluster creation
#
# == Requires
#
# == Sample Usage
#
# == Notes
#
#   FIXME 1:  We need SELinux labels.
#   FIXME 2:  We don't want to use the support scripts for too long.
#     Ultimately, we should go back to using the REST API.
#
class cloudstack::cloudmonkey {

  $needed_packages = [ 'readline', 'python-setuptools', 'python-pip' ]

  # Prerequisites...
  if $::osfamily == 'RedHat' {
    package { 'python-boto':
      ensure => absent,
    } ->
    package { 'python-requests':
      ensure => absent,
      before => Exec['install_cloudmonkey']
    }
  }

  package { $needed_packages:
    ensure => installed,
    before => Exec['install_cloudmonkey']
  }

  # Install Cloudmonkey itself
  exec { 'install_cloudmonkey':
    command => '/usr/bin/pip install cloudmonkey',
    unless  => '/usr/bin/which cloudmonkey 2>/dev/null'
  }

  # Utility scripts, since cloudstack has object IDs that are
  # a real pain to capture/consume via Puppet...

  File {
    ensure  => present,
    mode    => '0700',
    owner   => 'root',
    group   => 'root',
    # FIXME 1:  SELinux labels needed here.
    require => Exec['install_cloudmonkey']
  }

  # FIXME 2:  We shouldn't need these scripts at all.  We should
  # be making REST API calls.  But they're painful to make...
  $list_cluster = $::cloudstack::params::list_cluster_cmd
  $create_cluster = $::cloudstack::params::create_cluster_cmd
  $list_pod = $::cloudstack::params::list_pod_cmd
  $create_pod = $::cloudstack::params::create_pod_cmd
  file {
    "/usr/local/bin/${list_pod}":
      source => "puppet:///modules/cloudstack/${list_pod}";
    "/usr/local/bin/${create_pod}":
      source => "puppet:///modules/cloudstack/${create_pod}";
    "/usr/local/bin/${list_cluster}":
      source => "puppet:///modules/cloudstack/${list_cluster}";
    "/usr/local/bin/${create_cluster}":
      source => "puppet:///modules/cloudstack/${create_cluster}";
  }
}
