# Trellis™ Enterprise - Supplemental Pre-Installation Checks for Linux

## Introduction

This script provides additional pre-installation checks for Trellis™ Enterprise on Redhat Enterprise Linux, CentOS & Oracle Enterprise Linux.

#### Versions
| Release   | Release Date      | Notes             | Bugs Fixed    |
|-----------|-------------------|-------------------|---------------|
| 5.0.2		| 2020/12/03		| Corrections for shared memory. | |
| 5.0.1		| 2020/08/26		| Corrections for shared memory and sysctl validations. | |
| 2.0		| 2020/07/02		| Clean-up of resources, script names, copy right statements.<br>Corrected Author, Contributors & Maintainers to be consistent and compliant with license requirements.<br>Added additional documentation. | |
| 3.3		  | 2018/?/?	  	| Enhancements for Trellis 5.x. | |
| 3.2		  | ?							| Enhancements for upgrade detection. | ENTPL-7 Move Revision Notes Out of Script<br>ENTPL-6 Modifications to prompts to start matching Windows output. (Initial changes)<br>ENTPL-5 Base Log Output on Hostname & Run Time<br>ENTPL-4 Provide List of Packages to Installed<br>ENTPL-3 Support sudo entries placed in /etc/sudoers.d/trellis<br>ENTPL-2 Place report output in /u05 for easier access<br>ENTPL-1 Detect & permit execution with sudo |
| 3.1     |               | See change history section.        | |
| 3.0     |               | See change history section.        | |
| 2.8     |               | See change history section.        | |
| 2.7     |               | See change history section.        | |
| 2.6     |               | See change history section.        | |
| 2.5     |               | See change history section.        | |
| 2.4     |               | See change history section.        | |
| 2.3     |               | See change history section.        | |
| 2.2     |               | See change history section.        | |
| 2.1     |               | See change history section.        | |
| 2.0     | 2014/04/02    | See change history section.        | |        
| 1.2     | 2013/10/28    | See change history section.        | |
| 1.1     | 2013/10/25    | See change history section.        | |
| 1.0     | 2013/10/25    | See change history section.        | |

# Instructions

To launch the script you have two methods available.

## Quick Launch
This will run with the default options to provide a quick default overview of the system. It will additionally launch notepad with the content of the log file.

```shell
sudo supplimental_trellis-checks.sh
```

## Support
These collections are provided to aid Vertiv Software Delivery, Services and
Software Delivery, Support teams, guidance and support for Postman - or
alternatives - is not provided.

| Release   | Support Status      | Notes             | Linux Compatibility    | Trellis Compatibility |
|-----------|-------------------|-------------------|---------------|----------------------|
| 5.0.2 			| Supported* | RHEL 7.x, CentOS 7.x | Windows Server 2012 R2, 2016 | 5.1.x, 5.0.x, 4.0.x* |
| 5.0.1 			| Supported* | RHEL 7.x, CentOS 7.x | Windows Server 2012 R2, 2016 | 5.1.x, 5.0.x, 4.0.x* |
| 5.0 			| Supported* | RHEL 6.x/7.x, CentOS 6.x/7.x | Windows Server 2012 R2 | 5.1.x, 5.0.x, 4.0.x* |
| 3.3				| Deprecated | | RHEL 6.x | 4.0.x* |
| 3.2				| Deprecated | | RHEL 6.x | 4.0.x* |

### Maintainers
Feedback on function, errata and enhancements is welcome, this can be sent to the following mailbox.

| Name                 | Organization      | Contact                                                          |
|----------------------|-------------------|------------------------------------------------------------------|
| Professional Services     | Vertiv            | global.services.delivery.development@vertiv.com                |

### Change History

Legacy change history information, this will not be updated going forward and instead tracked with release notes.

##### v3.2
* ENTPL-7 Move Revision Notes Out of Script
* ENTPL-6 Modifications to prompts to start matching Windows output. (Initial changes)
* ENTPL-5 Base Log Output on Hostname & Run Time
* ENTPL-4 Provide List of Packages to Installed
* ENTPL-3 Support sudo entries placed in /etc/sudoers.d/trellis
* ENTPL-2 Place report output in /u05 for easier access
* ENTPL-1 Detect & permit execution with sudo

##### v3.1
* Bug fix RHEL >6.5 not running with correct validation parameters

