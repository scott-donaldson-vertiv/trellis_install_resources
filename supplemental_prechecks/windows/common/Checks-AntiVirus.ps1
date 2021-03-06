#---------------------------------------------------------------------------------------------
# Script Name: RunCheckDiskSpace
# Created: 2014/05/15
# Author: Scott Donaldson [NETPWR/AVOCENT/UK]
# Company: Emerson Network Power
# Group: Professional Services
# Email:scott.donaldson@emerson.com
#---------------------------------------------------------------------------------------------

function Get-CheckRunningAv {
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
	[switch]$OverwriteXMLFile = $false						# Force creation/overwrite of file
	#[string]$OutputXMLFile = $(throw "-OutputXMLFile is required."),
)
#---------------------------------------------------------------------------------------------

	#
	#	Get Anti-Virus Status for Windows Vista / Windows 7
	#
	Write-Debug "[Info]: Gathering Anti-virus/Internet Security Information..."
	
	try {
		$AntiVirusProduct = Get-WmiObject -Namespace root\SecurityCenter2 -Class AntiVirusProduct  -ComputerName $TargetServer -ErrorAction SilentlyContinue
	} catch {
	#if ($AntiVirusProduct.productState = $null) {
		# Fall Back Method (see. http://serverfault.com/questions/12343/how-can-i-determine-whether-an-antivirus-product-is-installed )
		#$FallBackMethod = Get-WmiObject -Namespace root\cimv2 -class Win32_Product -ComputerName $TargetServer -Filter "Name like '%antivirus%'"
		$AntiVirusProduct = Get-WmiObject -Namespace root\cimv2 -class Win32_Product -ComputerName $TargetServer -Filter "Name like '%endpoint%'"
	#}
	}
	
	#
	#	Detect Anti-Virus Status
	#
	#	Switch to determine the status of antivirus definitions and real-time protection. 
	#	The values in this switch-statement are retrieved from the following website: http://community.kaseya.com/resources/m/knowexch/1020.aspx 
	#	http://neophob.com/2010/03/wmi-query-windows-securitycenter2/
	switch ($AntiVirusProduct.productState) { 
		"262144" {$defstatus = "Up to date" ;$rtstatus = "Disabled"} 
	    "262160" {$defstatus = "Out of date" ;$rtstatus = "Disabled"} 
	    "266240" {$defstatus = "Up to date" ;$rtstatus = "Enabled"} 
	    "266256" {$defstatus = "Out of date" ;$rtstatus = "Enabled"} 
	   	"393216" {$defstatus = "Up to date" ;$rtstatus = "Disabled"} 
	   	"393232" {$defstatus = "Out of date" ;$rtstatus = "Disabled"} 
	   	"393488" {$defstatus = "Out of date" ;$rtstatus = "Disabled"} 
	   	"397312" {$defstatus = "Up to date" ;$rtstatus = "Enabled"} 
	   	"397328" {$defstatus = "Out of date" ;$rtstatus = "Enabled"} 
	   	"397584" {$defstatus = "Out of date" ;$rtstatus = "Enabled"} 
		"462864" {$defstatus = "Out of date" ;$rtstatus = "Enabled"}
		"462848" {$defstatus = "Up to date" ;$rtstatus = "Enabled"}
		"331776" {$defstatus = "Up to date" ;$rtstatus = "Enabled"}
		default {$defstatus = "Unknown" ;$rtstatus = "Unknown"} 
	}

	$output = @{}
	$output.Vendor = $FallBackMethod.Vendor
	$output.DisplayName = $AntiVirusProduct.displayName
	$output.Version = $FallBackMethod.Version
	$output.ProgramLocation = $AntiVirusProduct.pathToSignedProductExe
	$output.Definitions = $defstatus
	$output.Status = $rtstatus
	
	New-Object -TypeName PSObject -Property $output
	#####
}