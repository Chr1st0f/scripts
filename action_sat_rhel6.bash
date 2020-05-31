#!/bin/bash

# Purpose : Tool for the satellite migration
# The functions of this script are :
# unregister :  Will unregister and delete the client on the old satellite 
#				unistall management products ( katello, gofer ) 
# register   :  Will register client on the new satellite 
#				in providing the activation key on the new satellite 
#				activate repos and install the necessary management packages 
#
#
# Author : Cazin Christophe 05/2020
#
# Declartion part #############################################
flag_u=false
flag_r=false
flag_v=false 
OLDSAT="satellite.ebu.ch"
NEWSAT="satellite-ebu.ebu.ch"
SSHOPTIONS='-o StrictHostKeyChecking=no -o ConnectTimeout=1 -o ConnectionAttempts=1 -o PubkeyAuthentication=yes -o PreferredAuthentications=publickey'
SUDO="sudo"
red="1"
green="2"
blue="4"

# Function part ###############################################
usage ()
{
	echo  "Usage : $0 [-u] | [ -r -a <activationkey> ] -s <server> [-h|usage] -v\n"
	echo " -v : verbose mode"
	echo  "e.g   : To unregister servername "
	echo "         $0 -u -s servername"
	exit 2
}
register()
{
	print_res "### Register new host $server for ak $ak ###"
	launch4wget $server " wget -t 1 --timeout=3 http://satellite-ebu.ebu.ch/pub/katello-ca-consumer-latest.noarch.rpm"
	launch $server "rpm -Uvh http://satellite-ebu.ebu.ch/pub/katello-ca-consumer-latest.noarch.rpm"
	# Check if activation key exist
	launch $server "subscription-manager register --org="EBU" --activationkey=\"$ak\""
# Repos to activate on RHEL 7
#	launch $server "subscription-manager repos --enable=rhel-7-server-satellite-tools-6.6-rpms --enable=rhel-7-server-extras-rpms --enable=rhel-7-server-supplementary-rpms"
# Repos to activate on RHEL 6
	launch $server "subscription-manager repos --enable=rhel-6-server-rpms --enable=rhel-6-server-extras-rpms --enable=rhel-6-server-optional-rpms --enable=rhel-6-server-satellite-tools-6.6-rpms --enable=rhel-6-server-rh-common-rpms"
	launch $server "yum install -y katello-agent"

}
unregister()
{
	print_res "### Unregister host $server ###"
	print_res "### Remove $server on $OLDSAT ###"

	launch $server "yum remove -y katello-ca-consumer*"
	launch $server "subscription-manager remove -–all"
	launch $server "subscription-manager clean"
	launch $server "yum remove -y gofer"
	launch $server "yum remove -y katello-agent"
	launch $OLDSAT "hammer host delete --name $server"
	launch $OLDSAT "hammer host delete --name ${server}.ebu.ch"
}
launch()
{
	SERVER="$1"; shift ;COMMAND="$*"
	launch_on_s $SERVER $SUDO $COMMAND
	ret=$? ; [ $ret -eq 0 ] && STATUS="0" || STATUS="1"
	print_res " Return code -> $ret - on $SERVER - $COMMAND -" $STATUS
}
# Same launch but specific for wget command if problem we stop the migration
launch4wget()
{
	SERVER="$1"; shift ;COMMAND="$*"
	launch_on_s $SERVER $SUDO $COMMAND
	ret=$? ; [ $ret -eq 0 ] && STATUS="0" || STATUS="1"
	print_res " Return code -> $ret - on $SERVER - $COMMAND -" $STATUS
	! [ $ret -eq 0 ] && print_res "Satellite-ebu FW issue. Exit 0" $STATUS && exit 0
}
launch_on_s()
{
 SERVER="$1"; shift ;COMMAND="$*"

 # if flag_v ( verbose ) we print output
 if $flag_v 
	then
		ssh -t $SSHOPTIONS $SERVER "$COMMAND" 2>/dev/null 
	else
		ssh -t $SSHOPTIONS $SERVER "$COMMAND" 2>/dev/null 1>/dev/null
 fi
}

print_res()
{
 case $2 in
  0) tput setaf $green; echo -n "SUCC: " ;;
  1) tput setaf $red; echo -n "ERR : ";  ;;
  *) tput setaf $blue; echo -n "INFO: ";  ;;
 esac
 tput sgr0
 echo "# $1 #"
}

# Main ##############################################################
# a: the colon after the letter means there is a field after this parameter $OPTARG
# c no colon means it is a flag to trigger

while getopts :ura:hs:v options; do 
	case $options in
		u) flag_u=true ;;
		r) flag_r=true ;;
		a) ak=$OPTARG;;
		s) server=$OPTARG;;
		v) flag_v=true ;;
		?) print_res "parameter $OPTARG not allowed" 1 && usage ;; 
		:) print_res "option $OPTARG need an argument" 1&& usage ;; 
		h) usage;;
		*) usage;;
	esac
done
shift "$((OPTIND-1))"

! $flag_u && ! $flag_r && \
print_res "-u or -r option is mandatory" 1 && usage 

# a server -s need to be provided 
[ -z $server ] && \
print_res "a server -s option need to be provided" 1 && usage 

# Unregister and register note allowed in the same time 
$flag_u && $flag_r && \
 print_res "-u and -r parameter not allowed in same time" 1 && usage 

# When -r option -a ( activation key ) has to be filled 
# When register a activation is necessary to register in the ne satellite 
$flag_r && [ -z $ak ] && \
print_res "if -r ( register ) you have to provide an activation key -a option" 1&& usage 

$flag_u && unregister && exit 0
$flag_r && register && exit 0

