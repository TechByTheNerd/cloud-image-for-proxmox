#!/bin/bash

# NOTE: Requires apt-get install libguestfs-tools

Black='\033[0;30m'
DarkGray='\033[1;30m'
Red='\033[0;31m'
LightRed='\033[1;31m'
Green='\033[0;32m'
LightGreen='\033[1;32m'
Brown='\033[0;33m'
Yellow='\033[1;33m'
Blue='\033[0;34m'
LightBlue='\033[1;34m'
Purple='\033[0;35m'
LightPurple='\033[1;35m'
Cyan='\033[0;36m'
LightCyan='\033[1;36m'
LightGray='\033[0;37m'
White='\033[1;37m'
NC='\033[0m' # No Color

Name='ProxMox / CentOS Cloud Init Image Creation Utility (PUCIICU)'
Version='v1.0.0-alpha.11'

echo -e "${LightPurple}$Name $Version${NC}"
echo ""

if [[ "$1" == "" || $1 == "?" || $1 == "/?" || $1 == "--help" ]];
then
    echo -e "USAGE: sudo $0 [id] [storage] [version] [user] [password] \
        [searchdomain] [sshkeyid]\n\n\tsudo $0 4000 SSD-01A 9-stream sysadmin \
        G00dPazz22 intranet.example.com jdoe\n"
    exit -2
fi

if [[ $(whoami) != "root" ]];
then
    echo -e "ERROR: This utility must be run as root (or sudo)."
    exit -1
fi

# [id] [storage] [distro] [version] [user] [password]

if [ ! -z "$1" ] ; then
    VM_ID="$1"
else
    echo -e "ERROR: [id] missing. (ex.: 101)\n"
    exit -1
fi
if [ ! -z "$2" ] ; then
    if pvesm status | grep -q "$2" ; then
        STORAGE_NAME="$2"
    else
        echo -e "ERROR: Storage device '"$2"' does not exist."
        exit -1
    fi
else
    echo -e "ERROR: [storage] missing. (ex.: SSD-01A)\n"
    exit -1
fi

if [ ! -z "$3" ] ; then
    CENTOS_VERSION="$3"
else
    echo -e "ERROR: [version] missing. (ex.: 7, 9-stream, etc)\n"
    exit -1
fi
if [ ! -z "$4" ] ; then
    STD_USER_NAME="$4"
else
    echo -e "ERROR: [user] missing. (ex.: sysadmin)\n"
    exit -1
fi
if [ ! -z "$5" ] ; then
    STD_USER_PASSWORD="$5"
else
    echo -e "ERROR: [password] missing. (ex.: P4zzw0rd!)\n"
    exit -1
fi
if [ ! -z "$6" ] ; then
    SEARCH_DOMAIN="$6"
else
    echo -e "ERROR: [searchdomain] missing. (ex.: intranet.example.com)\n"
    exit -1
fi
if [ ! -z "$7" ] ; then
    SSH_KEY_ID="$7"
else
    echo -e "ERROR: [sshkeyid] missing. (ex.: jdoe)\n"
    exit -1
fi

if [[ "${CENTOS_VERSION}" == "8-stream" ]] ; then
    IMAGE_FILE="CentOS-Stream-GenericCloud-8-latest.0.x86_64.qcow2"
    HASH_FILE="CHECKSUM"
else
    IMAGE_FILE="CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2"
    HASH_FILE="${IMAGE_FILE}.SHA256SUM"
fi

MEM_SIZE="1024"
CORES="1"
DISK_SIZE="20G"
SSH_KEYS="./keys"
IMAGE_URL="https://cloud.centos.org/centos/${CENTOS_VERSION}/x86_64/images/${IMAGE_FILE}"
HASH_URL="https://cloud.centos.org/centos/${CENTOS_VERSION}/x86_64/images/"



