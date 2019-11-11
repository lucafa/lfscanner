#!/bin/bash
#Script per enumeration di rete in modo rapido 

IP=$@
SCAN_FOLDER="/root/$IP"
if [ ! -L $0 ]; then
	SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
else
	SCRIPTPATH=`dirname $(readlink -f $0)`
fi

#read configuration file
. $SCRIPTPATH/lib/base.sh
. $SCRIPTPATH/lib/configuration.sh

#Create folder for result
if [ ! -x $SCAN_FOLDER ];then
	mkdir $SCAN_FOLDER
fi

#Masscan in backgroud
masscan_udp $IP $SCAN_FOLDER &
echo "[START UDP ASSESSMENT ON ALL UDP AND TCP PORTS OF THE HOST $IP]"
sleep 1

#Basic web recon
echo "[START SCAN ON TIPICAL WEBPORTS OF THE HOST $IP]"
base_web_recon $IP

#Advanced web recon
echo "[START ADVANCE WEB RECON ON THE HOST $IP]"
if [ -s $SCAN_FOLDER/web ]; then
		advance_web_recon $IP   $SCAN_FOLDER 
fi

#Second stage recon (main services)
echo "[START SCAN ON TIPICAL SERVICES OF THE HOST $IP]"
second_stagerecon $IP $SCAN_FOLDER

#Services scan
echo "[START DEEP SCAN ON ACTIVE SERVICE OF THE HOST $IP]"
services_scan $IP $SCAN_FOLDER

#whatweb assessment
echo "[START WHATWEB ASSESSMENT ON THE WEBPORTS OF THE HOST $IP]"
whatweb_assessment $IP $SCAN_FOLDER

#Nikto assessment
echo "[START NIKTO SCAN ON WEBPORTS OF THE HOST $IP]"
nikto_scan $IP $SCAN_FOLDER
