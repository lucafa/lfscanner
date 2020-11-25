#!/bin/bash

#read configuration file
. $SCRIPTPATH/lib/configuration.sh

declare -r NMAP=`which nmap`
declare -r MASSCAN=`which masscan`
declare -r DIRB=`which dirb`

IP=$1
LOG=/root/$IP/log.txt

function test_program() {
  if [ ! -x $1 ]; then
    error "can't find $1 executable"
    exit 1
  fi
  return 1
}

function extract_port(){
cat "$SCAN_FOLDER/basic_tcp" | grep open | awk '{print $3}' >> $SCAN_FOLDER/tcp_ports
}

function basic_tcp_scan() {
	$MASSCAN -p1-1024 -oL "$SCAN_FOLDER/basic_tcp" $IP --rate=100
}

function basic_udp_scan() {
	$MASSCAN -pU:1-65535 $IP --rate=300
}


function nmap_scan() {
	PORTS=`cat $SCAN_FOLDER/tcp_ports |  tr "\n" "," | sed -e "s/ //g" | sed -e "s/,$//"`
	$NMAP -sTV -sC -O -A -p $PORTS $IP --reason -oN $SCAN_FOLDER/nmap_scan
}

function port_service(){
	FILE="$SCAN_FOLDER/nmap_scan"
	while read line
	do
		SERVICE=`echo $line | grep "/tcp" | grep -v "|" | awk '{print $3}'`
		if [[ $SERVICE == "http" ]]
		then
			PORTS=`echo $line | grep "/tcp" | grep -v "|" | awk -F"/" '{print $1}'`
			echo $PORTS >> $SCAN_FOLDER/web_port
		fi
		if [[ $SERVICE == *"https"* ]]
		then
			PORTS=`echo $line | grep "/tcp" | grep -v "|" | awk -F"/" '{print $1}'`
			echo $PORTS >> $SCAN_FOLDER/web_ssl_port
		fi
		if [[ $SERVICE == "netbios-ssn" || $SERVICE == "microsoft-ds" ]]
		then
			PORTS=`echo $line | grep "/tcp" | grep -v "|" | awk -F"/" '{print $1}'`
			echo $PORTS >> $SCAN_FOLDER/smb_port
		fi
		if [[ $SERVICE == "ftp"  ]]
		then
			PORTS=`echo $line | grep "/tcp" | grep -v "|" | awk -F"/" '{print $1}'`
			echo $PORTS >> $SCAN_FOLDER/ftp_port
		fi
		if [[ $SERVICE == "ssh"  ]]
		then
			PORTS=`echo $line | grep "/tcp" | grep -v "|" | awk -F"/" '{print $1}'`
			echo $PORTS >> $SCAN_FOLDER/ssh_port
		fi

	done < $SCAN_FOLDER/nmap_scan
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
	IP=$1
	FOLDER=$2
	PORT=`cat $SCAN_FOLDER/web`
	$NMAP -sT -sC -sV -v0 -A -T4 -oA $SCAN_FOLDER/$IP"_WEB" -p $PORT $IP 
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

nmap -d -sV --script=$script $ip -oA $ip-$service -v -n -p$ports -PN –sV --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn 
}

function ssh_scan(){
service=ssh
ip=$1
folder=$2
ports=22

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"
nmap -d -sV  --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn
}



function telnet_scan(){
service=telnet
ip=$1
folder=$2
ports=23

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"

nmap -d -sV --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn
}



function smtp_scan(){
service=smtp
ip=$1
folder=$2
ports=25

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"

nmap -d -sV --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn 
}


function dns_scan(){
service=dns
ip=$1
folder=$2
ports=53

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"

nmap -d -sV  --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn
}


function pop_scan(){
service=pop
ip=$1
folder=$2
ports=110

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"

nmap -d -sV --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn
}



function smb_scan(){
service=smb
ip=$1
folder=$2
ports=445

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"

nmap -d -sV  --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn
}


function mysql__scan(){
service=mysql
ip=$1
folder=$2
ports=445

script=$(ls /usr/share/nmap/scripts/ | grep $service | grep -v "flood\|brute\|slowloris\|psexec\|dos" | tr '\n' ',' | sed -e "s/,$//"); echo -e "\n============\nTarget\t $ip\nPorts\t$ports\nScripts\t $script\nOutput\t$ip-$service\n==================\n"

nmap -d -sV --script=$script $ip -oA $folder/$ip-$service -v -n -p$ports -Pn
}