echo ""
echo "VM_ID................: $VM_ID"
echo "CENTOS_VERSION.......: $CENTOS_VERSION"
echo "STORAGE_NAME.........: $STORAGE_NAME"
echo "IMAGE_FILE...........: $IMAGE_FILE"
echo "IMAGE_URL............: $IMAGE_URL"
echo "HASH_URL.............: $HASH_URL"
echo "HASH_FILE............: $HASH_FILE"
echo "STD_USER_NAME........: $STD_USER_NAME"
echo "STD_USER_PASSWORD....: $STD_USER_PASSWORD"
echo "SEARCH_DOMAIN........: $SEARCH_DOMAIN"
echo "SSH_KEY_ID...........: $SSH_KEY_ID"
echo ""

function setStatus(){

    description=$1
    severity=$2

    logger "$Name $Version: [${severity}] $description"


    case "$severity" in
        s)
            echo -e "[${LightGreen}+${NC}] ${LightGreen}${description}${NC}"
        ;;
        f)
            echo -e "[${Red}-${NC}] ${LightRed}${description}${NC}"
        ;;
        q)
            echo -e "[${LightPurple}?${NC}] ${LightPurple}${description}${NC}"
        ;;
        *)
            echo -e "[${LightCyan}*${NC}] ${LightCyan}${description}${NC}"
        ;;
    esac

    [[ $WithVoice -eq 1 ]] && echo -e ${description} | espeak
}

function runCommand(){

    beforeText=$1
    afterText=$2
    commandToRun=$3

    setStatus "${beforeText}" "s"

    eval $commandToRun

    setStatus "$afterText" "s"

}

setStatus "STEP 1: Get CentOS Cloud image and SHA256 hash" "*"

HASHES_MATCH=-1
ATTEMPT=0

while [ $HASHES_MATCH -lt 1 ]
do

    ATTEMPT=$(($ATTEMPT+1))

    setStatus "Checking to see if '${IMAGE_FILE}-orig' has been downloaded (attempt: $ATTEMPT)..." "*"
    if [ ! -f ./${IMAGE_FILE}-orig ]; then
        setStatus " - File not found." "f"
        setStatus " - Downloading file from internet (${IMAGE_URL})..." "*"

        if wget ${IMAGE_URL} -v --output-document=${IMAGE_FILE}-orig ; then
            setStatus " - Complete." "s"
        else
            setStatus " - Download failed." "f"
            #exit -2
        fi
    else
        setStatus " - File found." "s"
        if [ "$HASHES_MATCH" -eq "0" ]; then
            setStatus " - SHA256 hashes do not match. File is invalid." "f"
            setStatus " - Downloading file from internet and overwriting invalid, local file (${IMAGE_URL})..." "*"

            if wget ${IMAGE_URL} -v --output-document=${IMAGE_FILE}-orig ; then
                setStatus " - Complete." "s"
            else
                setStatus " - Download failed." "f"
            fi
        fi
    fi

    setStatus "Generating SHA256 hash from the file on-disk..." "*"
    SHA256_HASH_ONDISK=`sha256sum ./${IMAGE_FILE}-orig | cut -d ' ' -f1`
    setStatus " - Done: $SHA256_HASH_ONDISK" "s"

    setStatus "Downloading SHA256 sums from CentOS (${HASH_URL}${HASH_FILE})..." "*"
    if wget -q -N ${HASH_URL}${HASH_FILE} --output-document=${IMAGE_FILE}.SHA256SUM ; then
        setStatus " - Extracting SHA256 hash from CentOS (${IMAGE_FILE}.SHA256SUM)..." "*"
        SHA256_HASH_FROMINET=`grep "SHA256 (${IMAGE_FILE}" ./${IMAGE_FILE}.SHA256SUM | cut -d '=' -f2 | xargs`
        setStatus " - Done: $SHA256_HASH_FROMINET" "s"
    else
        setStatus " - Download of SHA256 hashes failed." "f"
        exit -2
    fi

    setStatus "Comparing SHA256 hashes..." "*"
    if [[ "$SHA256_HASH_ONDISK" != "$SHA256_HASH_FROMINET" ]]; then
        HASHES_MATCH=0
        setStatus " - Hashes do NOT match. Retrying..." "f"
    else
        HASHES_MATCH=1
        setStatus " - Hashes match." "s"
    fi

    if [ $ATTEMPT -gt 3 ]; then
        setStatus "FATAL: Can't seem to download a valid image and confirm the \
            SHA256 hash after 3 attempts. Cannot continue." "f"
        exit -1
    fi