#### v3.0
* OS checks for 6.5 now don’t “fail” but have a status of “passed (limited)” in the log file it states that it needs approval.  This has now been put in the same category as 6.3.
* Hostname now uses “hostname -s” for short host names and “hostname -f” for full hostnames.
* Summary is now using the same code as later in the script.  Code refined to be more consistent.
* IP address now shows as 0.0.0.0 if it is duplicated anywhere in the script
* Sudoers checked enhanced incase additional Sudoer entries exist (was expecting 7 or fail)
* Enhanced sysctl checking for values that contain spaces
* Time Zone checking (make sure time zone is within supported list)
* Symlink checking support for 6.5, now uses libcrypto.so.1.0.1e and libssl.so.1.0.1e
* Fixed issue with DCHP checking on virtualised NIC, now dynamically determines interface (all but “lo”) and doesn’t just expect “eth”
* Fixed issue with Sudoers, now supports external included sudoers files with more than 7 entries.  (must support running sudo -l)
* Fixed issue with TimeZone check failing
* Added support for IPTables for RH 6.5
* Added screen command required packages
* Added tolerance for up to 0.9GB (for partitions above 10GB) and up to 100MB for partitions below (10 GB) for hard disk sizing requirements before failure
* Added check for virtual / physical
* Added check for VMWare Tools
* Added display fix for pass / failure status when rebuilding hosts file
* Added check for rngd entropy service
* Added check for rngd entropy extra options (virtualisation only)
* Added extra sysctl parameter for entropy
* Added auto-detection of previous trellis installation
* Added support for pre-check for patch installations
* Added support no FQDN in hosts file
* Added timeserver and timezone details to summary
* Added server type to summary
* Added break out of cores per cpu and total cores in summary
* Added etc/sysctl.conf template
* Added requirement numbers and grouped checks as per requirements matrix
* Added summary and pass / fail for Average speed check
* Added CPU Frequency Check
* Added CPU Core Check
* Added Date & time to summary
* Added display of current Trellis Version

#### v2.8
* Added patch /sbin check to user environment variable check
* Removed re-write check and changed write check to not use cached values

#### v2.7
* Changed sudoers to only expect default content due to engineering recommendations
* All temporary config files are stored now stored in a directory
* Clean up of some additional temporary files that were created
* Added check whether OS is 32 or 64 bit
* Info added for sysctl parameters that are greater than defaults
* Added partitioning checking
* Merged partition and memory checking into "hardware specification checks"
* Added enhanced partition checking
* Optimised sudoers code to run in a loop
* Optimised sysctl code to run in a loop
* Fixed rounding issue on space error warning, it now shows exact space rounded to 2 decimal places
* Added failure on space requirements for root partition

#### v2.6
* Added message when detecting server
* Fixed input show error on host file creation
* Fixed exit error if no valid selection for host creation question

#### v2.5
* Added Confirm file permissions are retained
* Added Network Time Server Details
* Added check to run script as root only
* Added auto-detection of front and back ip / hosts for subsequent runs
* Added auto-detection of ip / host conflicts
* Shortened message for disk speed tests

#### v2.4
* Added additional comments in sysctl.conf output
* Added validation check for sysctl.conf parameters kernel.sem and net.ipv4.ip_local_port_range
* Added temp file creation of pam.d-login
* Added automatic generation of entropy
* Added additional comments
* Added enhanced disk write checks

#### v2.3
* Added enhanced validation for hosts file (only compare front and back IP)
* Added cores to CPU summary
* Added check for sudoers if unable to run sudo command as oracle in script

#### v2.2
* Added checking for sudoers and support for aliases
* Added checking for for disk check and disk rewrite check
* Added oracle umask check
* Added oracle /etc/pam.d/login content check
* Added enhanced nodemanger content check
* Added server configuration
* Added autogeneration option of hosts file
* Added check for licence server symlinks

#### v2.1
* Added duplicate line checking for sysctl.conf
* Ignore commented out lines in sysctl.conf
* Added checking for limits.conf
* Fixed DHCP checking, now allows for bootproto in and out of speachmarks
* Check iptables service is disabled
* Check network manager service is disabled
* Hosts checking now ommits 127.0.0.1 and ::1

#### v2.0
* 02/04/14
* Added:    Checking of server front / back (adapted from MS Script)
* Added:    Full creation of hosts file  (adapted from MS Script)
* Added:    Support for RH 6.4 / Trellis 3.x support
* Added:    Various fixes for comparison strings
* Added:    Automated checking of sysctl.conf  (adapted from MS Script)

#### v1.2
* 28/10/13
* Removed:    IPV6 test as Trellis 2.2 now supports IPV6
* Added:    none as check for  config (same as static)

##### v1.1
* 25/10/13:
* Added:     Checking that ANT is not installed

#### v1.0
* 25/10/13:
* Added:    RH 5.9 is now supported and checked

### Known Issues
* Windows Server 2016 is reported as unsupported.
* Remove unnecessary inline comments.
* ENPTCHK-9	Detect Simple TCP/IP Services
* ENPTCHK-11	Detect Whether Windows Update Will Restart The System
* ENPTCHK-6	Benchmark Secondary Storage when Detected Symbolic links
* ENPTCHK-13	Create Command Prompt Admin Shortcut to Trellis Folder on Desktop
* ENPTCHK-10	Report Output Enhancement to Use HTML5
* ENPTCHK-7	Detect Potential Conflicting IP Addresses
