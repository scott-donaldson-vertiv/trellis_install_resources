#---------------------------------------------------------------------------------------------
# Script Name: Checks-Specifications
# Created: 2014/05/15
# Author: Scott Donaldson [NETPWR/AVOCENT/UK]
# Company: Emerson Network Power
# Group: Professional Services
# Email:scott.donaldson@emerson.com
#---------------------------------------------------------------------------------------------



function Get-CultureValid {
	if ((Get-Culture).Name -contains 'en-US') {
		return $true
	}
	return $false
}

function Get-RegionInfo {
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
	[switch]$OverwriteXMLFile = $false,						# Force creation/overwrite of file
	#[string]$OutputXMLFile = $(throw "-OutputXMLFile is required."),
	[string[]]$CheckSpecificDrives	= ""					# List specific drives to test
)
#---------------------------------------------------------------------------------------------
	$output = @{}
	
	$output.TimeZone = (Get-WmiObject -Computername $TargetServer Win32_Timezone).Caption
	$Keyboards = Get-WmiObject -Computername $TargetServer Win32_Keyboard
	$ObjKeyboards = Get-WmiObject -ComputerName $TargetServer Win32_Keyboard

	$keyboardmap = @{
	"00000402" = "BG" 
	"00000404" = "CH" 
	"00000405" = "CZ" 
	"00000406" = "DK" 
	"00000407" = "GR" 
	"00000408" = "GK" 
	"00000409" = "US" 
	"0000040A" = "SP" 
	"0000040B" = "SU" 
	"0000040C" = "FR" 
	"0000040E" = "HU" 
	"0000040F" = "IS" 
	"00000410" = "IT" 
	"00000411" = "JP" 
	"00000412" = "KO" 
	"00000413" = "NL" 
	"00000414" = "NO" 
	"00000415" = "PL" 
	"00000416" = "BR" 
	"00000418" = "RO" 
	"00000419" = "RU" 
	"0000041A" = "YU" 
	"0000041B" = "SL" 
	"0000041C" = "US" 
	"0000041D" = "SV" 
	"0000041F" = "TR" 
	"00000422" = "US" 
	"00000423" = "US" 
	"00000424" = "YU" 
	"00000425" = "ET" 
	"00000426" = "US" 
	"00000427" = "US" 
	"00000804" = "CH" 
	"00000809" = "UK" 
	"0000080A" = "LA" 
	"0000080C" = "BE" 
	"00000813" = "BE" 
	"00000816" = "PO" 
	"00000C0C" = "CF" 
	"00000C1A" = "US" 
	"00001009" = "US" 
	"0000100C" = "SF" 
	"00001809" = "US" 
	"00010402" = "US" 
	"00010405" = "CZ" 
	"00010407" = "GR" 
	"00010408" = "GK" 
	"00010409" = "DV" 
	"0001040A" = "SP" 
	"0001040E" = "HU" 
	"00010410" = "IT" 
	"00010415" = "PL" 
	"00010419" = "RU" 
	"0001041B" = "SL" 
	"0001041F" = "TR" 
	"00010426" = "US" 
	"00010C0C" = "CF" 
	"00010C1A" = "US" 
	"00020408" = "GK" 
	"00020409" = "US" 
	"00030409" = "USL" 
	"00040409" = "USR" 
	"00050408" = "GK" 
	}
	$output.keymap = $keyboardmap.$($ObjKeyboards.Layout)
	if (!$output.keymap)
	{ $keyb = "Unknown"
	}

	#  Supported Keymaps
	$KeyMapSupported = @{
	"00000409" = "US" 
	"0000040C" = "FR" 
	"00000411" = "JP" 
	"0000041C" = "US" 
	"00000422" = "US" 
	"00000423" = "US" 
	"00000426" = "US" 
	"00000427" = "US" 
	"00000804" = "CH" 
	"00000809" = "UK" 
	"00000C1A" = "US" 
	"00001009" = "US" 
	"00001809" = "US" 
	"00010402" = "US" 
	"00010426" = "US" 
	"00010C1A" = "US" 
	"00020409" = "US" 
	}
	$supported = $KeyMapSupported.$($ObjKeyboards.Layout)
	if (!$output.keymap) { 
		$output.KeyMapSupported = $false
	} else {
		$output.KeyMapSupported = $true
	}
	
	New-Object -TypeName PSObject -Property $output
	return $output
}

function Get-RegionLoginKbValid {
	$path = "Microsoft.PowerShell.Core\Registry::HKEY_USERS\.Default\Keyboard Layout\preload"
	$keyboardmap = @{
	"00000409" = "US" 
	"0000041C" = "US" 
	"00000422" = "US" 
	"00000423" = "US" 
	"00000426" = "US" 
	"00000427" = "US" 
	"00000C1A" = "US" 
	"00001009" = "US"
	#"00000809" = "UK"
	"00001809" = "US" 
	"00010402" = "US" 
	"00010426" = "US" 
	"00010C1A" = "US" 
	"00020409" = "US" 
	}
	$output = $keyboardmap.$((Get-ItemProperty -Path $path -Name 1)."1")
	if (!($output)) {
		return $false
	}
	return $true
}

