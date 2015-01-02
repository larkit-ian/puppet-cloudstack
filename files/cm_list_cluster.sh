#!/bin/bash

# Fix for cloudmonkey output display... Fixed in Cloudmonkey 5.3.1, but it isn't available yet...
export TERM=vt100

zonename=$1
podname=$2
clustername=$3

zoneid=$(/usr/bin/cloudmonkey list zones name=${zonename} filter=name,id | grep -A 1 "name = ${zonename}$" | awk '/id = / {print $3}')

podid=$(/usr/bin/cloudmonkey list pods name=${podname} zoneid=${zoneid} filter=name,id | grep -A 1 "name = ${podname}$" | awk '/id = / {print $3}')

clusterid=$(/usr/bin/cloudmonkey list clusters name=${clustername} podid=${podid} zoneid=${zoneid} filter=name,id | grep -A 1 "name = ${clustername}$" | awk '/id = / {print $3}')

if [ $(echo $clusterid | wc -c) -gt 5 ];
	# Cluster exists.  We're done here.
	exit 0
else
	exit 1
fi
