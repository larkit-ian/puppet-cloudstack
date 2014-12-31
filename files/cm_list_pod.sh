#!/bin/bash

# Fix for cloudmonkey output display... Fixed in Cloudmonkey 5.3.1, but it isn't available yet...
export TERM=vt100

zonename=$1
podname=$2

zoneid=$(/usr/bin/cloudmonkey list zones name=${zonename} filter=id)

# The grep at the end of this is due to a potential cloudmonkey regex bug that makes
# it report partial name matches on objects, unfortunately.  This behavior exists in
# Cloudmonkey 5.3.0 AND 5.3.1 (as of 20141230)

podexists=$(/usr/bin/cloudmonkey list pods name=${podname} zoneid=${zoneid} filter=id,name | grep -q "^name = ${podname}$")
ccstatus=$?
if [ ${ccstatus} -eq 0 ]; then
	# Pod exists.  We're done here.
	exit 0
else
	exit 1
fi
