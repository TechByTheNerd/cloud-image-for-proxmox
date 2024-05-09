# <img src="logo.png" height="25" /> Creating AlmaLinux Cloud Images for ProxMox

If you haven't already, see the [README](../README.md) in the root of this repository. This is the AlmaLinux-specific cloud image setup.

## Getting Started

In short, this is what you need to run this script:

```bash
sudo ./prox-cloud-template-add.sh [id] [storage] [version] [user] [password] [searchdomain] [sshkeyid]
```
or as an example:
```bash
sudo ./prox-cloud-template-add.sh 4000 SSD-01A 9-stream sysadmin G00dPazz22 intranet.example.com jdoe
```

Below are what these values are:

- `id` This is the ProxMox number ID you want to label this template. I'm using higher numbers and use this for metadata. For example an `id` of `279000` is ProxMox server 2, 7 is an arbitrary number for AlmaLinux, and 9000 represents the `v9` release, without any minor version. You can use whatever you want, but it needs to be an integer.
- `storage` This is the name of the ProxMox storage device where you want to store the template. This might be `Local-LVM` or any mounted storage you have available on the same ProxMox server.
- `version` This is the numeric version of the AlmaLinux version (e.g. 8-stream, 9-stream, etc).
  - **NOTE**: As of this writing only `8` and `9` are supported options for the `version` argument. This is based mostly on the directory structure of where the source files are, [here](https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/).
- `user` This is the name of the non-root, default user who will have `sudo` privilege.
- `password` This is the password for `user`, in plain-text.
- `searchdomain` This is a network setting. When you search for a server name, if it can't be found, the network stack can add-on different DNS domain suffixes to try to find the server. For example you might know "server123", but it's fully-qualified-domain-name is "server123.lab.example.com". In this case, if you set this to "lab.example.com" it will add this onto DNS queries to help file machines that you try to access.
- `sshkeyid` This is the userid of the account to lookup, to scrape the SSH public keys to add to the `~/.ssh/authorized_keys` file for `user`. This is a common/consistent place to store your public keys. Or, this can be a file on the file system. So, there are three places where this script can pull down your SSH keys:
  - 1) **File System** - Point to a valid path that you have access to, in any tradition format (e.g. "~/ssh/authorized_keys", "keys.txt", "/home/user/keys", etc.)
  - 2) **LaunchPad** - Navigate to https://www.launchpad.net to create an account and upload the SSH keys from the various workstation(s) you might need to connect from. The download will be from: `https://launchpad.net/~[[sshkeyid]]`
  - 3) **GitHub** - Navigate to https://github.com/settings/keys and add your SSH keys. The download will be from: `https://github.com/[[sshkeyid]].keys`


## What does it do?

Below is a breakdown of what this script does, and some of the nuance:

### STEP 1: Get AlmaLinux Cloud image and SHA256 hash

This step checks to see if the [AlmaLinux Cloud Image](https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/) is downloaded yet. If it is, it downloads the SHA256 hashes, makes a hash for the local file and compares them. If the hashes don't match, the image is downloaded again.

Once the image is downloaded and the SHA256 hashes match, the script continues. If this fails more than 3 times, the script errors out.

### STEP 1b: Purge existing VM template (${VM_ID}) if it already exists.

If the existing VM-ID exists, it's deleted / purged from ProxMox. This makes this script idempotent. It can be run over-and-over.

### STEP 2: Create a virtual machine

Creates the skeleton of a new VM.

### STEP 3: Import the disk into the proxmox storage, into '${STORAGE_NAME}' in this case.

Import the raw disk into ProxMox.

### STEP 4: Add the new, imported disk to the VM.

This attaches the AlmaLinux Cloud image to the VM.

### STEP 5: Add a CD-ROM.

Adds a CD-ROM.

### STEP 6: Specify the boot disk.

Makes the AlmaLinux image bootable.

### STEP 7: Add support for VNC and a serial console.

Need to set up TTY so that the ProxMox web-based console works correctly.

### STEP 8: Retrieve SSH keys from LaunchPad...

Navigate to www.launchpad.net to get your SSH public keys for whichever workstations / servers need to be able to connect to machines that are cloned from this image.

