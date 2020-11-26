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
	enum4linux -a -u "" -p "" $IP >> $SCAN_FOLDER/smb_result.txt
	enum4linux -a -u "guest" -p "" $IP >> $SCAN_FOLDER/smb_result.txt
	smbmap -u "" -p "" -P 445 -H $IP >> $SCAN_FOLDER/smb_result.txt 
	smbmap -u "guest" -p "" -P 445 -H $IP >> $SCAN_FOLDER/smb_result.txt
	smbclient -U '%' -L //$IP && smbclient -U 'guest%' -L //$IP >> $SCAN_FOLDER/smb_result.txt
	smbmap -H $IP >> $SCAN_FOLDER/smb_map_enum
	smbmap  -H $IP -R --depth 5 >> $SCAN_FOLDER/smb_map_enum
	nmap -v -p139,445 --script=smb-enum* -oN $SCAN_FOLDER/smb_nmap_script_scan $IP
fi
}

