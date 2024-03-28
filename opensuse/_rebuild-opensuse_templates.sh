#!/bin/bash

# =======================================================================================================
# TEMPLATE ONLY - Copy this file to ./rebuild-opensuse-templates.sh and configure that file for your needs.
# =======================================================================================================

ACCOUNT_NAME=sysadmin
PASSWORD=P4zzw0rd123
DOMAIN=lab.example.com
SSH_KEY_ID=jdoe

HOSTNAME=$(echo `hostname` | cut -d'.' -f1)
HOST_DIGIT=${HOSTNAME: -1}

echo "[*] Rebuilding 'openSUSE Leap 15.1'..."
./prox-cloud-template-add-opensuse.sh ${HOST_DIGIT}01510 SSD-0${HOST_DIGIT}A Leap 15.1 $ACCOUNT_NAME $PASSWORD $DOMAIN $SSH_KEY_ID

echo "[*] Rebuilding 'openSUSE Leap 15.2'..."
./prox-cloud-template-add-opensuse.sh ${HOST_DIGIT}01520 SSD-0${HOST_DIGIT}A Leap 15.2 $ACCOUNT_NAME $PASSWORD $DOMAIN $SSH_KEY_ID

echo "[*] Rebuilding 'openSUSE Leap 15.3'..."
./prox-cloud-template-add-opensuse.sh ${HOST_DIGIT}01530 SSD-0${HOST_DIGIT}A Leap 15.3 $ACCOUNT_NAME $PASSWORD $DOMAIN $SSH_KEY_ID

# In this template, this assumes that your ProxMox server names end in a single digit
# and that this script is running on one of those ProxMox nodes. Example: pmvm3
#
# Next, on this ProxMox node, it's assumed there is storage configured with the name
# "SSD-03A", "SSD-03B", etc where the 3 refers to the node number, so that you can
# differentiate this storage when looking at a cluster view.
#
# Similarly, VM id's can be anything, but to make it consistent, this assumes that
# VM's or templates on the pmvm3 machine, start with the number 3. And in this case
# these templates will be created with high numbers (e.g. 301510, 30153, etc) to
# keep them at the end of the list of VM's. The "1510" and "1530" is metadata for the
# version of that distribution (e.g. "1510" is openSUSE 15.1, for example)