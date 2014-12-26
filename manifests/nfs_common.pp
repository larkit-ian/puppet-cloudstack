#
# == Class: cloudstack::nfs_common
#
#   This subclass provides NFS for primary and secondary storage
#   on a single machine. this is not production quality - but useful
#   for a POC/demo/dev/test environment.
#   you will either want to significantly alter or use your own nfs class
#
# == Parameters
#
# == Actions
#
# == Requires
#
# == Sample Usage
#
# == Notes
#
class cloudstack::nfs_common (
  $cs_pri_storage_nfs_server = '192.168.203.176',
  $cs_pri_storage_mnt_point  = '/primary',
  $cs_sec_storage_nfs_server = '192.168.203.176',
  $cs_sec_storage_mnt_point  = '/secondary',
  $system_tmplt_dl_cmd       = '/usr/lib64/cloud/agent/scripts/storage/secondary/cloud-install-sys-tmplt',
  $sysvm_url_kvm             = 'http://download.cloud.com/releases/2.2.0/systemvm.qcow2.bz2',
  $sysvm_url_xen             = 'http://download.cloud.com/releases/2.2.0/systemvm.vhd.bz2'
) {

  # FIXME:  Note that this means that we're not setting any parameters
  #   for the cloudstack class.  You should either provide them via Hiera
  #   or modify this code as you see fit.
  include ::cloudstack

  package {'nfs-utils':
    ensure => present
  }
  service {'nfs':
    ensure    => running,
    enable    => true,
    hasstatus => true,
    require   => [ Service[rpcbind], File['/primary'], File['/secondary'] ],
  }
  service {'rpcbind':
    ensure    => running,
    enable    => true,
    hasstatus => true,
  }
  file {'/primary':
    ensure => directory,
    path   => $cs_pri_storage_mnt_point,
    mode   => '0777',
    owner  => 'root',
    group  => 'root'
  }
  file {'/secondary':
    ensure => directory,
    path   => $cs_sec_storage_mnt_point,
    mode   => '0777',
    owner  => 'root',
    group  => 'root'
  }
  file {'/etc/sysconfig/nfs':
    source => 'puppet:///modules/cloudstack/nfs',
    notify => Service[nfs],
  }

  file {'/etc/exports':
    source => template('cloudstack/exports.erb'),
    notify => Service[nfs],
  }

  firewall {'100 INPUT NFS UDP ports':
    chain  => 'INPUT'
    proto  => 'udp',
    dport  => [ '111', '32769', '892', '875', '662' ],
    action => 'accept'
  }

  firewall {'100 INPUT NFS TCP ports':
    chain  => 'INPUT',
    proto  => 'tcp',
    dport  => [ '111', '2049', '32803', '892', '875', '662' ],
    action => 'accept'
  }
}
