#
# == Class: cloudstack::cloudmonkey
# 
#   Install cloudmonkey (Cloudstack CLI shell tool) configuration
#   operations
#
# == Actions
#
#   Installs some python modules
#   Removes the packaged version of python-requests (if on RedHat-based systems)
#   Install cloudmonkey via pip
#   Install cloudmonkey-based support scripts for CS pod and cluster creation
#
# == Sample Usage
#
#   include ::cloudstack::cloudmonkey
#
class cloudstack::cloudmonkey (
) inherits cloudstack::params {

  # Variables

  $ospath                   = $::cloudstack::params::ospath
  $list_cluster             = $::cloudstack::params::list_cluster_cmd
  $create_cluster           = $::cloudstack::params::create_cluster_cmd
  $list_pod                 = $::cloudstack::params::list_pod_cmd
  $create_pod               = $::cloudstack::params::create_pod_cmd
  $cm_unneeded_package_flag = $::cloudstack::params::cm_unneeded_package_flag
  $cm_unneeded_pkglist1     = $::cloudstack::params::cm_unneeded_pkglist1
  $cm_unneeded_pkglist2     = $::cloudstack::params::cm_unneeded_pkglist2

  $needed_packages = [ 'readline', 'python-setuptools', 'python-pip' ]

  # Resources

  if $cm_unneeded_package_flag {
    package { $cm_unneeded_pkglist1: ensure => absent }
    package { $cm_unneeded_pkglist2: ensure => absent }
  }

  package { $needed_packages: ensure => installed }

  exec { 'install_cloudmonkey':
    command => 'pip install cloudmonkey',
    creates => '/usr/bin/cloudmonkey',
    path    => $ospath
  }

  #   Utility scripts, since cloudstack has object IDs that are
  #   a real pain to capture/consume via Puppet...

  File {
    ensure  => present,
    mode    => '0700',
    owner   => 'root',
    group   => 'root'
  #   FIXME:  SELinux labels needed here.
  }

  #   FIXME:  We shouldn't need these scripts at all.  We should
  #   be making REST API calls.  But they're painful to make...
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

  # Finally, our dependencies...

  if $cm_unneeded_package_flag {
    Package[$cm_unneeded_pkglist1] ->
      Package[$cm_unneeded_pkglist2] ->
      Exec['install_cloudmonkey']
  }
  Package[$needed_packages] ->
    Exec['install_cloudmonkey'] ->
    File[
      "/usr/local/bin/${list_pod}",
      "/usr/local/bin/${create_pod}",
      "/usr/local/bin/${list_cluster}",
      "/usr/local/bin/${create_cluster}"
    ]
}
