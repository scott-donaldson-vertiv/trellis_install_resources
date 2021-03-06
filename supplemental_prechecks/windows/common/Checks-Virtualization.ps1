#---------------------------------------------------------------------------------------------
# Script Name: RunCheckDiskSpace
# Created: 2014/05/15
# Author: Scott Donaldson [NETPWR/AVOCENT/UK]
# Company: Emerson Network Power
# Group: Professional Services
# Email:scott.donaldson@emerson.com
#---------------------------------------------------------------------------------------------

#
#
#
function Get-GuestTools {
param (
    [string]$Hypervisor,						# Hypervisor to check for
	[string]$TargetServer = $env:COMPUTERNAME	#
)
	# Convert for tool names
	switch -wildcard ($Hypervisor) {
		"*vmware*" 	{ $ToolsName = "VMware Tools"}
		"*xen*"		{ $ToolsName = "Xen" }
		"*hyperv*"	{ $ToolsName = "Hyper-V" }
		default 	{ $ToolsName = "_INVALID_" }
	}
	
	$output = @{}
	$out = Get-WmiObject -Computer $TargetServer -Class Win32_Product | Where-Object {$_.Name -contains $ToolsName}
	if ($out) {
		$output.Name = (@($out) | % { $_.Name });
		$output.Vendor = (@($out) | % { $_.Vendor });
		$output.Version = (@($out) | % { $_.Version });
	} else {
		$output.Name = "Unknown";
		$output.Vendor = "Unknown";
		$output.Version = "Unknown";
	}
	New-Object -TypeName PSObject -Property $output
}
#####

function Get-Hypervisor {
param (
	[string]$TargetServer = $env:COMPUTERNAME
)
	$Hypervisor = Get-WmiObject -query 'select * from Win32_ComputerSystem' | Select-Object Manufacturer,Model
	switch -wildcard ($Hypervisor.Manufacturer) {
		"Xen" 				{ $HV = "Citrix XenServer" }
		"VMware, Inc." 		{ $HV = "VMware ESXi" }
		"Microsoft Hyper-V" { $HV = "Microsoft Hyper-V" }
		default 			{ $HV = "Unknown" }
	}
	return $HV
}