done

cp ./${IMAGE_FILE}-orig ./${IMAGE_FILE}

setStatus "STEP 1b: Purge existing VM template (${VM_ID}) if it already exists."
if qm destroy ${VM_ID} --purge ; then
    setStatus " - Successfully deleted." "s"
else
    setStatus " - No existing template found." "s"
fi

setStatus "STEP 1c: Configure VM template with software."
if virt-customize -a ./${IMAGE_FILE} --install epel-release,qemu-guest-agent,watchdog --selinux-relabel \
    --run-command "cat /dev/null > /etc/machine-id"; then
    setStatus " - Successfully installed." "s"
else
    setStatus " - Unable to install software into image file ./${IMAGE_FILE}." "s"
fi

setStatus "STEP 2: Create a virtual machine" "*"
if qm create ${VM_ID} --memory ${MEM_SIZE} --name centos-cloud-${CENTOS_VERSION} \
    --net0 virtio,bridge=vmbr0 --tags centos,centos-${CENTOS_VERSION},cloud-image \
    --cpu cputype=host --watchdog model=i6300esb,action=reset; then
    setStatus " - Success." "s"
    setStatus " - NOTE: CentOS 9 and later need the ProxMox CPU type to be 'host', else kernel panic."
else
    setStatus " - Error completing step." "f"
    exit -1
fi

setStatus "STEP 3: Import the disk into the proxmox storage, into '${STORAGE_NAME}' in this case."
if qm importdisk ${VM_ID} ./${IMAGE_FILE} ${STORAGE_NAME} ; then
    setStatus " - Success." "s"
else
    setStatus " - Error completing step." "f"
    exit -1
fi

setStatus "STEP 4: Add the new, imported disk to the VM."

# check storage type before trying to access this disk in the appropriate syntax
STORAGE_TYPE=$(pvesm status --storage ${STORAGE_NAME} | awk 'NR == 2 {print $2}')
if [ "$STORAGE_TYPE" = "dir" ]; then
  setStatus " - Storage type 'Directory' detected."
  IMPORTED_DISKFILE=${STORAGE_NAME}:${VM_ID}/vm-${VM_ID}-disk-0.raw
  rm ${IMPORTED_DISKFILE}
elif [ "$STORAGE_TYPE" = "lvm" ]; then
  setStatus " - Storage type 'LVM' detected."
  IMPORTED_DISKFILE=${STORAGE_NAME}:vm-${VM_ID}-disk-0
  lvremove ${IMPORTED_DISKFILE}
elif [ "$STORAGE_TYPE" = "lvmthin" ]; then
  setStatus " - Storage type 'LVM-Thin' detected."
  IMPORTED_DISKFILE=${STORAGE_NAME}:vm-${VM_ID}-disk-0
  lvremove ${IMPORTED_DISKFILE}
elif [ "$STORAGE_TYPE" = "rbd" ]; then
  setStatus " - Storage type 'RBD' detected."
  IMPORTED_DISKFILE=${STORAGE_NAME}:vm-${VM_ID}-disk-0
  rm ${IMPORTED_DISKFILE}
elif [ "$STORAGE_TYPE" = "zfspool" ]; then
  setStatus " - Storage type 'ZFS Pool' detected."
  IMPORTED_DISKFILE=${STORAGE_NAME}:vm-${VM_ID}-disk-0
  zfs destroy ${IMPORTED_DISKFILE}
else
  setStatus " - Storage type not detected. Defaulting to treating as Directory storage."
  IMPORTED_DISKFILE=${STORAGE_NAME}:${VM_ID}/vm-${VM_ID}-disk-0.raw
fi
sleep 1


if qm set ${VM_ID} --scsihw virtio-scsi-pci --scsi0 ${IMPORTED_DISKFILE} ; then
    setStatus " - Success." "s"
else
    setStatus " - Error completing step." "f"
    exit -1
fi

setStatus "STEP 5: Add a CD-ROM."
if qm set ${VM_ID} --ide2 ${STORAGE_NAME}:cloudinit ; then
    setStatus " - Success." "s"
else
    setStatus " - Error completing step." "f"
    exit -1
