
## Explanations 
This quicks scripts allow you to migrate clients from Redhat Satellite 6.1 to 6.6.
Actually the 6.6 is the last version. 
As is just command launched remotely by SSH you can do it or adapt for another version of satellite. 

You have to have activation key available on your new satellite. 

### Details in the scripts
#
Unregister will launch 
*	launch $server "yum remove -y katello-ca-consumer\*"
	launch $server "subscription-manager remove -–all"
	launch $server "subscription-manager clean"
	launch $server "yum remove -y gofer"
	launch $server "yum remove -y katello-agent"
	launch $OLDSAT "hammer host delete --name $server"
	launch $OLDSAT "hammer host delete --name ${server}.ebu.ch"*
Register

*	launch4wget $server " wget -t 1 --timeout=3 http://satellite-ebu.ebu.ch/pub/katello-ca-consumer-latest.noarch.rpm"
	launch $server "rpm -Uvh http://satellite-ebu.ebu.ch/pub/katello-ca-consumer-latest.noarch.rpm"
	# Check if activation key exist
	launch $server "subscription-manager register --org="EBU" --activationkey=\"$ak\""
	launch $server "subscription-manager repos --enable=rhel-7-server-satellite-tools-6.6-rpms --enable=rhel-7-server-extras-rpms --enable=rhel-7-server-supplementary-rpms"
	launch $server "yum install -y katello-agent"*
