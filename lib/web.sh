#!/bin/bash
function web_recon(){
if [ -f $SCAN_FOLDER/web_port ]
then
	FILE_HTTP="$SCAN_FOLDER/web_port"
fi
if [ -f $SCAN_FOLDER/web_ssl_port ]
then
	FILE_HTTPS="$SCAN_FOLDER/web_ssl_port"
fi

if [ -z "$FILE_HTTP" ] && [ -z "$FILE_HTTPS" ]
then
	echo "FILE NON TROVATO"
	exit
fi
if [ ! -z "$FILE_HTTP" ]
then
	while read line
	do
		nikto -h http://$IP -output $SCAN_FOLDER/nikto_scan_$line.txt -maxtime 20
		dirb -o $SCAN_FOLDER/dirb_$line.txt http://$IP /usr/share/dirb/wordlists/vulns/apache.txt 

	done < $SCAN_FOLDER/web_port
fi
	

if [ ! -z "$FILE_HTTPS" ]
then
	while read line
	do
		nikto -h https://$IP -output $SCAN_FOLDER/nikto_scan_$line.txt -maxtime 20
		dirb -o $SCAN_FOLDER/dirb_$line.txt https://$IP /usr/share/dirb/wordlists/vulns/apache.txt 

	done < $SCAN_FOLDER/web_port
fi
}