fi

setStatus "STEP 6: Specify the boot disk."
if qm set ${VM_ID} --boot c --bootdisk scsi0 ; then
    setStatus " - Success." "s"
else
    setStatus " - Error completing step." "f"
    exit -1
fi

# I don't think this is needed? Still evaluating.
setStatus "STEP 7: Add support for VNC and a serial console."
if qm set ${VM_ID} --serial0 socket --vga serial0 ; then
   setStatus " - Success." "s"
else
   setStatus " - Error completing step." "f"
   exit -1
fi

setStatus "STEP 8: Retrieve SSH keys from LaunchPad for: ${SSH_KEY_ID}..."
if wget https://launchpad.net/~${SSH_KEY_ID}/+sshkeys -O ./keys ; then
    setStatus " - Success." "s"
elif wget https://github.com/${SSH_KEY_ID}.keys -O ./keys ; then
    setStatus " - Success." "s"
else
    setStatus " - Error completing step." "f"
    exit -1
fi

setStatus "STEP 9: Set other template variables..."
if qm set ${VM_ID} --ciuser ${STD_USER_NAME} --cipassword ${STD_USER_PASSWORD} \
    --cores ${CORES} --searchdomain ${SEARCH_DOMAIN} --sshkeys ${SSH_KEYS} \
    --description "Virtual machine based on the CentOS '${CENTOS_VERSION}' Cloud \
    image. Last generated: `date`" --ipconfig0 ip=dhcp --onboot 1 --ostype l26 --agent 1 ; then
    setStatus " - Success." "s"
else
    setStatus " - Error completing step." "f"
    exit -1
fi

setStatus "STEP 10: Resize boot disk to ${DISK_SIZE}B"

ATTEMPT=0
while [ $ATTEMPT -lt 5 ];
do
    ATTEMPT=$(($ATTEMPT + 1))

    if qm resize ${VM_ID} scsi0 ${DISK_SIZE} ; then
        setStatus " - Success." "s"
        ATTEMPT=100
    else
        if [ $ATTEMPT -lt 5 ] ; then
            setStatus " - Error executing step. Retrying..." "f"
        else
            setStatus " - Error completing step." "f"
            exit -1
        fi
    fi
done
setStatus " - Refreshing view of drives, and waiting for I/O to catch up..."
qm rescan --vmid ${VM_ID}

setStatus "STEP 11: Convert VM to a template"
if qm template ${VM_ID} ; then
    setStatus " - Success." "s"
else
    setStatus " - Error completing step." "f"
    exit -1
fi

setStatus "Cleaning up..."
if rm ./keys ; then
    setStatus " - Success." "s"
else
    setStatus " - Error completing step." "f"
    exit -1
fi

echo "======================================================================"
echo "S U M M A R Y"
echo "======================================================================"
echo "New VM template based on CentOS '${CENTOS_VERSION}' was created as VM_ID"
echo "$VM_ID on ProxMox server `hostname`. It has $CORES CPU cores and ${MEM_SIZE}"
echo "of RAM. The primary '/' mount point has ${DISK_SIZE} of space. Login with:"
echo ""
echo "  User......: $STD_USER_NAME"
echo "  Password..: $STD_USER_PASSWORD"
echo ""
echo "======================================================================"
echo "T E M P L A T E  C O N F I G"
echo "======================================================================"
qm config ${VM_ID} | grep -v 'sshkeys\|description' | column -t -s' '
echo ""
echo "======================================================================"
echo "D I S K  S P A C E"
echo "======================================================================"
echo "Cloud images are using the following amount of space:"
echo ""
du -chs ./*.img ./*.qcow2
echo ""
echo "Available on the / mount point:"
TOTAL=`df -h | grep "/$" | xargs | cut -d ' ' -f2`
FREE=`df -h | grep "/$" | xargs | cut -d ' ' -f4`
USED=`df -h | grep "/$" | xargs | cut -d ' ' -f3`
USED_PCT=`df -h | grep "/$" | xargs | cut -d ' ' -f5`
echo -e "Total: Used: Avail: Used%\n$TOTAL $USED $FREE $USED_PCT" | column -t -s' '
