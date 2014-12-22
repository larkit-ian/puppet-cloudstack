#
## Class: cloudstack::nfs_common
#
# This subclass provides NFS for primary and secondary storage
# on a single machine. this is not production quality - but useful
# for a POC/demo/dev/test environment.
# you will either want to significantly alter or use your own nfs class
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

  include cloudstack

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
    path   => $cs_pri_storage_mnt_point,
    ensure => directory,
    mode   => '0777',
    owner  => 'root',
    group  => 'root'
  }
  file {'/secondary':
    path   => $cs_sec_storage_mnt_point,
    ensure => directory,
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

  firewall {'111 udp':
    proto  => 'udp',
    dport  => '111',
    action => 'accept',
  }

  firewall {'111 tcp':
    proto  => 'tcp',
    dport  => '111',
    action => 'accept',
  }

  firewall {'2049 tcp':
    proto  => 'tcp',
    dport  => '2049',
    action => 'accept',
  }

  firewall {'32803 tcp':
    proto  => 'tcp',
    dport  => '32803',
    action => 'accept',
  }

  firewall {'32769 udp':
    proto  => 'udp',
    dport  => '32769',
    action => 'accept',
  }

  firewall {'892 tcp':
    proto  => 'tcp',
    dport  => '892',
    action => 'accept',
  }

  firewall {'892 udp':
    proto  => 'udp',
    dport  => '892',
    action => 'accept',
  }

  firewall {'875 tcp':
    proto  => 'tcp',
    dport  => '875',
    action => 'accept',
  }

  firewall {'875 udp':
    proto  => 'udp',
    dport  => '875',
    action => 'accept',
  }

  firewall {'662 tcp':
    proto  => 'tcp',
    dport  => '662',
    action => 'accept',
  }

  firewall {'662 udp':
    proto  => 'udp',
    dport  => '662',
    action => 'accept',
  }

}
