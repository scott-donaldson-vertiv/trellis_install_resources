#---------------------------------------------------------------------------------------------
# Script Name: Checks-Networking
# Created: 2014/05/15
# Author: Scott Donaldson [NETPWR/AVOCENT/UK]
# Company: Emerson Network Power
# Group: Professional Services
# Email:scott.donaldson@emerson.com
#---------------------------------------------------------------------------------------------

function Run-CheckNIC {
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
    [string[]]$targetServer = [Environment]::MachineName,	# Server name
    [string[]]$UserName = [Environment]::UserName,			# Username only
	[string[]]$DomainName = [Environment]::UserDomainName,	# Domain name only
	[switch]$OverwriteXMLFile = $false						# Force creation/overwrite of file
	#[string]$OutputXMLFile = $(throw "-OutputXMLFile is required."),
)
#---------------------------------------------------------------------------------------------

	$output = Get-WmiObject -ComputerName $targetServer Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" | Where-Object { $_.IPAddress }
	$output
	#####
}

function Run-CheckDhcp {
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
    [string[]]$targetServer = [Environment]::MachineName,	# Server name
    [string[]]$UserName = [Environment]::UserName,			# Username only
	[string[]]$DomainName = [Environment]::UserDomainName,	# Domain name only
	[switch]$OverwriteXMLFile = $false						# Force creation/overwrite of file
	#[string]$OutputXMLFile = $(throw "-OutputXMLFile is required."),
)
#---------------------------------------------------------------------------------------------

	$output = Get-WmiObject -ComputerName $targetServer Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" | Where-Object { $_.DHCPEnabled -like 'True'}
	
	$output
	#####
}

function Get-IPv4Address {
<#
   	.Synopsis
	Returns all IPv4 addresses assigned.
   	.Description
   	.Example
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
    [string[]]$targetServer = [Environment]::MachineName,	# Server name
    [string[]]$UserName = [Environment]::UserName,			# Username only
	[string[]]$DomainName = [Environment]::UserDomainName,	# Domain name only
	[switch]$FirstOnly = $false								# Default return only first IP entry
)
	#
	#  Filter out IPv4 using *.*
	#
	$returnIp = Get-WmiObject -ComputerName $targetServer Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" | Select -ExpandProperty IPAddress | Where {$_ -notlike "*:*"}
	if ($FirstOnly) { $returnIp = $returnIp | Select-Object -First 1 }
	return $returnIp
	#####
}
#---------------------------------------------------------------------------------------------

function Get-IPv6Address {
<#
   	.Synopsis
	Returns all IPv6 addresses assigned.
   	.Description
   	.Example
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
    [string[]]$targetServer = [Environment]::MachineName,	# Server name
    [string[]]$UserName = [Environment]::UserName,			# Username only
	[string[]]$DomainName = [Environment]::UserDomainName,	# Domain name only
	[switch]$FirstOnly = $false								# Default return only first IP entry
)

	#
	#  Filter out IPv4 using *.*
	#
	$returnIp = Get-WmiObject -ComputerName $targetServer Win32_NetworkAdapterConfiguration -Filter "IPEnabled = True" | Select -ExpandProperty IPAddress | Where {$_ -notlike "*.*"}
	if ($FirstOnly) { $returnIp = $returnIp | Select-Object -First 1 }
	return $returnIp
	#####
}
#---------------------------------------------------------------------------------------------

function CheckFirewallState {
<#
   	.Synopsis
	Modified from http://poshcode.org/836 to permit verification across all three firewall profiles.
	.Description
   	.Example
   	.Example
    .Parameter TargetServer
	.Parameter UserName
	.Link
#>
	param (
		[string]$targetServer = [Environment]::MachineName,
		[string]$UserName = [Environment]::UserName
	)
	
	if ($_) { $targetServer = $_ }

	$HKLM = 2147483650

	$firewallState = @{}
	
	$regConfig = Get-WmiObject -List -Namespace root\default -Computer $targetServer | Where-Object { $_.name -eq "StdRegProv" }
	$fwManager = (New-Object -com HNetCfg.FwMgr).LocalPolicy.CurrentProfile
	[bool]$firewallState.Current = $fwManager.FirewallEnabled
	[bool]$firewallState.ExceptionsNotAllowed = $fwManager.ExceptionsNotAllowed
	[bool]$firewallState.Domain = ($regConfig.GetDwordValue($HKLM, "System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile","EnableFirewall")).uValue
	[bool]$firewallState.Public = ($regConfig.GetDwordValue($HKLM, "System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile","EnableFirewall")).uValue
	[bool]$firewallState.Standard = ($regConfig.GetDwordValue($HKLM, "System\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile","EnableFirewall")).uValue

	New-Object -TypeName PSObject -Property $firewallState
}

