# <img src="logo.png" height="25" />  Creating Debian Cloud Images for ProxMox

If you haven't already, see the [README](../README.md) in the root of this repository. This is the Debian-specific cloud image setup.

## Getting Started

In short, this is what you need to run this script:

```bash
sudo ./prox-cloud-template-add-debian.sh [id] [storage] [distro] [version] [user] [password] [searchdomain] [sshkeyid]
```
or as an example:
```bash
sudo ./prox-cloud-template-add-debian.sh 4000 SSD-01A Bullseye 11 sysadmin G00dPazz22 intranet.example.com jdoe
```


Below are what these values are:

- `id` is the ProxMox number ID you want to label this template. I'm using higher numbers and use this for metadata. For example an `id` of `321000` is ProxMox server 3, 2 is an arbitrary number for Debian, and 1000 represents the `v10` release, with no minor version. You can use whatever you want, but it needs to be an integer.
- `storage` is the name of the ProxMox storage device where you want to store the template. This might be `Local-LVM` or any mounted storage you have available on the same ProxMox server.
- `distro` is the word name of the Debian version, NOT the number version. See [this page](https://cloud.debian.org/images/cloud/buster/latest/) as an example (e.g. "Buster", "Bullseye", etc).
- `version` is the numeric version of the Debian version (e.g. 10, 11, etc).
- `user` is the name of the non-root, default user who will have `sudo` privilege.
- `password` is the password for `user`, in plain-text.
- `searchdomain` is a network setting. When you search for a server name, if it can't be found, the network stack can add-on different DNS domain suffixes to try to find the server. For example you might know "server123", but it's fully-qualified-domain-name is "server123.lab.example.com". In this case, if you set this to "lab.example.com" it will add this onto DNS queries to help file machines that you try to access.
- `sshkeyid` This is the userid of the account to lookup, to scrape the SSH public keys to add to the `~/.ssh/authorized_keys` file for `user`. This is a common/consistent place to store your public keys. There are two places where this script can pull down your SSH keys:
  - 1) **LaunchPad** - Navigate to https://www.launchpad.net to create an account and upload the SSH keys from the various workstation(s) you might need to connect from. The download will be from: `https://launchpad.net/~[[sshkeyid]]`
  - 2) **GitHub** - Navigate to https://github.com/settings/keys and add your SSH keys. The download will be from: `https://github.com/[[sshkeyid]].keys`


## What does it do?

Below is a breakdown of what this script does, and some of the nuance:

### STEP 1: Get Debian Cloud image and SHA256 hash

This step checks to see if the [Debian Cloud Image](https://cloud.debian.org/images/cloud/) is downloaded yet. If it is, it downloads the SHA512 hashes, makes a hash for the local file and compares them. If the hashes don't match, the image is downloaded again.

Once the image is downloaded and the SHA512 hashes match, the script continues. If this fails more than 3 times, the script errors out.

### STEP 1b: Purge existing VM template (${VM_ID}) if it already exists.

If the existing VM-ID exists, it's deleted / purged from ProxMox. This makes this script idempotent. It can be run over-and-over.

### STEP 2: Create a virtual machine

Creates the skeleton of a new VM.

### STEP 3: Import the disk into the proxmox storage, into '${STORAGE_NAME}' in this case.

Import the raw disk into ProxMox.

### STEP 4: Add the new, imported disk to the VM.

This attaches the Debian Cloud image to the VM.

### STEP 5: Add a CD-ROM.

Adds a CD-ROM.

### STEP 6: Specify the boot disk.

Makes the Debian image bootable.

### STEP 7: Add support for VNC and a serial console.

Need to set up TTY so that the ProxMox web-based console works correctly.

### STEP 8: Retrieve SSH keys from LaunchPad...

Navigate to www.launchpad.net to get your SSH public keys for whichever workstations / servers need to be able to connect to machines that are cloned from this image.

### STEP 9: Set other template variables...

Configures all of the other details such as a description, core count, default username/password, etc.

### STEP 10: Resize boot disk to ${DISK_SIZE}B

The Debian Cloud Image is just a few gigabytes by default. This expands the `/` mount point, the main disk to 120GB.

### STEP 11: Convert VM to a template

Finally, we take this VM we've been creating and change it into a ProxMox Template. The script then does some clean-up and ultimate prints out a summary message of what was built. For example:

```text

TBD

```

## Examples

If you have two proxmox servers, you could run something like this to set up templates for Debian Buster 10 and Bullseye 11:

```bash
# This gets run from pmvm01 as root where my SSD storage is mounted as SSD-01A:
./prox-cloud-template-add-debian.sh 121000 SSD-01A Buster 10 sysadmin P4zzw0rd123! lab.example.com jdoe
./prox-cloud-template-add-debian.sh 121100 SSD-01A Bullseye 11 sysadmin P4zzw0rd123! lab.example.com jdoe
```
```bash
# This gets run from pmvm02 as root where my SSD storage is mounted as SSD-02A:
./prox-cloud-template-add-debian.sh 221000 SSD-02A Buster 10 sysadmin P4zzw0rd123! lab.example.com jdoe
./prox-cloud-template-add-debian.sh 221100 SSD-02A Bullseye 11 sysadmin P4zzw0rd123! lab.example.com jdoe
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