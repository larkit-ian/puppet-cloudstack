#!/bin/bash

# Add Cloudstack cluster - cloudmonkey version

# Invocation:
#
#     /usr/local/bin/cm_addcluster.sh ${name} ${clustertype} ${hypervisor} ${podname} ${zonename}
#
# Fix for cloudmonkey output display... Fixed in Cloudmonkey 5.3.1, but it isn't available yet...
export TERM=vt100

clustername=$1
clustertype=$2
hypervisor=$3
podname=$4
zonename=$5

zoneid=$(/usr/bin/cloudmonkey list zones name=${zonename} filter=name,id | grep -A 1 "name = ${zonename}$" | awk '/id = / {print $3}')
podid=$(/usr/bin/cloudmonkey list pods name=${podname} zoneid=${zoneid} filter=name,id | grep -A 1 "name = ${podname}$" | awk '/id = / {print $3}')

/usr/bin/cloudmonkey add cluster clustername=${clustername} clustertype=${clustertype} hypervisor=${hypervisor} podid=${podid} zoneid=${zoneid}

exit 0
