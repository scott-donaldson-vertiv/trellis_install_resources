# Trellis™ Enterprise - Supplemental Kickstarts for RHEL/CentOS

## Introduction

These kickstarts are provided for Trellis™ Enterprise & Trellis™ Intelligence Engine on Redhat Enterprise Linux, CentOS & Oracle Enterprise Linux.

The collections are separated into baseline engineering samples and alternative, security hardened and/or optimized installations, this can include additional packages and configuration for virtual machine guests and variations to support different hypervisors.

* Linux® KVM
* Citrix® Hypervisor / Citrix® XenServer
* XCP-NG
* AWS EC2 < Gen5 (XenServer)
* AWS EC2 Gen5+ (Linux® KVM)
* Microsoft® Hyper-V
* VMware® ESXi

### Versions
| Release   | Release Date      | Notes             | Bugs Fixed    |
|-----------|-------------------|-------------------|---------------|
| 0.4		| 2020/03/23		| Initial proposal for hardened UEFI Trellis Enterprise & TIE templates. | |

### Kickstarts
| File Name                 | Target Type         | Target Product              | Boot Type | Nature of Enhancements           | Product Compatibility |
|---------------------------|---------------------|-----------------------------|-----------|----------------------------------|--------|
| ks_tie_rhel7-efi-stig.cfg | Virtual* & Physical | Trellis Intelligence Engine | UEFI      | Security hardening towards NIST STIG baseline.<br>*Note:* It is not possible to completely meet this compliance level. | x |
| ks_trellis_rhel7-efi-stig.cfg | Virtual* & Physical | Trellis Intelligence Engine | UEFI   | Security hardening towards NIST STIG baseline.<br>*Note:* It is not possible to completely meet this compliance level. | 5.0.x, 5.1.x |

# Instructions

## Kickstart Preparation
Pending writeup.

## Kick Start Launch
There are three main ways of initiating an installation with these kickstarts.

1. [Local Media with kickstart on media](#Kickstart-on-Media)
2. [Local Media with hosted kickstart on FTP, HTTP or NFS](#Kickstart-with-Local-Media)
3. [Network boot with hosted kickstart on FTP, HTTP or NFS](#Kickstart-with-PXE-Boot)

### Kickstart on Media
Pending writeup.

Reference: [How Do You Perform a Kickstart Installation?](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-kickstart-howto)

### Kickstart with Local Media
This will run with the default options to provide a quick default overview of the system. It will additionally launch notepad with the content of the log file.

1. Boot from installation media (ISO/USB)
2. During boot menu edit the boot load by either pressing `<e>` or `<tab>` key as indicated on the menu.
3. Append the kernel line with the `inst.ks` property.

```shell
inst.ks=[ftp|http|nfs]://<IP>/<PATH>/<KICKSTART_FILE>
```
#### BIOS Example
```shell
append initrd=initrd.img inst.ks=http://10.0.244.100/mnt/archive/RHEL-7/7.x/Server/x86_64/kickstarts/ks.cfg
```
#### UEFI Example
```shell
kernel vmlinuz inst.ks=http://10.0.244.100/mnt/archive/RHEL-7/7.x/Server/x86_64/kickstarts/ks.cfg
```

Useful parameters to be aware of when kickstarting RHEL/CentOS/OEL 7.x:

| Parameter   | Description      | Structure                        | Example |
|-------------|------------------|----------------------------------|---------|
| `inst.repo` | Specifies the installation source if it is not local media. For example when using the boot only image to conduct a network installation. | | `inst.repo=https://deploy.int.example.org/os/linux/rhel/7/7_7/` |
| `inst.text` | Forces text only mode. | | |
| `inst.sshd` | Enables SSH service during installation for the purposes of monitoring status remotely. | | |
| `ip`        | Allows TCP/IP settings to be defined, useful if the network does not offer DHCP. | `ip=ip::gateway:netmask:hostname` | `ip=10.0.244.44::10.0.244.1:255.2555.255.0:example-host` |
| `nameserver` | Defines the DNS server to use. | `nameserver=<IPv4\|IPv6>` | `nameserver=9.9.9.11` |
| `inst.syslog` | Defines the syslog server to send logging information to, this is useful for headless installs, particularly network boots. | `inst.syslog=<IPv4\|IPv6>` | `inst.syslog=10.0.244.250` |

Reference: [Chapter 22. Boot Options](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/chap-anaconda-boot-options)
Reference: [Starting the Kickstart Installation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/installation_guide/sect-kickstart-howto#sect-kickstart-installation-starting)

### Kickstart with PXE Boot
Pending.

Reference: [Configuring PXE Boot Servers for UEFI](https://github.com/tianocore/tianocore.github.io/wiki/Configuring-PXE-Boot-Servers-for-UEFI)

## Support
These collections are provided to aid Vertiv Software Delivery, Services and
Software Delivery, Support teams, guidance and support for Postman - or
alternatives - is not provided.

| Release   | Support Status      | Notes             | OS Compatibility    | Trellis Compatibility |
|-----------|-------------------|-------------------|---------------|----------------------|
| 0.4 			| Unsupported* | Draft for review. | RHEL 7.x, CentOS 7.x, OEL 7.x | 5.1.x, 5.0.x |

### Maintainers
Feedback on function, errata and enhancements is welcome, this can be sent to the following mailbox.

| Name                 | Organization      | Contact                                                          |
|----------------------|-------------------|------------------------------------------------------------------|
| Professional Services     | Vertiv            | global.services.delivery.development@vertiv.com                |

### Known Issues
* hdparam missing from packages.
* shmmall is set to 8GB which is not safe for 5.0.x or 5.1.x, it must be doubled.
* GPG key import will produce failures in installer log as all three distributions are blindly imported regardless of whether the key is present.
