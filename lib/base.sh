#!/bin/bash

#read configuration file
. $SCRIPTPATH/lib/configuration.sh

declare -r NMAP=`which nmap`
declare -r MASSCAN=`which masscan`
declare -r DIRB=`which dirb`
declare -r WHATWEB=`which whatweb`
declare -r NBTSCAN=`which nbtscan`


IP=$1
LOG=/root/$IP/log.txt

function test_program() {
  if [ ! -x $1 ]; then
    error "can't find $1 executable"
    exit 1
  fi
  return 1
}


function base_web_recon() {
	$NMAP -Pn  -p $WEB_PORT $IP | grep open | awk '{print $1}' | awk -F "/" '{print $1}' | tr "\n" "," | sed -e "s/,$/\n/" >> /root/$IP/web
#	$NMAP -Pn  -p $WEB_PORT $IP | grep open | awk '{print $1}' | awk -F "/" '{print $1}'  >> $SCAN_FOLDER/web
}

function second_stagerecon(){
	IP=$1
	FOLDER=$2
	#Script to create nmap output ports
	#$NMAP -Pn -p $DAEMON_PORT $IP | grep open | awk '{print $1}' | awk -F "/" '{print $1}' | tr "\n" "," | sed -e "s/,$/\n/" >> $FOLDER/services
	#Script to split ports line by line
	$NMAP -Pn -p $DAEMON_PORT $IP | grep open | awk '{print $1}' | awk -F "/" '{print $1}'  >> $FOLDER/services
	}

function advance_web_recon() {
	ip=$1
	folder=$2
	port=`cat $SCAN_FOLDER/web`
	service=http
	script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"
	
	$NMAP -sT -sC -sV -v0 -A -T4 -oA $SCAN_FOLDER/$ip"_WEB" -p $port $ip 
}

function services_scan(){
	IP=$1
	FOLDER=$2
	while IFS= read -r line;do
			case $line in
				21)
				  	ftp_scan $IP $FOLDER;;
			  	22)
					ssh_scan $IP $FOLDER;;
			  	23)
					telnet_scan $IP $FOLDER;;
				25)	
					smtp_scan $IP $FOLDER;;
				53)
					dns_scan $IP $FOLDER;;
				110)	
					pop_scan $IP $FOLDER;;
				445)
					smb_scan $IP $FOLDER;;
				3306)	
					mysql_scan $IP $FOLDER;;
				*)
					echo "Porta $line non testata" >> $LOG;;

			esac
		done < /root/$IP/services
	}

function ftp_scan(){
service=ftp
ip=$1
folder=$2
ports=21
script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"

nmap -d -sV --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn  > /dev/null 2>&1
}

function ssh_scan(){
service=ssh
ip=$1
folder=$2
ports=22

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"
nmap -d -sV  --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn > /dev/null 2>&1
}



function telnet_scan(){
service=telnet
ip=$1
folder=$2
ports=23

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"

nmap -d -sV --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn > /dev/null 2>&1
}



function smtp_scan(){
service=smtp
ip=$1
folder=$2
ports=25

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"

nmap -d -sV --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn > /dev/null 2>&1 
}


function dns_scan(){
service=dns
ip=$1
folder=$2
ports=53

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"

nmap -d -sV  --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn > /dev/null 2>&1
}


function pop_scan(){
service=pop
ip=$1
folder=$2
ports=110

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"

nmap -d -sV --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn > /dev/null 2>&1
}



function smb_scan(){
service=smb
ip=$1
folder=$2
ports=445

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"

#nmap con script per samba
nmap -d -sV  --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn > /dev/null 2>&1

#Netbios scan
$NBTSCAN -r $IP >> $2/$ports-nbtscan


}


function mysql_scan(){
service=mysql
ip=$1
folder=$2
ports=3306

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"

nmap -d -sV --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn > /dev/null 2>&1
}

function whatweb_assessment(){
ip=$1
folder=$2
port_number=`cat /root/$ip/web | awk -F, '{print NF}'`

for i in $( eval echo {1..$port_number} ) 
do
	port=`cat /root/$ip/web | awk -v x=$i -F, '{print $x}'`
	if [ $port == 80 ] || [ $port == 8080 ]; then
	       whatweb --color=never  http://$ip:$port > $folder/$port-Whatweb_scan
	else
	       whatweb --color=never  https://$ip:$port > $folder/$port-Whatweb_scan

	fi
       done
}

function nikto_scan (){
ip=$1
folder=$2
port_number=`cat /root/$ip/web | awk -F, '{print NF}'`

for i in $( eval echo {1..$port_number} ) 
do
	port=`cat /root/$ip/web | awk -v x=$i -F, '{print $x}'`
	if [ $port == 80 ] || [ $port == 8080 ]; then
	       nikto -h http://$ip:$port -o $folder/$port-Nikto_scan.html -F htm > /dev/null 2>&1
	else
	       nikto -h https://$ip:$port -o $folder/$port-Nikto_scan.html -F htm > /dev/null 2>&1
	fi
done
}

#Udp scan to run in backgroud 
function masscan_udp(){
ip=$1
folder=$2
masscan -p U:1-65535  $ip   -oG $folder/masscan_udp --rate=100 > /dev/null 2>&1
masscan -p 1-65535  $ip   -oG $folder/masscan_tcp --rate=100 > /dev/null 2>&1

}

