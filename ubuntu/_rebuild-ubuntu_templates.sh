#!/bin/bash

# =======================================================================================================
# TEMPLATE ONLY - Copy this file to ./rebuild-ubuntu-templates.sh and configure that file for your needs.
# =======================================================================================================

ACCOUNT_NAME=sysadmin
PASSWORD=P4zzw0rd123
DOMAIN=lab.example.com
SSH_KEY_ID=jdoe

HOSTNAME=$(echo `hostname` | cut -d'.' -f1)
HOST_DIGIT=${HOSTNAME: -1}

echo "[*] Rebuilding 'Ubuntu 22.04 (jammy)'..."
./prox-cloud-template-add-ubuntu.sh ${HOST_DIGIT}02204 SSD-0${HOST_DIGIT}A jammy 22.04 $ACCOUNT_NAME $PASSWORD $DOMAIN $SSH_KEY_ID

echo "[*] Rebuilding 'Ubuntu 20.04 (focal)'..."
./prox-cloud-template-add-ubuntu.sh ${HOST_DIGIT}02004 SSD-0${HOST_DIGIT}A focal 20.04 $ACCOUNT_NAME $PASSWORD $DOMAIN $SSH_KEY_ID

echo "[*] Rebuilding 'Ubuntu 18.04 (bionic)'..."
./prox-cloud-template-add-ubuntu.sh ${HOST_DIGIT}01804 SSD-0${HOST_DIGIT}A bionic 18.04 $ACCOUNT_NAME $PASSWORD $DOMAIN $SSH_KEY_ID

echo "[*] Rebuilding 'Ubuntu 16.04 (xenial)'..."
./prox-cloud-template-add-ubuntu.sh ${HOST_DIGIT}01604 SSD-0${HOST_DIGIT}A xenial 16.04 $ACCOUNT_NAME $PASSWORD $DOMAIN $SSH_KEY_ID

# In this template, this assumes that your ProxMox server names end in a single digit
# and that this script is running on one of those ProxMox nodes. Example: pmvm3
#
# Next, on this ProxMox node, it's assumed there is storage configured with the name
# "SSD-03A", "SSD-03B", etc where the 3 refers to the node number, so that you can
# differentiate this storage when looking at a cluster view.
#
# Similarly, VM id's can be anything, but to make it consistent, this assumes that
# VM's or templates on the pmvm3 machine, start with the number 3. And in this case
# these templates will be created with high numbers (e.g. 301804, 302204, etc) to
# keep them at the end of the list of VM's. The "1804" and "2204" is metadata for the
# version of that distribution (e.g. "1804" is Ubuntu 18.04, for example)