### STEP 9: Set other template variables...

Configures all of the other details such as a description, core count, default username/password, etc.

### STEP 10: Resize boot disk to ${DISK_SIZE}B

The AlmaLinux Cloud Image is just a few gigabytes by default. This expands the `/` mount point, the main disk to 120GB.

### STEP 11: Convert VM to a template

Finally, we take this VM we've been creating and change it into a ProxMox Template. The script then does some clean-up and ultimate prints out a summary message of what was built. For example:

```text
ProxMox / AlmaLinux Cloud Init Image Creation Utility (PACIICU) v1.0.0-alpha.1


VM_ID................: 119000
ALMALINUX_VERSION....: 9
STORAGE_NAME.........: SSD-01A
IMAGE_FILE...........: AlmaLinux-9-GenericCloud-latest.x86_64.qcow2
IMAGE_URL............: https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2
HASH_URL.............: https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/
HASH_FILE............: CHECKSUM
STD_USER_NAME........: sysadmin
STD_USER_PASSWORD....: P4zzw0rd1!
SEARCH_DOMAIN........: lab.example.com
SSH_KEY_ID...........: jdoe

[*] STEP 1: Get AlmaLinux Cloud image and SHA256 hash
[*] Checking to see if 'AlmaLinux-9-GenericCloud-latest.x86_64.qcow2-orig' has been downloaded (attempt: 1)...
[+]  - File found.
[*] Generating SHA256 hash from the file on-disk...
[+]  - Done: 6bbd060c971fd827a544c7e5e991a7d9e44460a449d2d058a0bb1290dec5a114
[*] Downloading SHA256 sums from AlmaLinux (https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/CHECKSUM)...
[*]  - Extracting SHA256 hash from AlmaLinux (AlmaLinux-9-GenericCloud-latest.x86_64.qcow2.SHA256SUM)...
[+]  - Done: 6bbd060c971fd827a544c7e5e991a7d9e44460a449d2d058a0bb1290dec5a114
[*] Comparing SHA256 hashes...
[+]  - Hashes match.
[*] STEP 1b: Purge existing VM template (119000) if it already exists.
Configuration file 'nodes/pve1/qemu-server/119000.conf' does not exist
[+]  - No existing template found.
[*] STEP 1c: Configure VM template with software.
[   0.0] Examining the guest ...
[   6.5] Setting a random seed
[   6.5] Setting the machine ID in /etc/machine-id
[   6.5] Installing packages: epel-release qemu-guest-agent watchdog
[  17.6] Running: cat /dev/null > /etc/machine-id
[  17.6] SELinux relabelling
[  18.6] Finishing off
[+]  - Successfully installed.
[*] STEP 2: Create a virtual machine
[+]  - Success.
[*]  - NOTE: AlmaLinux 9 and later need the ProxMox CPU type to be 'host', else kernel panic.
[*] STEP 3: Import the disk into the proxmox storage, into 'SSD-01A' in this case.
importing disk './AlmaLinux-9-GenericCloud-latest.x86_64.qcow2' to VM 119000 ...
Formatting '/mnt/SSD-01A/images/119000/vm-119000-disk-0.raw', fmt=raw size=10737418240 preallocation=off
transferred 0.0 B of 10.0 GiB (0.00%)
transferred 112.6 MiB of 10.0 GiB (1.10%)
transferred 216.1 MiB of 10.0 GiB (2.11%)
...snip...
transferred 9.8 GiB of 10.0 GiB (98.27%)
transferred 9.9 GiB of 10.0 GiB (99.27%)
transferred 10.0 GiB of 10.0 GiB (100.00%)
transferred 10.0 GiB of 10.0 GiB (100.00%)
Successfully imported disk as 'unused0:SSD-01A:119000/vm-119000-disk-0.raw'
[+]  - Success.
[*] STEP 4: Add the new, imported disk to the VM.
[*]  - Storage type 'Directory' detected.
rm: cannot remove 'SSD-01A:119000/vm-119000-disk-0.raw': No such file or directory
update VM 119000: -scsi0 SSD-01A:119000/vm-119000-disk-0.raw -scsihw virtio-scsi-pci
[+]  - Success.
[*] STEP 5: Add a CD-ROM.
update VM 119000: -ide2 SSD-01A:cloudinit
Formatting '/mnt/SSD-01A/images/119000/vm-119000-cloudinit.qcow2', fmt=qcow2 cluster_size=65536 extended_l2=off preallocation=metadata compression_type=zlib size=4194304 lazy_refcounts=off refcount_bits=16
ide2: successfully created disk 'SSD-01A:119000/vm-119000-cloudinit.qcow2,media=cdrom'
generating cloud-init ISO
[+]  - Success.
[*] STEP 6: Specify the boot disk.
update VM 119000: -boot c -bootdisk scsi0
[+]  - Success.
[*] STEP 7: Add support for VNC and a serial console.
update VM 119000: -serial0 socket -vga serial0
[+]  - Success.
[*] STEP 8: Retrieve SSH keys from LaunchPad for: jdoe...
--2024-04-12 03:26:51--  https://launchpad.net/~jdoe/+sshkeys
Resolving launchpad.net (launchpad.net)... 185.125.189.223, 185.125.189.222, 2620:2d:4000:1009::f3, ...
Connecting to launchpad.net (launchpad.net)|185.125.189.223|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 4164 (4.1K) [text/plain]
Saving to: ‘./keys’

./keys                        100%[=================================================>]   4.07K  --.-KB/s    in 0s

2024-04-12 03:26:52 (42.4 MB/s) - ‘./keys’ saved [4164/4164]

[+]  - Success.
[*] STEP 9: Set other template variables...
update VM 119000: -agent 1 -cipassword <hidden> -ciuser sysadmin -cores 1 -description Virtual machine based on the AlmaLinux '9' Cloud     image. Last generated: Fri Apr 12 03:26:52 AM EDT 2024 -ipconfig0 ip=dhcp -onboot 1 -ostype l26 -searchdomain lab.example.com -sshkeys ssh-rsa%20AAAAB3N...snip...IJfb0hAl2qIZ7V9U979%20conan_the_deployer%40r3lab%0A
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
New VM template based on AlmaLinux '9' was created as VM_ID
119000 on ProxMox server pve1. It has 1 CPU cores and 1024
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
ide2:          SSD-01A:119000/vm-119000-cloudinit.qcow2,media=cdrom
ipconfig0:     ip=dhcp
memory:        1024
meta:          creation-qemu=8.1.5,ctime=1712906804
name:          almalinux-cloud-9
net0:          virtio=BC:24:11:C4:2D:B3,bridge=vmbr0
onboot:        1
ostype:        l26
scsi0:         SSD-01A:119000/base-119000-disk-0.raw,size=20G
scsihw:        virtio-scsi-pci
searchdomain:  lab.example.com
serial0:       socket
smbios1:       uuid=f37edeb2-2802-4ebb-957b-2662cd7f56e8
tags:          almalinux,almalinux-9,cloud-image
template:      1
vga:           serial0
vmgenid:       9ec84f6e-d891-47df-8a1d-63634a26278d
watchdog:      model=i6300esb,action=reset

======================================================================
D I S K  S P A C E
======================================================================
Cloud images are using the following amount of space:

du: cannot access './*.img': No such file or directory
731M    ./AlmaLinux-8-GenericCloud-latest.x86_64.qcow2
645M    ./AlmaLinux-9-GenericCloud-latest.x86_64.qcow2
1.4G    total

Available on the / mount point:
Total:  Used:  Avail:  Used%
94G     14G    77G     15%
```

## Examples

Here's an example of how you could build (or rebuild, this script is idempotent) your AlmaLinux 8 and 9 cloud images:

```bash
# This gets run from pmvm01 as root where some storage is mounted as HDD-01A:

# Set up a cloud template for AlmaLinux 8
./prox-cloud-template-add-almalinux.sh 118000 HDD-01A 8 sysadmin P4zzw0rd1! lab.example.com jdoe

# Set up a cloud template for AlmaLinux 9
./prox-cloud-template-add-almalinux.sh 119000 HDD-01A 9 sysadmin P4zzw0rd1! lab.example.com jdoe
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