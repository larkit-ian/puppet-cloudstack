#!/bin/bash

# Fix for cloudmonkey output display... Will be fixed in Cloudmonkey 5.3.1.
export TERM=vt100

podname=$1
zonename=$2
gateway=$3
netmask=$4
startip=$5
endip=$6

/usr/bin/cloudmonkey set display=default

zoneid=$(/usr/bin/cloudmonkey list zones name=${zonename} filter=name,id | grep -A 1 "name = ${zonename}$" | awk '/id = / {print $3}')

/usr/bin/cloudmonkey create pod zoneid=${zoneid} name=${podname} gateway=${gateway} netmask=${netmask} startip=${startip} endip=${endip}

exit 0
