#---------------------------------------------------------------------------------------------
# Script Name: Checks-InstalledApps
# Created: 2015/11/04
# Author: Scott Donaldson [NETPWR/AVOCENT/UK]
# Company: Emerson Network Power
# Group: Professional Services
# Email:scott.donaldson@emerson.com
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
# Get-RolePresent
#---------------------------------------------------------------------------------------------
function Get-RolePresent {
	<#
	   	.Synopsis
	    Check if UAC is enabled
	   	.Description
	    This function tests whether UAC is enabled for the current system/user
	   	.Example
	    Get-SystemUacStatus
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
		[string[]]$DomainName = [Environment]::UserDomainName	# Domain name only
	)
	
	Import-Module ServerManager
	
	Get-WindowsFeature Web-WebServer, Web-Common-Http
	
	return $null
}
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
# Get-FeaturePresent
#---------------------------------------------------------------------------------------------
function Get-FeaturePresent {
	<#
	   	.Synopsis
	    Check if UAC is enabled
	   	.Description
	    This function tests whether UAC is enabled for the current system/user
	   	.Example
	    Get-SystemUacStatus
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
		[string[]]$DomainName = [Environment]::UserDomainName	# Domain name only
		#[switch]$OverwriteXMLFile = $false						# Force creation/overwrite of file
		#[string]$OutputXMLFile = $(throw "-OutputXMLFile is required."),
	)
	
	return $null
}
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
# Get-SpecificWebServerPresent
#---------------------------------------------------------------------------------------------
function Get-IisWebServerRunning {
	<#
	   	.Synopsis
	    Checks if any existing webservers are present.
	   	.Description
	    This function checks for services and port bindings consistent with a running webserver
	   	.Example
	    Get-SpecificWebServerPresent
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
		[string[]]$DomainName = [Environment]::UserDomainName	# Domain name only
		#[switch]$OverwriteXMLFile = $false						# Force creation/overwrite of file
		#[string]$OutputXMLFile = $(throw "-OutputXMLFile is required."),
	)

	$iisStatus = $null
	$iisStatus = Get-WmiObject Win32_Service -ComputerName $TargetServer -Filter "name='IISADMIN'"
	
	if ($iisStatus) {
		if (($iisStatus.State -eq "Running") -or ($iisStatus.StartMode -like "Auto")) {
	  		return $true	# IIS is present and either running or configured to auto start (like used to cover Auto (Delayed)
		} else {
			return $false	# IIS is present but not running or set to startup automatically
		}
	} else {
	  return $false			# No IISADMIN found, not installed
	}
}
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
# Get-ServiceListeners
#---------------------------------------------------------------------------------------------
function Get-ServiceListeners {
	<#
	   	.Synopsis
	    Checks a list of ports for listening services and return details.
	   	.Description
	    Checks a list of ports for listening services and return details of listening process.
	   	.Example
	    Get-ServiceListeners
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
		[string[]]$DomainName = [Environment]::UserDomainName	# Domain name only
		#[switch]$OverwriteXMLFile = $false						# Force creation/overwrite of file
		#[string]$OutputXMLFile = $(throw "-OutputXMLFile is required."),
	)

	return $null
}
#---------------------------------------------------------------------------------------------