function CheckFirewallRule {
<#
   	.Synopsis
	Modified from http://poshcode.org/836 to permit verification across all three firewall profiles.
	.Description
   	.Example
   	.Example
    .Parameter TargetServer
	.Parameter UserName
	.Link
#>
	param (
		[string]$targetServer = [Environment]::MachineName,
		[string]$UserName = [Environment]::UserName,
		[ValidateSet("tcp","udp")][string]$Protocol = 'tcp',
		[ValidateRange(0,65535)][int]$Ports
	)
	process {
		Write-Debug "New-CheckFirewallRule"
	}

	#netsh.exe advfirewall firewall add rule name = '$($_.name)' dir=$($_.dir) action=$($_.action) enable=$($_.enable)  profile=$($_.profile) localip=$($_.localip) remoteip=$($_.remoteip) protocol=$($_.protocol) edge=$($_.edge) localport=$($_.localport) remoteport=$($_.remoteport)
	
}

function Get-HostResolutionIPv4 {

	param (
		[string]$targetHostname = $null
	)
	return (Resolve-Host -PassThru $targetHostname -ErrorAction silentlyContinue | Select-Object AddressList -ExpandProperty AddressList | ?{ $_.AddressFamily -like "InterNetwork"} | Select-Object IPAddressToString)
}

function Get-HostResolutionIPv6 {

	param (
		[string]$targetHostname = $null
	)
	return (Resolve-Host -PassThru $targetHostname -ErrorAction silentlyContinue | Select-Object AddressList -ExpandProperty AddressList | ?{ $_.AddressFamily -like "InterNetworkV6"} | Select-Object IPAddressToString)
}

#
#  Get-PostIsListening
#
function Get-PortIsListening {
	param (
	[string]$targetServer = [Environment]::MachineName,
	[string]$UserName = [Environment]::UserName,
	[ValidateSet("tcp","udp")][string]$Protocol = 'tcp',
	[ValidateRange(0,65535)][int]$PortNum
	)
	
	$ErrorActionPreference = 'SilentlyContinue'
	
	#
	#  Create Connction for appropriate protocol then bind to port
	#
	if ($Protocol -eq "tcp") {
		$testSocket = New-Object Net.Sockets.TcpClient
	} else {
		$testSocket = New-Object Net.Sockets.UdpClient
	}
	$testSocket.Connect($targetServer,$PortNum)
	######
	
	#
	#  Verify connection status
	#
	if ($testSocket.Connected) {
		$testSocket.Close()
		$testSocket = $null
		return $true
	} else {
		$testSocket = $null
		return $false
	}
}
######

#
# Get-PortCanBind
#
function Get-PortCanBind {
	param (
	[string]$targetServer = [Environment]::MachineName,
	[string]$UserName = [Environment]::UserName,
	[ValidateSet("tcp","udp")][string]$Protocol = 'tcp',
	[ValidateRange(0,65535)][int]$PortNum,
	[switch]$waitForConnect = $false
	)
	
	$ErrorActionPreference = 'SilentlyContinue'
	
	$testInterface = New-Object System.Net.IPEndPoint ([ipaddress]::any,$PortNum)
	if ($testInterface) {
		$testListener = New-Object System.Net.Sockets.TcpListener $testInterface
		if ($testListener) {
			try {
				$testListener.Start()
				if ($waitForConnect) {
					$testListener.AcceptTcpClient() # Will wait for a connection before proceeding
				}
				$testListener.Stop()
				
				# Cleanup
				$testListener = $null
				$testInterface = $null
				return $true
			} Catch {
				$ErrorMessage = $_.Exception.Message
    			$FailedItem = $_.Exception.ItemName
			}
		}
	}
	
	#
	#  Fall through to fail
	#
	$testListener = $null
	$testInterface = $null
	return $false  # Interface binding failed
}
######