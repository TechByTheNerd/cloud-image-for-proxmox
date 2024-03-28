# <img src="logo.png" height="25" />  Creating Ubuntu Cloud Images for ProxMox

If you haven't already, see the [README](../README.md) in the root of this repository. This is the Ubuntu-specific cloud image setup.

## Getting Started

In short, this is what you need to run this script:

```bash
sudo ./prox-cloud-template-add.sh [id] [storage] [distro] [version] [user] [password] [searchdomain] [sshkeyid]
```
or as an example:
```bash
sudo ./prox-cloud-template-add.sh 4000 SSD-01A focal 20.04 sysadmin G00dPazz22 intranet.example.com jdoe
```


Below are what these values are:

- `id` is the ProxMox number ID you want to label this template. I'm using higher numbers and use this for metadata. For example an `id` of `282004` is ProxMox server 2, 8 is an arbitrary number for Ubuntu, and 2004 represents the `20.04 LTS` release. You can use whatever you want, but it needs to be an integer.
- `storage` is the name of the ProxMox storage device where you want to store the template. This might be `Local-LVM` or any mounted storage you have available on the same ProxMox server.
- `distro` is the word name of the Ubuntu version, NOT the number version. See [this page](https://cloud-images.ubuntu.com/) as an example.
- `version` is the numeric version of the Ubuntu version (e.g. 18.04, 20.04, 22.04, etc).
- `user` is the name of the non-root, default user who will have `sudo` privilege.
- `password` is the password for `user`, in plain-text.
- `searchdomain` is a network setting. When you search for a server name, if it can't be found, the network stack can add-on different DNS domain suffixes to try to find the server. For example you might know "server123", but it's fully-qualified-domain-name is "server123.lab.example.com". In this case, if you set this to "lab.example.com" it will add this onto DNS queries to help file machines that you try to access.
- `sshkeyid` This is the userid of the account to lookup, to scrape the SSH public keys to add to the `~/.ssh/authorized_keys` file for `user`. This is a common/consistent place to store your public keys. There are two places where this script can pull down your SSH keys:
  - 1) **LaunchPad** - Navigate to https://www.launchpad.net to create an account and upload the SSH keys from the various workstation(s) you might need to connect from. The download will be from: `https://launchpad.net/~[[USERNAME]]`
  - 2) **GitHub** - Navigate to https://github.com/settings/keys and add your SSH keys. The download will be from: `https://github.com/[[USERNAME]].keys`


## What does it do?

Below is a breakdown of what this script does, and some of the nuance:

### STEP 1: Get Ubuntu Cloud image and SHA256 hash

