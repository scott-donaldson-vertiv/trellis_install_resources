#---------------------------------------------------------------------------------------------
# Script Name: Checks-Security
# Created: 2015/03/21
# Author: Scott Donaldson [NETPWR/AVOCENT/UK]
# Company: Emerson Network Power
# Group: Professional Services
# Email:scott.donaldson@emerson.com
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
#
#---------------------------------------------------------------------------------------------
function Get-SystemUacStatus {
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
	return $((Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System).EnableLUA)
}
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
#
#---------------------------------------------------------------------------------------------
function Get-SystemUacGpo {
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
		[string[]]$DomainName = [Environment]::UserDomainName,	# Domain name only
		[String[]]$UacSetting = $null,							# Return value for specific entry
		[Switch]$ListSettings,									# List all valid UAC parameters
		[String[]]$MatchString = $null,							# Match by string			#
		[int]$MatchValue = $null								# Match by numeric value
	)

	#
	# Based on description at https://technet.microsoft.com/en-us/library/dd835564%28v=ws.10%29.aspx
	# 
	$uacRegistryRoot = "Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
	
	# Required
	$uacRequired = @{
		"EnableLUA" = "Disabled"; # Default: Enabled
		"EnableUIADesktopToggle" = "Disabled"; # Default: Disabled
		"ConsentPromptBehaviorAdmin" = "Elevate without prompting"; # Default: Prompt for consent non-Windows Binaries
		"ConsentPromptBehaviorUser" = "Prompt for credentials."; # Default: Prompt for consent
		"EnableInstallerDetection" = "Disabled"; # Default: Disabled (Enterprise)
		"ValidateAdminCodeSignatures" = "Enabled"; # Default: Disabled
		"EnableSecureUIAPaths"	= "Disabled"; # Default: Enabled
		"FilterAdministratorToken" = "Enabled"; # Default: Disabled
		"PromptOnSecureDesktop" = "Disabled"; # Default: Enabled
		"EnableVirtualization" = "Enabled" # Default: Enabled
	}
	
	$uacDefaults = @{
		"EnableLUA" = "Enabled"; # Default: Enabled
		"EnableUIADesktopToggle" = "Disabled"; # Default: Disabled
		"ConsentPromptBehaviorAdmin" = "Prompt for consent non-Windows Binaries"; # Default: Prompt for consent non-Windows Binaries
		"ConsentPromptBehaviorUser" = "Prompt for credentials."; # Default: Prompt for consent
		"EnableInstallerDetection" = "Disabled"; # Default: Disabled (Enterprise)
		"ValidateAdminCodeSignatures" = "Disabled"; # Default: Disabled
		"EnableSecureUIAPaths"	= "Enabled"; # Default: Enabled
		"FilterAdministratorToken" = "Disabled"; # Default: Disabled
		"PromptOnSecureDesktop" = "Enabled"; # Default: Enabled
		"EnableVirtualization" = "Enabled" # Default: Enabled
	}

	# Common between entries
	$uacEnumCommon = @{
		0 = "Disabled";
		1 = "Enabled";
	}
	
	# Values specific for ConsentPromptBehaviorAdmin
	$uacEnumConsentPromptBehaviorAdmin = @{
		0 = "Elevate without prompting";
		1 = "Prompt for credentials on the secure desktop";
		2 = "Prompt for consent on the secure desktop";
		3 = "Prompt for credentials";
		4 = "Prompt for consent";
		5 = "Prompt for consent for non-Windows binaries";
	}

	# Values specific for ConsentPromptBehaviorUser
	$uacEnumConsentPromptBehaviorUser = @{
		0 = "Automatically deny elevation requests";
		1 = "Prompt for credentials on the secure desktop";
		3 = "Prompt for credentials"
	}
	
	#
	# We want to list all valid settings
	#
	if ($ListSettings) {
		 Write-Host "Valid properties to query are.`n"
		 $uacRequired.GetEnumerator() | Sort-Object Name | ForEach-Object -Process { Write-Host -NoNewline "`t"$_.Name"`n" }
		 Write-Host
		 return $null
	}
	#####
	
	#
	#  Check the particular value provided for UacSetting
	#
	if ($UacSetting -ne $null) {
		if (($uacDefaults.ContainsKey("$UacSetting")) -eq "True" ) {
			if ($UacSetting -like "ConsentPromptBehaviorUser") {
				if ($MatchString -ne $null) {
					if (($uacEnumConsentPromptBehaviorUser.Get_Item(((Get-ItemProperty -Path $uacRegistryRoot).$UacSetting))) -eq $MatchString) { return $true }
					return $false
				} else {
					return ($uacEnumConsentPromptBehaviorUser.Get_Item(((Get-ItemProperty -Path $uacRegistryRoot).$UacSetting)))
				}
			} elseif ($UacSetting -like "ConsentPromptBehaviorAdmin") {
				if ($MatchString -ne $null) {
					if (($uacEnumConsentPromptBehaviorAdmin.Get_Item(((Get-ItemProperty -Path $uacRegistryRoot).$UacSetting))) -eq $MatchString) { return $true }
					return $false
				} else {
					return ($uacEnumConsentPromptBehaviorAdmin.Get_Item(((Get-ItemProperty -Path $uacRegistryRoot).$UacSetting)))
				}
			} else {
				if ($MatchString -ne $null) {
					if (($uacEnumCommon.Get_Item(((Get-ItemProperty -Path $uacRegistryRoot ).$UacSetting))) -eq $MatchString) { return $true }
					return $false	
				} else {
					return ($uacEnumCommon.Get_Item(((Get-ItemProperty -Path $uacRegistryRoot ).$UacSetting)))
				}
			}
		} else {
			return $false;
		}
	} else {
		Write-Host "Null"
	}
	#####

	return $null;
}
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
#
#---------------------------------------------------------------------------------------------
function Get-SystemLpimGpo {
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

	return $false;
}
#---------------------------------------------------------------------------------------------



#---------------------------------------------------------------------------------------------
#
#---------------------------------------------------------------------------------------------
function Get-IsPsAdministrator {
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

	#
	#  (see. http://blogs.technet.com/b/heyscriptingguy/archive/2011/05/11/check-for-admin-credentials-in-a-powershell-script.aspx )
	#
	if ($AdministratorTest -is [System.Management.Automation.PSCredential]) {
		return $true;
	}
	return $false;
}
#---------------------------------------------------------------------------------------------
