#!/bin/bash

# ==============================================================================================
# TEMPLATE ONLY - Copy this file to ./push-to-proxmox.sh and configure that file for your needs.
# ==============================================================================================

DOMAIN=lab.example.com

INDEX=0

while [[ $INDEX -lt 6 ]]
do
	((INDEX++))
	echo "[*] Pushing cloud image scripts to: pmvm${INDEX}.$DOMAIN"
	ssh root@pmvm${INDEX}.$DOMAIN 'mkdir -p /root/cloud-init/centos/ ; mkdir -p /root/cloud-init/ubuntu/'
	
	scp ./centos/prox-cloud-template-add-centos.sh root@pmvm${INDEX}.$DOMAIN:/root/cloud-init/centos/
	
	if [ ! -f ./centos/rebuild-centos-templates.sh ]; then
    	echo "[-] The file rebuild-centos-templates.sh does not exist. Consider copying the _rebuild-centos-templates.sh template and configuring for your needs."
	else
		scp ./centos/rebuild-centos-templates.sh root@pmvm${INDEX}.$DOMAIN:/root/cloud-init/centos/
	fi
	
	scp ./ubuntu/prox-cloud-template-add-ubuntu.sh root@pmvm${INDEX}.$DOMAIN:/root/cloud-init/ubuntu/
	
	if [ ! -f ./ubuntu/rebuild-ubuntu-templates.sh ]; then
	    echo "[-] The file rebuild-ubuntu-templates.sh does not exist. Consider copying the _rebuild-ubuntu-templates.sh template and configuring for your needs."
	else
		scp ./ubuntu/rebuild-ubuntu-templates.sh root@pmvm${INDEX}.$DOMAIN:/root/cloud-init/ubuntu/
	fi
	
	scp ./rebuild-all-templates.sh root@pmvm${INDEX}.$DOMAIN:/root/cloud-init/
done

# In this template, this would loop through:
#
#   pmvm1.lab.example.com
#   pmvm2.lab.example.com
#   pmvm3.lab.example.com
#   pmvm4.lab.example.com
#   pmvm5.lab.example.com
#   pmvm6.lab.example.com
#
# Where the number portion of the hostname is ${INDEX}. Change the hostname 
# and domain for whatever your needs, and change the $INDEX on line 7 to however
# many servers you have.
#
# This creates a /root/cloud-init/ folder with a centos and ubuntu folder under that,
# and pushes out all of the relevant scripts so that they are the same on all of your
# ProxMox servers.