function Get-RegionLoginScreenValid {
	$path = "Microsoft.PowerShell.Core\Registry::HKEY_USERS\.Default\Control Panel\International"
	if ((Get-ItemProperty -Path $path -Name sLanguage).sLanguage -notcontains 'ENU') {
		return $false
	}
	return $true
}

function Get-PhyMemoryConf {
param (
	[string]$TargetServer = [Environment]::MachineName
)
	#
	#	Get RAM Configuration
	#
	$output = @{}
	$MemoryInterleaving = @{0="Non-Interleaved";1="First Position";2="Second Position"}
	$MemoryPackage = @{0="Unknown";1="Other";2="SiP";3="DIP";4="ZIP";5="SOJ";6="Proprietary";7="SIMM";8="DIMM";9="TSOPO";10="PGA";11="RIM";12="SODIMM";13="SRIMM";14="SMD";15="SSMP";16="QFP";17="TQFP";18="SOIC";19="LCC";20="PLCC";21="FPGA";22="LGA"}
	$MemoryType = @{0="Unknown";1="Other";2="DRAM";3="SDRAM";4="Cache DRAM";5="EDO";6="EDRAM";7="VRAM";8="SRAM";9="ROM";10="ROM";11="FLASH";12="EEPROM";13="FEPROM";14="EPROM";15="CDRAM";16="3DRAM";17="SDRAM";18="SGRAM";19="RDRAM"; 20="DDR";21="DDR2";22="DDR3";}
	$tmp = (Get-WmiObject -Computer $TargetServer Win32_PhysicalMemory | Select BankLabel,Capacity,DataWidth,DeviceLocator,MemoryType,FormFactor,HotSwappable,PartNumber,Speed,InterleavePosition)
	
	$ComputerSystem = (Get-WmiObject -ComputerName $TargetServer Win32_OperatingSystem | Select FreePhysicalMemory,TotalPhysicalMemory,TotalVisibleMemorySize,TotalVirtualMemorySize,MaxProcessMemorySize,FreeVirtualMemory,PAEEnabled)
	#$colMemoryCounters = (Get-Counter -ListSet memory -ComputerName $TargetServer).paths  | Where {$_ -like "*available*"}
	$output.MemoryTotal = [int]([Math]::Round(($ComputerSystem.TotalVisibleMemorySize/1KB),2))
	$output.MemoryFree = [int]([Math]::Round($ComputerSystem.FreePhysicalMemory,2)/1024)
	New-Object -TypeName PSObject -Property $output
	#####
}

<#	
	#
	#	Get System Configuration
	#
	$DepLevels= @{ 0="Disabled"; 1="Opt-In"; 2="Opt-Out"; 3="Always On" }
	$colSessionMemory = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" | select  DisablePagingExecutive, LargeSystemCache, MoveImages
	$colSessionFilesystem =  Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" | select  NtfsDisable8dot3NameCreation,NtfsDisableLastAccessUpdate,NtfsMemoryUsage,NtfsMftZoneReservation,NtfsDisableCompression,NtfsDisableEncryption
	$colSessionSecurity =  Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel\" | select DisableExceptionChainValidation
	$colSessionDEP = Get-WmiObject Win32_OperatingSystem | select DataExecutionPrevention_Available, DataExecutionPrevention_SupportPolicy
	
	Write-Debug "[Debug]: $MemoryTotal / $MemoryFree / $MemoryFreePerc" 
	#####
	
	$output = @{}
	
	New-Object  -TypeName PSObject -Property $output
}
#>

function Get-WindowsVersionInfo {
	param (
		[string]$TargetServer = [Environment]::MachineName
	)
	
	$output = @{}
	$tmp = Get-WmiObject -ComputerName $TargetServer Win32_OperatingSystem | Select BuildNumber,Caption,Version,Hostname,ServicePackMajorVersion,FreePhysicalMemory
	[int]$output.BuildNumber = $tmp.BuildNumber
	[string]$output.Caption = $tmp.Caption
	[string]$output.Version = $tmp.Version
	[string]$output.Hostname = $tmp.Hostname
	[int]$output.ServicePackMajorVersion = $tmp.ServicePackMajorVersion
	[int]$output.FreePhysicalMemory = ($tmp.FreePhysicalMemory)/1KB

	$ComputerSystem = Get-WmiObject -ComputerName $TargetServer Win32_ComputerSystem

	switch ($ComputerSystem.DomainRole){
		0 { $output.ComputerRole = "Standalone Workstation" }
		1 { $output.ComputerRole = "Member Workstation" }
		2 { $output.ComputerRole = "Standalone Server" }
		3 { $output.ComputerRole = "Member Server" }
		4 { $output.ComputerRole = "Domain Controller" }
		5 { $output.ComputerRole = "Domain Controller" }
		default { $output.ComputerRole = "Information not available" }
	}
		
	switch ($output.ComputerRole){
		"Member Workstation" { $output.CompType = "Computer Domain"; break }
		"Domain Controller" { $output.CompType = "Computer Domain"; break }
		"Member Server" { $output.CompType = "Computer Domain"; break }
		default { $output.CompType = "Computer Workgroup"; break }
	}

	$OperatingSystem = Get-WmiObject -Computername $TargetServer Win32_OperatingSystem
	$output.KernelStartTime = $OperatingSystem.ConvertToDateTime($OperatingSystem.Lastbootuptime)
	
	New-Object -TypeName PSObject -Property $output
}

