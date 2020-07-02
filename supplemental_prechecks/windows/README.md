# Trellis™ Enterprise - Supplemental Pre-Installation Checks for Windows

## Introduction

This script provides additional pre-installation checks for Trellis™ Enterprise on Windows(r) Server.

#### Versions
| Release   | Release Date      | Notes             | Bugs Fixed    |
|-----------|-------------------|-------------------|---------------|
| 2.0		| 2020/07/02		| Clean-up of resources, script names, copy right statements.<br>Corrected Author, Contributors & Maintainers to be consistent and compliant with license requirements.<br>Added additional documentation. | |
| 3.2		  | ?							| Enhancements for upgrade detection. | |
| 1.6 		| 2016/03/09		| Bug fixes. 		| ENPTCHK-3	FQDN & Hostname Not Being Placed at Beginning of Generated Hostfile<br>ENPTCHK-8	Detect Presence of IIS<br>ENPTCHK-12	IPv6 Break Host File Creation<br>ENPTCHK-1	IPv6 Addresses Break Test Validations<br>ENPTCHK-2	Disk Throughput Test Can Fail Even Though Criteria is Met<br>ENPTCHK-5	Trellis 3.4 Has More Stringent UAC Requirements	(Re-opened) |
| 1.5		| 2015/?/?			| Bug fixes.		| ENPTCHK-5	Trellis 3.4 Has More Stringent UAC Requirements |

# Instructions

To launch the script you have two methods available.

## Quick Launch
This will run with the default options to provide a quick default overview of the system. It will additionally launch notepad with the content of the log file.

```shell
run_quick.cmd
```

## Advanced Launch
To launch an elevated and execution permissive PowerShell session to run the script from launch the `run.cmd`.
```shell
run.cmd
```
Once the PowerShell session is open the script can be launched with the following parameters, if unsure the parameters names will tab complete, and where appropriate will tab complete values.

| Parameter 	| Usage																		| Values 				| Example			|
|---------------|---------------------------------------------------------------------------|-----------------------|-------------------|
| `Verbose`		| Verbose will output additional information to the console window, this information is the same as written to the log file. | | `trellis-precheck -Verbose`	|
| `SelfRepair`	| SelfRepair will enable repair capabilities, these will still be confirmed individually before bing applied.| | `trellis-precheck -SelfFix` |
| `LogFile`		| <filename>	LogFile allows for the path & filename of the output log to be overriden.	| 		| `trellis-precheck -LogFile .\mylogfile.txt` |
| `TestVersMaj`	| Main Version to test against, must be used with -TestVersMin |	| `trellis-precheck -MajVer 3 -MinVer 2`	|
| `TestVersMin` | Main Version to test against, must be used with -TestVersMaj |	| `trellis-precheck -MajVer 3 -MinVer 3`	|
| `TrellisSizing` | Specify intended instance size Development, Small, Medium, Large, Enterprise | `small`\|`medium`\|`large` | `trellis-precheck -TrellisSizing Medium` |


## Support
These collections are provided to aid Vertiv Software Delivery, Services and
Software Delivery, Support teams, guidance and support for Postman - or
alternatives - is not provided.

| Release   | Support Status      | Notes             | Windows Compatibility    | Trellis Compatibility |
|-----------|-------------------|-------------------|---------------|----------------------|
| 5.0 			| Supported* | Requires update to support Windows Server 2016 with Trellis 5.1.x. | Windows Server 2012 R2 | 5.1.x, 5.0.x, 4.0.x* |
| 3.2				| Deprecated | | Windows Server 2008 R2 | 4.0.x* |
| 1.6 			| Deprecated | | Windows Server 2008 R2 | 4.0.x* |
| 1.5				| Deprecated. | | Windows Server 2008 R2 | 4.0.x, 3.0.x |

### Maintainers
Feedback on function, errata and enhancements is welcome, this can be sent to the following mailbox.

| Name                 | Organization      | Contact                                                          |
|----------------------|-------------------|------------------------------------------------------------------|
| Professional Services     | Vertiv            | global.services.delivery.development@vertiv.com                |

### Known Issues
* Windows Server 2016 is reported as unsupported.
* Remove unnecessary inline comments.
* ENPTCHK-9	Detect Simple TCP/IP Services
* ENPTCHK-11	Detect Whether Windows Update Will Restart The System
* ENPTCHK-6	Benchmark Secondary Storage when Detected Symbolic links
* ENPTCHK-13	Create Command Prompt Admin Shortcut to Trellis Folder on Desktop
* ENPTCHK-10	Report Output Enhancement to Use HTML5
* ENPTCHK-7	Detect Potential Conflicting IP Addresses
