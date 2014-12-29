#include ::cloudstack
class { '::cloudstack':
  csversion  => '4.4',
  setup_repo => true,
  uses_xen   => true
}

cloudstack::zone { 'zone1': }
cloudstack::zone { 'zone2':
  networkdomain => 'foo2.com',
  networktype => 'Basic'
}
cloudstack::zone { 'zone3':
  networkdomain => 'foo3.com',
  networktype => 'Advanced'
}

cloudstack::pod { 'pod1':
  gateway  => '192.168.203.1',
  netmask  => '255.255.255.0',
  startip  => '192.168.203.200',
  endip    => '192.168.203.230',
  zonename => 'zone1'
}

cloudstack::cluster { 'cluster1':
  clustertype => 'CloudManaged',
  hypervisor  => 'XenServer',
  zonename    => 'zone1',
  podname     => 'pod1'
}