function Get-MaxServicePack {
	param (
		[string]$versionString
	)
	($versionString -match '\d\.\d')

	switch ($matches[0]) {
		"6.3" { return 0 }
		"6.2" { return 1 }
		"6.1" { return 2 }
		"6.0" { return 2 }
		"5.2" { return 2 }
		default { return -1 }
	}
}

#
# http://blogs.technet.com/b/jamesone/archive/2009/01/31/checking-and-enabling-remote-desktop-with-powershell.aspx
#
function Get-RemoteDesktopConfig {
	if ((Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server').fDenyTSConnections -eq 1) {
		return "NONE"
	} elseif ((Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp').UserAuthentication -eq 1) {
 		return "SECURE"
	} else {
		return "ALL"
 	}
}


#
#  Utilize winsat too test drive throughput
#
function Get-DiskThroughPut {
	param (
		[string]$TargetDrive = $env:SystemDrive		# Default to Windows System Drive
	)
	$output = @{}
	if ((winsat disk -drive -read -seq $(($TargetDrive).Trim(":\")) | Select-String "MB/s") -match '\d*\.\d*\sMB\/s') {
		[float]$output.ReadSequential = (($matches[0]).Trim(" MB/s"))
	}
	
	if ((winsat disk -drive -read -ran $(($TargetDrive).Trim(":\")) | Select-String "MB/s") -match '\d*\.\d*\sMB\/s') {
		[float]$output.ReadRandom = (($matches[0]).Trim(" MB/s"))
	}
	
	if ((winsat disk -drive -write -seq $(($TargetDrive).Trim(":\")) | Select-String "MB/s") -match '\d*\.\d*\sMB\/s') {
		[float]$output.WriteSequential = (($matches[0]).Trim(" MB/s"))
	}
	
	if ((winsat disk -drive -write -ran $(($TargetDrive).Trim(":\")) | Select-String "MB/s") -match '\d*\.\d*\sMB\/s') {
		[float]$output.WriteRandom = (($matches[0]).Trim(" MB/s"))
	}
	New-Object -TypeName PSObject -Property $output
	#####
}

function Get-FixedDisks {
	[System.IO.DriveInfo]::getdrives() | Where { $_.DriveType -eq 'Fixed'} #| Format-Table RootDirectory,VolumeLabel,DriveType,DriveFormat,AvailableFreeSpace,TotalFreeSpace,TotalSize
}

function Get-AllDisksSpeed {
	$testResults = @{}
	ForEach ($fixedDisk in (Get-FixedDisks | Select-Object -Property Name)) {
		$testResults.Set_Item("$(($fixedDisk.Name).Trim(':\'))", (Get-DiskThroughPut -TargetDrive $fixedDisk.Name))
	}
	return $testResults
}

# (18 Oct 2018 - RayD) Add check for .NET version
function Get-DotNetFrameworkVersion {
<#
   	.Synopsis
    Get latest installed .NET version
   	.Description
	Returns latest installed .NET framework version
   	.Example
	Get-DotNetFrameworkVersion
	.Link
#>
	param (
	)
	Process {
		$latestdotnetversion = (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse | 
			Get-ItemProperty -name Version,Release -EA 0 | Where { $_.PSChildName -match '^(?![SW])\p{L}'} | 
			Select Version | Measure-Object -property Version -Maximum).Maximum
		return $latestdotnetversion
	}
}

# (9 Nov 2018 - RayD) Return list of all installed .NET versions
function Get-AllDotNetFrameworkVersions {
<#
   	.Synopsis
    Get all installed .NET versions
   	.Description
	Returns all installed .NET framework version in a comma-separated llist
   	.Example
	Get-AllDotNetFrameworkVersions
	.Link
#>
	param (
	)
	Process {
		$latestdotnetversion = (Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse | 
			Get-ItemProperty -name Version,Release -EA 0 | Where { $_.PSChildName -match '^(?![SW])\p{L}'} | 
			Select -ExpandProperty Version) -join "," 
		return $latestdotnetversion
	}
}

# (18 Oct 2018 - RayD) Add check for previous use of service account
function Get-ServiceAccountPreviouslyUsed {
<#
   	.Synopsis
    Check for traces of previous use of the service account for a Trellis install
   	.Description
	Returns true or false whether the service account was used for the Trellis install
   	.Example
	Get-ServiceAccountPreviouslyUsed
	.Link
#>
	param (
	)
	Process {
		$testfile = $env:userprofile + "\TrellisScripts.zip"
		return Test-Path $testfile
	}
}