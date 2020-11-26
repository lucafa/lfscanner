#!/bin/bash
#Script per enumeration di rete in modo rapido 
#Use: lfscanner.sh <IP_TO_SCAN>

IP=$@
LOCAL_DIR=`pwd`
SCAN_FOLDER="$LOCAL_DIR/$IP"

if [ ! -L $0 ]; then
	SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
else
	SCRIPTPATH=`dirname $(readlink -f $0)`
fi

#read configuration file
. $SCRIPTPATH/lib/base.sh
. $SCRIPTPATH/lib/configuration.sh
. $SCRIPTPATH/lib/web.sh
. $SCRIPTPATH/lib/smb.sh

#Create folder for result
if [ ! -x $SCAN_FOLDER ];then
	mkdir $SCAN_FOLDER
fi

#Basic scan using masscan on all tcp ports
basic_udp_scan $IP $SCAN_FOLDER &
basic_tcp_scan $IP $SCAN_FOLDER
extract_tcp_port $SCAN_FOLDER

#Detailed scan using nmap
nmap_scan $IP $SCAN_FOLDER

port_service $SCAN_FOLDER

#Basic web recon
web_recon $IP $SCAN_FOLDER
ftp_scan $IP $SCAN_FOLDER &
smb_recon $IP $SCAN_FOLDER &
exit

#Advanced web recon
if [ -s $SCAN_FOLDER/web ]; then
		     advance_web_recon $IP   $SCAN_FOLDER 
fi

#Second stage recon (main services)
second_stagerecon $IP $SCAN_FOLDER

#Services scan
services_scan $IP $SCAN_FOLDER
