#!/bin/bash

# Fix for cloudmonkey output display... Fixed in Cloudmonkey 5.3.1, but it isn't available yet...
export TERM=vt100

zonename=$1
podname=$2

zoneid=$(/usr/bin/cloudmonkey list zones name=${zonename} filter=id)
podexists=$(/usr/bin/cloudmonkey list pods name=${podname} zoneid=${zoneid} filter=id)
if [ a"${podexists}" != "a" ]; then
	# Pod exists.  We're done here.
	exit 0
else
	exit 1
fi
