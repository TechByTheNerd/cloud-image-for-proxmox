# <img src="logo.png" height="25" /> Creating CentOS Cloud Images for ProxMox

If you haven't already, see the [README](../README.md) in the root of this repository. This is the CentOS-specific cloud image setup.

## Getting Started

In short, this is what you need to run this script:

```bash
sudo ./prox-cloud-template-add.sh [id] [storage] [version] [user] [password] [searchdomain] [launchpadid]
```
or as an example:
```bash
sudo ./prox-cloud-template-add.sh 4000 SSD-01A 9-stream sysadmin G00dPazz22 intranet.example.com jdoe
```

Below are what these values are:

<dl>
  <dt><code>id</code></dt>
  <dd>This is the ProxMox number ID you want to label this template. I'm using higher numbers and use this for metadata. For example an <code>id</code> of <code>282004</code> is ProxMox server 2, 8 is an arbitrary number for Ubuntu, and 2004 represents the <code>20.04 LTS</code> release. You can use whatever you want, but it needs to be an integer.</dd>

  <dt><code>storage</code></dt>
  <dd>This is the name of the ProxMox storage device where you want to store the template. This might be<code>Local-LVM</code>or any mounted storage you have available on the same ProxMox server.</dd>

  <dt><code>version</code></dt>
  <dd>This is the numeric version of the Ubuntu version (e.g. 8-stream, 9-stream, etc). <br><br><strong>NOTE</strong>: As of this writing only <code>8-stream</code> and <code>9-stream</code> are supported options for the <code>version</code> argument. This is based mostly on the directory structure of where the source files are, <a href="https://cloud.centos.org/centos/9-stream/x86_64/images/" target="_blank">here</a>.</dd>

  <dt><code>user</code></dt>
  <dd>This is the name of the non-root, default user who will have <code>sudo</code> privilege.</dd>

  <dt><code>password</code></dt>
  <dd>This is the password for <code>user</code>, in plain-text.</dd>

  <dt><code>searchdomain</code></dt>
  <dd>This is a network setting. When you search for a server name, if it can't be found, the network stack can add-on different DNS domain suffixes to try to find the server. For example you might know "server123", but it's fully-qualified-domain-name is "server123.lab.example.com". In this case, if you set this to "lab.example.com" it will add this onto DNS queries to help file machines that you try to access.</dd>

  <dt><code>launchpadid</code></dt>
  <dd>This is the userid of the account to lookup, to scrape the SSH public keys to add to the <code>~/.ssh/authorized_keys</code> file for <code>user</code>. This is a common/consistent place to store your public keys. Navigate to www.launchpad.net to create an account and upload the SSH keys from the various workstation(s) you might need to connect from.</dd>
</dl>


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
ProxMox / CentOS Cloud Init Image Creation Utility (PUCIICU) v1.0.0-alpha.10


VM_ID................: 608000
CENTOS_VERSION.......: 8-stream
STORAGE_NAME.........: HDD-06A
IMAGE_FILE...........: CentOS-Stream-GenericCloud-8-20220913.0.x86_64.qcow2
IMAGE_URL............: https://cloud.centos.org/centos/8-stream/x86_64/images/CentOS-Stream-GenericCloud-8-20220913.0.x86_64.qcow2
HASH_URL.............: https://cloud.centos.org/centos/8-stream/x86_64/images/
HASH_FILE............: CHECKSUM
STD_USER_NAME........: sysadmin
STD_USER_PASSWORD....: P4zzw0rd1!
SEARCH_DOMAIN........: lab.example.com
LAUNCHPAD_ID.........: jdoe

