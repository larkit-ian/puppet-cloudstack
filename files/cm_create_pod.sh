#!/bin/bash

# Fix for cloudmonkey output display... Fixed in Cloudmonkey 5.3.1, but it isn't available yet...
export TERM=vt100

podname=$1
zonename=$2
gateway=$3
netmask=$4
startip=$5
endip=$6

zoneid=$(/usr/bin/cloudmonkey list zones name=${zonename} filter=id)
podexists=$(/usr/bin/cloudmonkey list pods name=${podname} zoneid=${zoneid} filter=id)
if [ a"${podexists}" != "a" ]; then
	# Pod exists.  We're done here.
	exit 0
fi

# Apparently, the pod doesn't exist.  Let's create it.
/usr/bin/cloudmonkey create pod zoneid=${zoneid} name=${podname} gateway=${gateway} netmask=${netmask} startip=${startip} endip=${endip}

exit 0
