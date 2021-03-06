#---------------------------------------------------------------------------------------------
# Script Name: RunCheckDiskSpace
# Created: 2014/05/15
# Author: Scott Donaldson [NETPWR/AVOCENT/UK]
# Company: Emerson Network Power
# Group: Professional Services
# Email:scott.donaldson@emerson.com
#---------------------------------------------------------------------------------------------

function RunCheckDiskSpace {
<#
   	.Synopsis
    Check diskspace criteria is met
   	.Description
    This script detects available space required for installation and outputs to an XML file.
   	.Example
    Trellis-Prereq
    Generates a report based on the current running user and machine in a plain text
	form against the newest release of Trellis®.
   	.Example
    Trellis-Prereq -FrontServer -DetectOtherServers -OutputMethod html
    .Parameter TargetServer
	The server name to run checks against, default is the running system.
	.Parameter UserName
	The user name to run checks against, default is the running user.
	.Parameter DomainName
	The domain to authenticate against, default is the running user's domain.
	.Link
   		https://www.emersonnetworkpower.com
#>

param (
    [string[]]$TargetServer = [Environment]::MachineName,	# Server name
    [string[]]$UserName = [Environment]::UserName,			# Username only
	[string[]]$DomainName = [Environment]::UserDomainName,	# Domain name only
	[string[]]$CheckSpecificDrives							# List specific drives to test
)
#---------------------------------------------------------------------------------------------

	if (!($CheckSpecificDrives)) {
		  Get-WmiObject -Class win32_Volume -ComputerName $TargetServer |
		  Select-object DriveLetter, Label, FileSystem, PageFilePresent,
		  @{Name = "ComputerName"; Expression = {$_.__Server} },
		  @{Name = "Capacity"; Expression = {$_.capacity / 1MB} },
		  @{Name = "FreeSpace"; Expression = {$_.Freespace / 1MB} },
		  @{Name = "PercentFree"; Expression = { ($_.FreeSpace / $_.Capacity)*100 } }
	} else {
		foreach($d in $CheckSpecificDrives)
		 {
		  Get-WmiObject -Class win32_Volume -ComputerName $TargetServer -Filter "DriveLetter = '$d'" |
		  Select-object DriveLetter, Label, FileSystem, PageFilePresent,
		  @{Name = "ComputerName"; Expression = {$_.__Server} },
		  @{Name = "Capacity"; Expression = {$_.capacity / 1MB} },
		  @{Name = "FreeSpace"; Expression = {$_.Freespace / 1MB} },
		  @{Name = "PercentFree"; Expression = { ($_.FreeSpace / $_.Capacity)*100 } }
		 }
	}
}

function Get-SymbolicDestinaton {
	param(
		[string]$Folder,
		[string]$Drive
	)
	if ((dir $env:SystemDrive | Select-String "SYMLINKD") -match "\w?:\\") {
		if ($matches -like $Drive) {
			return $true
		} else {
			return $false
		}
	}
	return $false
}