This step checks to see if the [Ubuntu Cloud Image](https://cloud-images.ubuntu.com/) is downloaded yet. If it is, it downloads the SHA256 hashes, makes a hash for the local file and compares them. If the hashes don't match, the image is downloaded again.

Once the image is downloaded and the SHA256 hashes match, the script continues. If this fails more than 3 times, the script errors out.

### STEP 1b: Purge existing VM template (${VM_ID}) if it already exists.

If the existing VM-ID exists, it's deleted / purged from ProxMox. This makes this script idempotent. It can be run over-and-over.

### STEP 2: Create a virtual machine

Creates the skeleton of a new VM.

### STEP 3: Import the disk into the proxmox storage, into '${STORAGE_NAME}' in this case.

Import the raw disk into ProxMox.

### STEP 4: Add the new, imported disk to the VM.

This attaches the Ubuntu Cloud image to the VM.

### STEP 5: Add a CD-ROM.

Adds a CD-ROM.

### STEP 6: Specify the boot disk.

Makes the Ubuntu image bootable.

### STEP 7: Add support for VNC and a serial console.

Need to set up TTY so that the ProxMox web-based console works correctly.

### STEP 8: Retrieve SSH keys from LaunchPad...

Navigate to www.launchpad.net to get your SSH public keys for whichever workstations / servers need to be able to connect to machines that are cloned from this image.

### STEP 9: Set other template variables...

Configures all of the other details such as a description, core count, default username/password, etc.

### STEP 10: Resize boot disk to ${DISK_SIZE}B

The Ubuntu Cloud Image is just a few gigabytes by default. This expands the `/` mount point, the main disk to 120GB.

### STEP 11: Convert VM to a template

Finally, we take this VM we've been creating and change it into a ProxMox Template. The script then does some clean-up and ultimate prints out a summary message of what was built. For example:

```text
ProxMox / Ubuntu Cloud Init Image Creation Utility (PUCIICU) v1.0.0-alpha.1


VM_ID................: 181804
UBUNTU_DISTRO........: focal
UBUNTU_VERSION.......: 20.04
STORAGE_NAME.........: SSD-01A
IMAGE_FILE...........: focal-server-cloudimg-amd64.img
IMAGE_URL............: https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
HASH_URL.............: https://cloud-images.ubuntu.com/focal/current/SHA256SUMS
HASH_FILE............: focal_SHA256SUMS
STD_USER_NAME........: sysadmin
STD_USER_PASSWORD....: P4zzw0rd123!
SEARCH_DOMAIN........: lab.example.com
LAUNCHPAD_ID.........: jdoe

[*] STEP 1: Get Ubuntu Cloud image and SHA256 hash
[*] Checking to see if 'focal-server-cloudimg-amd64.img' has been downloaded (attempt: 1)...
[+]  - File found.
[*] Generating SHA256 hash from the file on-disk...
[+]  - Done: 1df09816277273d37f0acbabbbc41c0713e0b4c3cd209902dddce04decbb3969
[*] Downloading SHA256 sums from Ubuntu (https://cloud-images.ubuntu.com/focal/current/SHA256SUMS)...
[*]  - Extracting SHA256 hash from Ubuntu (focal_SHA256SUMS)...
[+]  - Done: 1df09816277273d37f0acbabbbc41c0713e0b4c3cd209902dddce04decbb3969
[*] Comparing SHA256 hashes...
[+]  - Hashes match.
[*] STEP 1b: Purge existing VM template (181804) if it already exists.
purging VM 181804 from related configurations..
[+]  - Successfully deleted.
[*] STEP 2: Create a virtual machine
[+]  - Success.
[*] STEP 3: Import the disk into the proxmox storage, into 'SSD-01A' in this case.
importing disk './focal-server-cloudimg-amd64.img' to VM 181804 ...
Formatting '/mnt/pve/SSD-01A/images/181804/vm-181804-disk-0.raw', fmt=raw size=2361393152 preallocation=off
transferred 0.0 B of 2.2 GiB (0.00%)
transferred 22.5 MiB of 2.2 GiB (1.00%)
transferred 45.0 MiB of 2.2 GiB (2.00%)
 --- SNIP ---
transferred 2.2 GiB of 2.2 GiB (99.84%)
transferred 2.2 GiB of 2.2 GiB (100.00%)
transferred 2.2 GiB of 2.2 GiB (100.00%)
Successfully imported disk as 'unused0:SSD-01A:181804/vm-181804-disk-0.raw'
[+]  - Success.
[*] STEP 4: Add the new, imported disk to the VM.
rm: cannot remove 'SSD-01A:181804/vm-181804-disk-0.raw': No such file or directory
update VM 181804: -scsi0 SSD-01A:181804/vm-181804-disk-0.raw -scsihw virtio-scsi-pci
[+]  - Success.
[*] STEP 5: Add a CD-ROM.
update VM 181804: -ide2 SSD-01A:cloudinit
Formatting '/mnt/pve/SSD-01A/images/181804/vm-181804-cloudinit.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off preallocation=metadata compression_type=zlib size=4194304 lazy_refcounts=off refcount_bits=16
ide2: successfully created disk 'SSD-01A:181804/vm-181804-cloudinit.qcow2,media=cdrom'
[+]  - Success.
[*] STEP 6: Specify the boot disk.
update VM 181804: -boot c -bootdisk scsi0
[+]  - Success.
[*] STEP 7: Add support for VNC and a serial console.
update VM 181804: -serial0 socket -vga serial0
[+]  - Success.
[*] STEP 8: Retrieve SSH keys from LaunchPad...
--2022-05-17 00:17:10--  https://launchpad.net/~jdoe/+sshkeys
Resolving launchpad.net (launchpad.net)... 185.125.189.222, 185.125.189.223, 2620:2d:4000:1001::8004, ...
Connecting to launchpad.net (launchpad.net)|185.125.189.222|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 2650 (2.6K) [text/plain]
Saving to: ‘./keys’

./keys                                 100%[============================================================================>]   2.59K  --.-KB/s    in 0.007s

2022-05-17 00:17:11 (350 KB/s) - ‘./keys’ saved [2650/2650]

[+]  - Success.
[*] STEP 9: Set other template variables...
update VM 181804: -agent 1 -cipassword <hidden> -ciuser sysadmin -cores 4 -description Virtual machine based on the Ubuntu 'focal' Cloud image. -ipconfig0 ip=dhcp -onboot 1 -ostype l26 -searchdomain lab.example.com -sshkeys ssh-rsa%20AAAA---SNIP---%20jdoe%40computername
[+]  - Success.
[*] STEP 10: Resize boot disk to 120GB
command '/usr/bin/qemu-img resize -f raw /mnt/pve/SSD-01A/images/181804/vm-181804-disk-0.raw 128849018880' failed: got timeout
[-]  - Error executing step. Retrying...
[+]  - Success.
[*]  - Refreshing view of drives, and waiting for I/O to catch up...
rescan volumes...
VM 181804 (scsi0): size of disk 'SSD-01A:181804/vm-181804-disk-0.raw' updated from 2252M to 120G
[*] STEP 11: Convert VM to a template
[+]  - Success.
[*] Cleaning up...
[+]  - Success.
======================================================================
S U M M A R Y
======================================================================
New VM template based on Ubuntu 'focal' was created as VM_ID
181804 on ProxMox server pmvm1.lab.example.com. It has 4 CPU cores and 2048
of RAM. The primary '/' mount point has 120G of space. Login with:

  User......: sysadmin
  Password..: P4zzw0rd123!

======================================================================
T E M P L A T E  C O N F I G
======================================================================
agent:    1
balloon:  0
boot:     order=scsi0;ide2;net0
cores:    4
ide2:     cdrom,media=cdrom
memory:   2048
meta:     creation-qemu=6.2.0,ctime=1652450630
name:     nameserver1.lab.example.com
net0:     virtio=CA:28:20:BD:FE:00,bridge=vmbr0,firewall=1
numa:     0
onboot:   1
ostype:   l26
scsi0:    SSD-01A:100/vm-100-disk-0.raw,size=120G,ssd=1
scsihw:   virtio-scsi-pci
smbios1:  uuid=e56c7475-7f8b-4b04-941a-e65d740ea782
sockets:  1
vmgenid:  86fc3d15-673f-42c3-846c-e35f06c63aa6

======================================================================
D I S K  S P A C E
======================================================================
Ubuntu cloud images are using the following amount of space:

370M    ./bionic-server-cloudimg-amd64.img
568M    ./focal-server-cloudimg-amd64.img
597M    ./jammy-server-cloudimg-amd64.img
1.5G    total

Available on the / mount point:
Total:  Used:  Avail:  Used%
110G    47G    58G     45%
```

## Examples

I have 4 proxmox servers. here's what I ran (with some details changed) to set up templates for Ubuntu 18.04 LTS, 20.04 LTS, and 22.04 LTS:

```bash
# This gets run from pmvm01 as root where my SSD storage is mounted as SSD-01A:
./prox-cloud-template-add-ubuntu.sh 181804 SSD-01A bionic 18.04 sysadmin p4zzw0rd123! lab.example.com jdoe
./prox-cloud-template-add-ubuntu.sh 182004 SSD-01A focal 20.04 sysadmin p4zzw0rd123! lab.example.com jdoe
./prox-cloud-template-add-ubuntu.sh 182204 SSD-01A jammy 22.04 sysadmin p4zzw0rd123! lab.example.com jdoe
```
```bash
# This gets run from pmvm02 as root where my SSD storage is mounted as SSD-02A:
./prox-cloud-template-add-ubuntu.sh 281804 SSD-02A bionic 18.04 sysadmin p4zzw0rd123! lab.example.com jdoe
./prox-cloud-template-add-ubuntu.sh 282004 SSD-02A focal 20.04 sysadmin p4zzw0rd123! lab.example.com jdoe
./prox-cloud-template-add-ubuntu.sh 282204 SSD-02A jammy 22.04 sysadmin p4zzw0rd123! lab.example.com jdoe
```
```bash
# This gets run from pmvm03 as root where my SSD storage is mounted as SSD-03A:
./prox-cloud-template-add-ubuntu.sh 381804 SSD-03A bionic 18.04 sysadmin p4zzw0rd123! lab.example.com jdoe
./prox-cloud-template-add-ubuntu.sh 382004 SSD-03A focal 20.04 sysadmin p4zzw0rd123! lab.example.com jdoe
./prox-cloud-template-add-ubuntu.sh 382204 SSD-03A jammy 22.04 sysadmin p4zzw0rd123! lab.example.com jdoe
```
```bash
# This gets run from pmvm04 as root where my SSD storage is mounted as SSD-04A:
./prox-cloud-template-add-ubuntu.sh 481804 SSD-04A bionic 18.04 sysadmin p4zzw0rd123! lab.example.com jdoe
./prox-cloud-template-add-ubuntu.sh 482004 SSD-04A focal 20.04 sysadmin p4zzw0rd123! lab.example.com jdoe
./prox-cloud-template-add-ubuntu.sh 482204 SSD-04A jammy 22.04 sysadmin p4zzw0rd123! lab.example.com jdoe
```

## More Information

I was initially inspired by this TechnoTim video:

> **[https://www.youtube.com/watch?v=shiIi38cJe4](https://www.youtube.com/watch?v=shiIi38cJe4)**

and blog post:

> **[https://docs.technotim.live/posts/cloud-init-cloud-image/](https://docs.technotim.live/posts/cloud-init-cloud-image/)**

I basically built-out a single script that does these things, and few other steps. This page from the ProxMox documentation was very helpful too:

> https://pve.proxmox.com/pve-docs/qm.1.html

As was the `virt-customize` command (you need to install `libguestfs-tools` first) which allows you to modify configuration of an offline VM disk:

> https://libguestfs.org/virt-customize.1.html