# <img src="logo.png" height="25" /> Creating Rocky Linux Cloud Images for ProxMox

If you haven't already, see the [README](../README.md) in the root of this repository. This is the Rocky Linux-specific cloud image setup.

## Getting Started

In short, this is what you need to run this script:

```bash
sudo ./prox-cloud-template-add.sh [id] [storage] [version] [user] [password] [searchdomain] [sshkeyid]
```
or as an example:
```bash
sudo ./prox-cloud-template-add.sh 4000 SSD-01A 9 sysadmin G00dPazz22 intranet.example.com jdoe
```

Below are what these values are:

- `id` This is the ProxMox number ID you want to label this template. I'm using higher numbers and use this for metadata. For example an `id` of `279000` is ProxMox server 2, 7 is an arbitrary number for Rocky Linux, and 9000 represents the `v9` release, without any minor version. You can use whatever you want, but it needs to be an integer.
- `storage` This is the name of the ProxMox storage device where you want to store the template. This might be `Local-LVM` or any mounted storage you have available on the same ProxMox server.
- `version` This is the numeric version of the Rocky Linux version (e.g. 8-stream, 9-stream, etc).
  - **NOTE**: As of this writing only `8` and `9` are supported options for the `version` argument. This is based mostly on the directory structure of where the source files are, [here](https://rockylinux.org/alternative-images).
- `user` This is the name of the non-root, default user who will have `sudo` privilege.
- `password` This is the password for `user`, in plain-text.
- `searchdomain` This is a network setting. When you search for a server name, if it can't be found, the network stack can add-on different DNS domain suffixes to try to find the server. For example you might know "server123", but it's fully-qualified-domain-name is "server123.lab.example.com". In this case, if you set this to "lab.example.com" it will add this onto DNS queries to help file machines that you try to access.
- `sshkeyid` This is the userid of the account to lookup, to scrape the SSH public keys to add to the `~/.ssh/authorized_keys` file for `user`. This is a common/consistent place to store your public keys. Or, this can be a file on the file system. So, there are three places where this script can pull down your SSH keys:
  - 1) **File System** - Point to a valid path that you have access to, in any tradition format (e.g. "~/ssh/authorized_keys", "keys.txt", "/home/user/keys", etc.)
  - 2) **LaunchPad** - Navigate to https://www.launchpad.net to create an account and upload the SSH keys from the various workstation(s) you might need to connect from. The download will be from: `https://launchpad.net/~[[sshkeyid]]`
  - 3) **GitHub** - Navigate to https://github.com/settings/keys and add your SSH keys. The download will be from: `https://github.com/[[sshkeyid]].keys`


## What does it do?

Below is a breakdown of what this script does, and some of the nuance:

### STEP 1: Get Rocky Linux Cloud image and SHA256 hash

