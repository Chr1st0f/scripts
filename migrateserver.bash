#!/bin/bash

#ak="ak-qual-vm-rhel-7-x86_64"
#ak="ak-prod-vm-rhel-7-x86_64"
#ak="ak-prod-vm-rhel-5-i386"
ak="ak-prod-vm-rhel-6-x86_64"

server="$1"

#echo "- Waiting for enter to continue -" && read t
echo "*** Migration of $server ***"
./action_sat.bash -u -s $server
#echo "- Waiting for enter to continue -" && read t
./action_sat.bash -r -a $ak -s $server

