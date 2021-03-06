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
function Get-SysInternalBundle {
param (
    [Parameter(mandatory=$true)][string]$SourcePath,		# Source of files to copy
	[Parameter(mandatory=$true)][string]$DestinationPath = $env:windir
)
	$output = $true
	$files = Get-ChildItem $SourcePath
	foreach ($file in $files) {
		if (!(Test-Path $DestinationPath\$file)) { 
			Write-Verbose "`t`tfail - $file does not exist."
			$output = $output -and $false
		} else {
			Write-Verbose "`t`tpass - $file exists."
			$output = $output -and $true
		}
	}
	return $output
}
#####

#
#
#
function Deploy-SysInternalBundle {   	
param (
    [Parameter(mandatory=$true)][string]$SourcePath,		# Source of files to copy
	[Parameter(mandatory=$true)][string]$DestinationPath = $env:windir
)
	#
	#	Copy
	#
	if ((Test-Path $SourcePath) -and (Test-Path $DestinationPath)) {
		Copy-Item $SourcePath\* $DestinationPath\ -Recurse #-ErrorAction SilentlyContinue
	}
	#####
}