[*] STEP 1: Get CentOS Cloud image and SHA256 hash
[*] Checking to see if 'CentOS-Stream-GenericCloud-8-20220913.0.x86_64.qcow2-orig' has been downloaded (attempt: 1)...
[+]  - File found.
[*] Generating SHA256 hash from the file on-disk...
[+]  - Done: 8717251f8e4d2fe3e5032799caae89358c1ba68d65a16b5128a59ec6003aac1c
[*] Downloading SHA256 sums from CentOS (https://cloud.centos.org/centos/8-stream/x86_64/images/CHECKSUM)...
[*]  - Extracting SHA256 hash from CentOS (CHECKSUM)...
[+]  - Done: 8717251f8e4d2fe3e5032799caae89358c1ba68d65a16b5128a59ec6003aac1c
[*] Comparing SHA256 hashes...
[+]  - Hashes match.
[*] STEP 1b: Purge existing VM template (608000) if it already exists.
purging VM 608000 from related configurations..
[+]  - Successfully deleted.
[*] STEP 1c: Configure VM template with software.
[   0.0] Examining the guest ...
[   4.3] Setting a random seed
[   4.4] Setting the machine ID in /etc/machine-id
[   4.4] Installing packages: epel-release qemu-guest-agent
[  46.2] Running: cat /dev/null > /etc/machine-id
[  46.2] SELinux relabelling
[  47.0] Finishing off
[+]  - Successfully installed.
[*] STEP 2: Create a virtual machine
[+]  - Success.
[*]  - NOTE: CentOS 9 and later need the ProxMox CPU type to be 'host', else kernel panic.
[*] STEP 3: Import the disk into the proxmox storage, into 'HDD-06A' in this case.
importing disk './CentOS-Stream-GenericCloud-8-20220913.0.x86_64.qcow2' to VM 608000 ...
Formatting '/mnt/pve/HDD-06A/images/608000/vm-608000-disk-0.raw', fmt=raw size=10737418240 preallocation=off
transferred 0.0 B of 10.0 GiB (0.00%)
transferred 102.4 MiB of 10.0 GiB (1.00%)
...snip...
transferred 10.0 GiB of 10.0 GiB (99.66%)
transferred 10.0 GiB of 10.0 GiB (100.00%)
transferred 10.0 GiB of 10.0 GiB (100.00%)
Successfully imported disk as 'unused0:HDD-06A:608000/vm-608000-disk-0.raw'
[+]  - Success.
[*] STEP 4: Add the new, imported disk to the VM.
[*]  - Storage type 'Directory' detected.
rm: cannot remove 'HDD-06A:608000/vm-608000-disk-0.raw': No such file or directory
update VM 608000: -scsi0 HDD-06A:608000/vm-608000-disk-0.raw -scsihw virtio-scsi-pci
[+]  - Success.
[*] STEP 5: Add a CD-ROM.
update VM 608000: -ide2 HDD-06A:cloudinit
Formatting '/mnt/pve/HDD-06A/images/608000/vm-608000-cloudinit.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off preallocation=metadata compression_type=zlib size=4194304 lazy_refcounts=off refcount_bits=16
ide2: successfully created disk 'HDD-06A:608000/vm-608000-cloudinit.qcow2,media=cdrom'
generating cloud-init ISO
[+]  - Success.
[*] STEP 6: Specify the boot disk.
update VM 608000: -boot c -bootdisk scsi0
[+]  - Success.
[*] STEP 7: Add support for VNC and a serial console.
update VM 608000: -serial0 socket -vga serial0
[+]  - Success.
[*] STEP 8: Retrieve SSH keys from LaunchPad for: jdoe...
--2023-01-10 11:46:47--  https://launchpad.net/~jdoe/+sshkeys
Resolving launchpad.net (launchpad.net)... 185.125.189.222, 185.125.189.223, 2620:2d:4000:1001::8003, ...
Connecting to launchpad.net (launchpad.net)|185.125.189.222|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 3490 (3.4K) [text/plain]
Saving to: ‘./keys’

./keys                                          100%[======================================================================================================>]   3.41K  --.-KB/s    in 0s      

2023-01-10 11:46:47 (134 MB/s) - ‘./keys’ saved [3490/3490]

[+]  - Success.
[*] STEP 9: Set other template variables...
update VM 608000: -agent 1 -cipassword <hidden> -ciuser sysadmin -cores 4 -description Virtual machine based on the CentOS '8-stream' Cloud     image. Last generated: Tue 10 Jan 2023 11:46:47 AM EST -ipconfig0 ip=dhcp -onboot 1 -ostype l26 -searchdomain lab.example.com -sshkeys ssh-rsa%20AAA...snip...aaiLGDg%3D%3D%20robert%40desktop%0A
[+]  - Success.
[*] STEP 10: Resize boot disk to 120GB
command '/usr/bin/qemu-img resize -f raw /mnt/pve/HDD-06A/images/608000/vm-608000-disk-0.raw 128849018880' failed: got timeout
[-]  - Error executing step. Retrying...
[+]  - Success.
[*]  - Refreshing view of drives, and waiting for I/O to catch up...
rescan volumes...
VM 608000 (scsi0): size of disk 'HDD-06A:608000/vm-608000-disk-0.raw' updated from 10G to 120G
[*] STEP 11: Convert VM to a template
[+]  - Success.
[*] Cleaning up...
[+]  - Success.
======================================================================
S U M M A R Y
======================================================================
New VM template based on CentOS '8-stream' was created as VM_ID
608000 on ProxMox server pmvm6.lab.example.com. It has 4 CPU cores and 2048
of RAM. The primary '/' mount point has 120G of space. Login with:

  User......: sysadmin
  Password..: P4zzw0rd1!

======================================================================
T E M P L A T E  C O N F I G
======================================================================
agent:         1
boot:          c
bootdisk:      scsi0
cipassword:    **********
ciuser:        sysadmin
cores:         4
cpu:           cputype=host
ide2:          HDD-06A:608000/vm-608000-cloudinit.qcow2,media=cdrom
ipconfig0:     ip=dhcp
memory:        2048
meta:          creation-qemu=7.1.0,ctime=1673369195
name:          centos-cloud-8-stream
net0:          virtio=D6:3F:CC:A6:BF:69,bridge=vmbr0
onboot:        1
ostype:        l26
scsi0:         HDD-06A:608000/base-608000-disk-0.raw,size=120G
scsihw:        virtio-scsi-pci
searchdomain:  lab.example.com
serial0:       socket
smbios1:       uuid=71419d67-8238-4b5c-afe3-0fa3992c39d0
tags:          cloud-image,centos,centos-8-stream
template:      1
vga:           serial0
vmgenid:       a0c659de-194a-4fda-adda-b83293163bcd

======================================================================
D I S K  S P A C E
======================================================================
Cloud images are using the following amount of space:

753M    ./bionic-server-cloudimg-amd64.img
1.1G    ./focal-server-cloudimg-amd64.img
1.2G    ./jammy-server-cloudimg-amd64.img
498M    ./xenial-server-cloudimg-amd64-disk1.img
1.6G    ./CentOS-Stream-GenericCloud-8-20220913.0.x86_64.qcow2
991M    ./CentOS-Stream-GenericCloud-9-20230103.0.x86_64.qcow2
5.9G    total

Available on the / mount point:
Total:  Used:  Avail:  Used%
108G    15G    89G     15%
```

## Examples

Here's an example of how you could build (or rebuild, this script is idempotent) your CentOS 8 and 9 cloud images:

```bash
# This gets run from pmvm01 as root where some storage is mounted as HDD-01A:

# Set up a cloud template for CentOS 8 Stream
./prox-cloud-template-add-centos.sh 108000 HDD-01A 8-stream sysadmin P4zzw0rd1! lab.example.com jdoe

# Set up a cloud template for CentOS 9 Stream
./prox-cloud-template-add-centos.sh 109000 HDD-01A 9-stream sysadmin P4zzw0rd1! lab.example.com jdoe
```

The purpose of having a high VM ID (e.g. 108000 and 109000) is so that these templates stay organized at the end of the list of VM's on that particular ProxMox server. 

## More Information

I was initially inspired by this TechnoTim video:

> **[https://www.youtube.com/watch?v=shiIi38cJe4](https://www.youtube.com/watch?v=shiIi38cJe4)**

and blog post:

> **[https://docs.technotim.live/posts/cloud-init-cloud-image/](https://docs.technotim.live/posts/cloud-init-cloud-image/)**

I basically built-out a single script that does these things, and few other steps. This page from the ProxMox documentation was very helpful too:

> https://pve.proxmox.com/pve-docs/qm.1.html

As as the `virt-customize` command (you need to install `libguestfs-tools` first) which allows you to modify configuration of an offline VM disk:

> https://libguestfs.org/virt-customize.1.html