This step checks to see if the [Rocky Linux Cloud Image](https://rockylinux.org/alternative-images) is downloaded yet. If it is, it downloads the SHA256 hashes, makes a hash for the local file and compares them. If the hashes don't match, the image is downloaded again.

Once the image is downloaded and the SHA256 hashes match, the script continues. If this fails more than 3 times, the script errors out.

### STEP 1b: Purge existing VM template (${VM_ID}) if it already exists.

If the existing VM-ID exists, it's deleted / purged from ProxMox. This makes this script idempotent. It can be run over-and-over.

### STEP 2: Create a virtual machine

Creates the skeleton of a new VM.

### STEP 3: Import the disk into the proxmox storage, into '${STORAGE_NAME}' in this case.

Import the raw disk into ProxMox.

### STEP 4: Add the new, imported disk to the VM.

This attaches the Rocky Linux Cloud image to the VM.

### STEP 5: Add a CD-ROM.

Adds a CD-ROM.

### STEP 6: Specify the boot disk.

Makes the Rocky Linux image bootable.

### STEP 7: Add support for VNC and a serial console.

Need to set up TTY so that the ProxMox web-based console works correctly.

### STEP 8: Retrieve SSH keys from LaunchPad...

Navigate to www.launchpad.net to get your SSH public keys for whichever workstations / servers need to be able to connect to machines that are cloned from this image.

### STEP 9: Set other template variables...

Configures all of the other details such as a description, core count, default username/password, etc.

### STEP 10: Resize boot disk to ${DISK_SIZE}B

The Rocky Linux Cloud Image is just a few gigabytes by default. This expands the `/` mount point, the main disk to 120GB.

### STEP 11: Convert VM to a template

Finally, we take this VM we've been creating and change it into a ProxMox Template. The script then does some clean-up and ultimate prints out a summary message of what was built. For example:

```text
ProxMox / Rocky Linux Cloud Init Image Creation Utility (PRLCIICU) v1.0.0-alpha.1


VM_ID................: 129000
ROCKYLINUX_VERSION...: 9
STORAGE_NAME.........: SSD-01A
IMAGE_FILE...........: Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
IMAGE_URL............: https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
HASH_URL.............: https://dl.rockylinux.org/pub/rocky/9/images/x86_64/
HASH_FILE............: CHECKSUM
STD_USER_NAME........: sysadmin
STD_USER_PASSWORD....: P4zzw0rd1!
SEARCH_DOMAIN........: lab.example.com
SSH_KEY_ID...........: jdoe

[*] STEP 1: Get Rocky Linux Cloud image and SHA256 hash
[*] Checking to see if 'Rocky-9-GenericCloud-Base.latest.x86_64.qcow2-orig' has been downloaded (attempt: 1)...
[+]  - File found.
[*] Generating SHA256 hash from the file on-disk...
[+]  - Done: 7713278c37f29b0341b0a841ca3ec5c3724df86b4d97e7ee4a2a85def9b2e651
[*] Downloading SHA256 sums from Rocky Linux (https://dl.rockylinux.org/pub/rocky/9/images/x86_64/CHECKSUM)...
[*]  - Extracting SHA256 hash from Rocky Linux (Rocky-9-GenericCloud-Base.latest.x86_64.qcow2.SHA256SUM)...
[+]  - Done: 7713278c37f29b0341b0a841ca3ec5c3724df86b4d97e7ee4a2a85def9b2e651
[*] Comparing SHA256 hashes...
[+]  - Hashes match.
[*] STEP 1b: Purge existing VM template (129000) if it already exists.
purging VM 129000 from related configurations..
[+]  - Successfully deleted.
[*] STEP 1c: Configure VM template with software.
[   0.0] Examining the guest ...
[   6.6] Setting a random seed
virt-customize: warning: random seed could not be set for this type of
guest
[   6.6] Setting the machine ID in /etc/machine-id
[   6.6] Installing packages: epel-release qemu-guest-agent watchdog
[  15.8] Running: cat /dev/null > /etc/machine-id
[  15.9] SELinux relabelling
[  16.9] Finishing off
[+]  - Successfully installed.
[*] STEP 2: Create a virtual machine
[+]  - Success.
[*]  - NOTE: Rocky Linux 9 and later need the ProxMox CPU type to be 'host', else kernel panic.
[*] STEP 3: Import the disk into the proxmox storage, into 'SSD-01A' in this case.
importing disk './Rocky-9-GenericCloud-Base.latest.x86_64.qcow2' to VM 129000 ...
Formatting '/mnt/SSD-01A/images/129000/vm-129000-disk-0.raw', fmt=raw size=10737418240 preallocation=off
transferred 0.0 B of 10.0 GiB (0.00%)
transferred 102.4 MiB of 10.0 GiB (1.00%)
transferred 215.0 MiB of 10.0 GiB (2.10%)
...snip...
transferred 10.0 GiB of 10.0 GiB (99.78%)
transferred 10.0 GiB of 10.0 GiB (100.00%)
transferred 10.0 GiB of 10.0 GiB (100.00%)
Successfully imported disk as 'unused0:SSD-01A:129000/vm-129000-disk-0.raw'
[+]  - Success.
[*] STEP 4: Add the new, imported disk to the VM.
[*]  - Storage type 'Directory' detected.
rm: cannot remove 'SSD-01A:129000/vm-129000-disk-0.raw': No such file or directory
update VM 129000: -scsi0 SSD-01A:129000/vm-129000-disk-0.raw -scsihw virtio-scsi-pci
[+]  - Success.
[*] STEP 5: Add a CD-ROM.
update VM 129000: -ide2 SSD-01A:cloudinit
Formatting '/mnt/SSD-01A/images/129000/vm-129000-cloudinit.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off preallocation=metadata compression_type=zlib size=4194304 lazy_refcounts=off refcount_bits=16
ide2: successfully created disk 'SSD-01A:129000/vm-129000-cloudinit.qcow2,media=cdrom'
generating cloud-init ISO
[+]  - Success.
[*] STEP 6: Specify the boot disk.
update VM 129000: -boot c -bootdisk scsi0
[+]  - Success.
[*] STEP 7: Add support for VNC and a serial console.
update VM 129000: -serial0 socket -vga serial0
[+]  - Success.
[*] STEP 8: Retrieve SSH keys from LaunchPad for: jdoe...
--2024-04-12 04:36:55--  https://launchpad.net/~jdoe/+sshkeys
Resolving launchpad.net (launchpad.net)... 185.125.189.222, 185.125.189.223, 2620:2d:4000:1009::3ba, ...
Connecting to launchpad.net (launchpad.net)|185.125.189.222|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 4164 (4.1K) [text/plain]
Saving to: ‘./keys’

./keys                                         100%[====================================================================================================>]   4.07K  --.-KB/s    in 0s

2024-04-12 04:36:55 (79.0 MB/s) - ‘./keys’ saved [4164/4164]

[+]  - Success.
[*] STEP 9: Set other template variables...
update VM 129000: -agent 1 -cipassword <hidden> -ciuser sysadmin -cores 1 -description Virtual machine based on the Rocky Linux '9' Cloud     image. Last generated: Fri Apr 12 04:36:55 AM EDT 2024 -ipconfig0 ip=dhcp -onboot 1 -ostype l26 -searchdomain lab.example.com
[+]  - Success.
[*] STEP 10: Resize boot disk to 20GB
Image resized.
[+]  - Success.
[*]  - Refreshing view of drives, and waiting for I/O to catch up...
rescan volumes...
[*] STEP 11: Convert VM to a template
[+]  - Success.
[*] Cleaning up...
[+]  - Success.
======================================================================
S U M M A R Y
======================================================================
New VM template based on Rocky Linux '9' was created as VM_ID
129000 on ProxMox server pve1. It has 1 CPU cores and 1024
of RAM. The primary '/' mount point has 20G of space. Login with:

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
cores:         1
cpu:           cputype=host
ide2:          SSD-01A:129000/vm-129000-cloudinit.qcow2,media=cdrom
ipconfig0:     ip=dhcp
memory:        1024
meta:          creation-qemu=8.1.5,ctime=1712911007
name:          rockylinux-cloud-9
net0:          virtio=BC:24:11:0F:6B:10,bridge=vmbr0
onboot:        1
ostype:        l26
scsi0:         SSD-01A:129000/base-129000-disk-0.raw,size=20G
scsihw:        virtio-scsi-pci
searchdomain:  lab.example.com
serial0:       socket
smbios1:       uuid=62c3a889-0e05-421f-82f5-fb3c709de860
tags:          rockylinux,rockylinux-9,cloud-image
template:      1
vga:           serial0
vmgenid:       894be608-2886-4472-ab2f-c2ee15f5b566
watchdog:      model=i6300esb,action=reset

======================================================================
D I S K  S P A C E
======================================================================
Cloud images are using the following amount of space:

du: cannot access './*.img': No such file or directory
1.9G    ./Rocky-8-GenericCloud-Base.latest.x86_64.qcow2
1.1G    ./Rocky-9-GenericCloud-Base.latest.x86_64.qcow2
3.0G    total

Available on the / mount point:
Total:  Used:  Avail:  Used%
94G     19G    71G     22%
```

## Examples

Here's an example of how you could build (or rebuild, this script is idempotent) your Rocky Linux 8 and 9 cloud images:

```bash
# This gets run from pmvm01 as root where some storage is mounted as HDD-01A:

# Set up a cloud template for Rocky Linux 8
./prox-cloud-template-add-almalinux.sh 128000 HDD-01A 8 sysadmin P4zzw0rd1! lab.example.com jdoe

# Set up a cloud template for Rocky Linux 9
./prox-cloud-template-add-almalinux.sh 129000 HDD-01A 9 sysadmin P4zzw0rd1! lab.example.com jdoe
```

The purpose of having a high VM ID (e.g. 128000 and 129000) is so that these templates stay organized at the end of the list of VM's on that particular ProxMox server. 

## More Information

I was initially inspired by this TechnoTim video:

> **[https://www.youtube.com/watch?v=shiIi38cJe4](https://www.youtube.com/watch?v=shiIi38cJe4)**

and blog post:

> **[https://docs.technotim.live/posts/cloud-init-cloud-image/](https://docs.technotim.live/posts/cloud-init-cloud-image/)**

I basically built-out a single script that does these things, and few other steps. This page from the ProxMox documentation was very helpful too:

> https://pve.proxmox.com/pve-docs/qm.1.html

As as the `virt-customize` command (you need to install `libguestfs-tools` first) which allows you to modify configuration of an offline VM disk:

> https://libguestfs.org/virt-customize.1.html