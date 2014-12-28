#!/bin/bash

# Fix for cloudmonkey output display... Fixed in Cloudmonkey 5.3.1, but it isn't available yet...
export TERM=vt100

zonename=$1
podname=$2
clustername=$3

zoneid=$(/usr/bin/cloudmonkey list zones name=${zonename} filter=id)
podid=$(/usr/bin/cloudmonkey list pods name=${podname} zoneid=${zoneid} filter=id)
clusterexists=$(/usr/bin/cloudmonkey list clusters name=${clustername} podid=${podid} zoneid=${zoneid} filter=id)
if [ a"${clusterexists}" != "a" ]; then
	# Cluster exists.  We're done here.
	exit 0
else
	exit 1
fi

