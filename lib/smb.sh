#!/bin/bash
function smb_recon(){
if [ -f $SCAN_FOLDER/smb_port ]
then
	FILE_SMB="$SCAN_FOLDER/smb_port"
fi

if [ -z "$FILE_SMB" ]
then
	exit
fi

if [ ! -z "$FILE_SMB" ]
then
	while read line
	do
		#INSERIRE SMB SCRIPT
	done < $SCAN_FOLDER/web_port
fi
}

