#---------------------------------------------------------------------------------------------
# Script Name: ConfigurationHandler
# Created: 2015/11/07
# Author: Scott Donaldson [NETPWR/AVOCENT/UK]
# Company: Emerson Network Power
# Group: Professional Services
# Email:scott.donaldson@emerson.com
#---------------------------------------------------------------------------------------------

# (6 Nov 2018 - RayD) Update function for 5.0 versions
function Get-SizeTrellisInstance {
	<#
	   	.Synopsis
	   	.Description
	   	.Example
	    Get-RunTest
	    .Parameter TargetServer
		The server name to run checks against, default is the running system.
		.Parameter TestGroup
		.Parameter TestItem
		.Link
	   		https://www.emersonnetworkpower.com
	#>
	param (
		[Switch]$UseStaticOverride,							# Use hard-coded values
		[String]$sizeDescription = "Small",
		[int]$TrellisMaj = -1,								# Search test group
		[int]$TrellisMin = -1								# Search test item
	)
	
	$TrellisMaxMaj = 5

	$sizeTrellis = @{}
	#
	#  Trellis 3.0 - 3.3
	#
	$sizeTrellis["T3_0"] = @{}
	$sizeTrellis["T3_0"]["Enterprise"] = @{ "FRONT_RAM" = "45056"; "BACK_RAM" = "45056"; "FRONT_CORES" = "16"; "BACK_CORES" = "16"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T3_0"]["Large"] = @{ "FRONT_RAM" = "40960"; "BACK_RAM" = "40960"; "FRONT_CORES" = "8"; "BACK_CORES" = "8"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T3_0"]["Medium"] = @{ "FRONT_RAM" = "32768"; "BACK_RAM" = "32768"; "FRONT_CORES" = "8"; "BACK_CORES" = "8"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T3_0"]["Small"] = @{ "FRONT_RAM" = "32768"; "BACK_RAM" = "24576"; "FRONT_CORES" = "4"; "BACK_CORES" = "4"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T3_0"]["Development"] = @{ "FRONT_RAM" = "24576"; "BACK_RAM" = "24576"; "FRONT_CORES" = "4"; "BACK_CORES" = "4"; "CPU_FREQ" = "2200"};
	
	#
	#  Trellis 3.4
	#
	$sizeTrellis["T3_4"] = @{}
	$sizeTrellis["T3_4"]["Enterprise"] = @{ "FRONT_RAM" = "45056"; "BACK_RAM" = "45056"; "FRONT_CORES" = "16"; "BACK_CORES" = "16"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T3_4"]["Large"] = @{ "FRONT_RAM" = "40960"; "BACK_RAM" = "40960"; "FRONT_CORES" = "8"; "BACK_CORES" = "8"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T3_4"]["Medium"] = @{ "FRONT_RAM" = "32768"; "BACK_RAM" = "32768"; "FRONT_CORES" = "8"; "BACK_CORES" = "8"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T3_4"]["Small"] = @{ "FRONT_RAM" = "32768"; "BACK_RAM" = "32768"; "FRONT_CORES" = "4"; "BACK_CORES" = "4"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T3_4"]["Development"] = @{ "FRONT_RAM" = "24576"; "BACK_RAM" = "24576"; "FRONT_CORES" = "4"; "BACK_CORES" = "4"; "CPU_FREQ" = "2200"};
	#####
	
	#
	#  Trellis 4.0
	#
	$sizeTrellis["T4_0"] = @{}
	$sizeTrellis["T4_0"]["Enterprise"] = @{ "FRONT_RAM" = "45056"; "BACK_RAM" = "45056"; "FRONT_CORES" = "16"; "BACK_CORES" = "16"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T4_0"]["Large"] = @{ "FRONT_RAM" = "40960"; "BACK_RAM" = "40960"; "FRONT_CORES" = "8"; "BACK_CORES" = "8"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T4_0"]["Medium"] = @{ "FRONT_RAM" = "32768"; "BACK_RAM" = "32768"; "FRONT_CORES" = "8"; "BACK_CORES" = "8"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T4_0"]["Small"] = @{ "FRONT_RAM" = "32768"; "BACK_RAM" = "24576"; "FRONT_CORES" = "4"; "BACK_CORES" = "4"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T4_0"]["Development"] = @{ "FRONT_RAM" = "32768"; "BACK_RAM" = "24576"; "FRONT_CORES" = "4"; "BACK_CORES" = "4"; "CPU_FREQ" = "2200"};
	#####	

	#
	#  Trellis 5.0
	#
	$sizeTrellis["T5_0"] = @{}
	$sizeTrellis["T5_0"]["Enterprise"] = @{ "FRONT_RAM" = "45056"; "BACK_RAM" = "45056"; "FRONT_CORES" = "16"; "BACK_CORES" = "16"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T5_0"]["Large"] = @{ "FRONT_RAM" = "40960"; "BACK_RAM" = "40960"; "FRONT_CORES" = "8"; "BACK_CORES" = "8"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T5_0"]["Medium"] = @{ "FRONT_RAM" = "32768"; "BACK_RAM" = "32768"; "FRONT_CORES" = "8"; "BACK_CORES" = "8"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T5_0"]["Small"] = @{ "FRONT_RAM" = "32768"; "BACK_RAM" = "24576"; "FRONT_CORES" = "4"; "BACK_CORES" = "4"; "CPU_FREQ" = "2200"};
	$sizeTrellis["T5_0"]["Development"] = @{ "FRONT_RAM" = "32768"; "BACK_RAM" = "24576"; "FRONT_CORES" = "4"; "BACK_CORES" = "4"; "CPU_FREQ" = "2200"};
	#####	
	
	$mapTrellisReq = @{
		"3.0"	=	"T3_0";
		"3.1"	=	"T3_0";
		"3.2"	=	"T3_0";
		"3.3"	=	"T3_0";
		"3.4"	=	"T3_4";
		"3.5"	=	"T3_4";
		"3.6"	=	"T3_4";
		"3.7"	=	"T3_4";
		"3.8"	=	"T3_4";
		"3.9"	=	"T3_4";
		"4.0"	=	"T4_0";
		"4.1"	=	"T4_1";
		"5.0"	=	"T5_0"
	}
	
	if (($TrellisMaj -gt 0) -and ($TrellisMin -ge 0)) {
	
		if (($TrellisMaj -ge 3) -and ($TrellisMaj -le $TrellisMaxMaj)) {
			$tmpVer = "{0}.{1}" -f $TrellisMaj,$TrellisMin
			if ($mapTrellisReq.Contains("$tmpVer")) {
				if ($sizeTrellis.($mapTrellisReq.Item("$tmpVer")).ContainsKey("$sizeDescription")) {
					Write-Output $sizeDescription
					return ($sizeTrellis.($mapTrellisReq.Item("$tmpVer")).$sizeDescription)
				} else {
					return $null
					#return ($sizeTrellis.($mapTrellisReq.Item("$tmpVer")).Small)
				}
			} else {
				Write-Output "Out of range"
				return $false
			}
		}
		else {
			Write-Output "Out of range"
			return $null
		}
	
	}
	return $null
}

#---------------------------------------------------------------------------------------------
#
#---------------------------------------------------------------------------------------------
function Get-RunTest {
	<#
	   	.Synopsis
	   	.Description
	   	.Example
	    Get-RunTest
	    .Parameter TargetServer
		The server name to run checks against, default is the running system.
		.Parameter TestGroup
		.Parameter TestItem
		.Link
	   		https://www.emersonnetworkpower.com
	#>
	param (
	    [string[]]$TargetServer = [Environment]::MachineName,	# Server name
	    [string[]]$UserName = [Environment]::UserName,			# Username only
		[string[]]$DomainName = [Environment]::UserDomainName,	# Domain name only
		[Switch]$UseStaticOverride,								# Use hard-coded values
		[String[]]$Platform = "Windows",						# Check if suitable for operating system
		[String[]]$PlatformVersion = $null,						# Check if suitable for operating system version
		[int]$TestGroup = -1,								# Search test group
		[int]$TestNumber = -1								# Search test item
	)

	#
	#  Statically defined, will be replaced by dynamically loaded XML
	#
	$cfgPlatforms = @{
		"RHEL5" 	= "Linux";
		"RHEL6" 	= "Linux";
		"RHEL7" 	= "Linux";
		"OEL5" 		= "Linux";
		"OEL6" 		= "Linux";
		"OEL7" 		= "Linux";		
		"WIN2008R2" = "Windows";
		"WIN2012"	= "Windows";
		"WIN2012R2"	= "Windows";
	}
	#####

	#
	#  Statically defined, will be replaced by dynamically loaded XML
	#
	$cfgWindowsVersions = @{
	"WIN10" = "10.0";
	"WIN2016" = "10.0";
	"WIN81" = "6.3";
	"WIN2012R2" = "6.3";
 	"WIN8" = "6.2";
	"WIN2012" = "6.2";
	"WIN7" = "6.1";
	"WIN2008R2" = "6.1";
	"WIN2008" = "6.0";
	"WINVIST" = "6.0";
	"WIN2003R2" = "5.2";
	"WIN2003" = "5.2";
	"WINXP64" = "5.2";
	"WINXP" = "5.1";
	"WIN2000" = "5.1"
	}
	#####
	
	#
	#  Statically defined, will be replaced by dynamically loaded XML
	#
	$cfgTestMatrixStatic = @{}
	
	#####  REQ 1.0 - OS Checks (Group)
	$cfgTestMatrixStatic["T1_0"] = @{}
	$cfgTestMatrixStatic["T1_0"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T1_0"]["Linux"] = $true;
	$cfgTestMatrixStatic["T1_0"]["Windows"] = $true;
	$cfgTestMatrixStatic["T1_0"]["Description"] = "Windows Checks (Group)"
	
	$cfgTestMatrixStatic["T1_1"] = @{}
	$cfgTestMatrixStatic["T1_1"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T1_1"]["Linux"] = $true;
# (18 Oct 2018 - RayD) Remove check, since it duplicates the Engineering Precheck script
	$cfgTestMatrixStatic["T1_1"]["Windows"] = $false;
	$cfgTestMatrixStatic["T1_1"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T1_1"]["Description"] = "Example"
	
	$cfgTestMatrixStatic["T1_2"] = @{}
	$cfgTestMatrixStatic["T1_2"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T1_2"]["Linux"] = $true;
	$cfgTestMatrixStatic["T1_2"]["Windows"] = $true;
	$cfgTestMatrixStatic["T1_2"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T1_2"]["Description"] = "Installation Folders"
	
	$cfgTestMatrixStatic["T1_3"] = @{}
	$cfgTestMatrixStatic["T1_3"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T1_3"]["Linux"] = $true;
	$cfgTestMatrixStatic["T1_3"]["Windows"] = $false;
	$cfgTestMatrixStatic["T1_3"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T1_3"]["Description"] = "pending"	

	$cfgTestMatrixStatic["T1_4"] = @{}
	$cfgTestMatrixStatic["T1_4"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T1_4"]["Linux"] = $true;
	$cfgTestMatrixStatic["T1_4"]["Windows"] = $false;
	$cfgTestMatrixStatic["T1_4"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T1_4"]["Description"] = "pending"	
	
	$cfgTestMatrixStatic["T1_5"] = @{}
	$cfgTestMatrixStatic["T1_5"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T1_5"]["Linux"] = $false;
	$cfgTestMatrixStatic["T1_5"]["Windows"] = $true;
	$cfgTestMatrixStatic["T1_5"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T1_5"]["Description"] = "A dedicated service account and is member of local administrators"
	
	$cfgTestMatrixStatic["T1_6"] = @{}
	$cfgTestMatrixStatic["T1_6"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T1_6"]["Linux"] = $false;
	$cfgTestMatrixStatic["T1_6"]["Windows"] = $true;
	$cfgTestMatrixStatic["T1_6"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T1_6"]["Description"] = "Remote Desktop Enabled"
	
	$cfgTestMatrixStatic["T1_7"] = @{}
	$cfgTestMatrixStatic["T1_7"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T1_7"]["Linux"] = $false;
	$cfgTestMatrixStatic["T1_7"]["Windows"] = $true;
	$cfgTestMatrixStatic["T1_7"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T1_7"]["Description"] = "Language & Region English US"	
	
	$cfgTestMatrixStatic["T1_8"] = @{}
	$cfgTestMatrixStatic["T1_8"]["Linux"] = $false;
	$cfgTestMatrixStatic["T1_8"]["Windows"] = $true;
	$cfgTestMatrixStatic["T1_8"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T1_8"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T1_8"]["Description"] = "Login Language & Region English US"	

# (18 Oct 2018 - RayD) Add check for .NET Framework	
	$cfgTestMatrixStatic["T1_9"] = @{}
	$cfgTestMatrixStatic["T1_9"]["Linux"] = $false;
	$cfgTestMatrixStatic["T1_9"]["Windows"] = $true;
	$cfgTestMatrixStatic["T1_9"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T1_9"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T1_9"]["Description"] = ".NET Framework Version"	

# (18 Oct 2018 - RayD) Add check for 8.3 Filename support
	$cfgTestMatrixStatic["T1_10"] = @{}
	$cfgTestMatrixStatic["T1_10"]["Linux"] = $false;
	$cfgTestMatrixStatic["T1_10"]["Windows"] = $true;
	$cfgTestMatrixStatic["T1_10"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T1_10"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T1_10"]["Description"] = "8.3 Filenames Enabled"	

# (18 Oct 2018 - RayD) Add check for service account previously used
	$cfgTestMatrixStatic["T1_11"] = @{}
	$cfgTestMatrixStatic["T1_11"]["Linux"] = $false;
	$cfgTestMatrixStatic["T1_11"]["Windows"] = $true;
	$cfgTestMatrixStatic["T1_11"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T1_11"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T1_11"]["Description"] = "Previously Used Service Account"	
	#####  REQ 1.0 - OS Checks (Group)
	
	#####  REQ 2.0 - Hardware Checks (Group)
	$cfgTestMatrixStatic["T2_0"] = @{}
	$cfgTestMatrixStatic["T2_0"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T2_0"]["Linux"] = $true;
	$cfgTestMatrixStatic["T2_0"]["Windows"] = $true;
	$cfgTestMatrixStatic["T2_0"]["Description"] = "Hardware Checks (Group)"	

	$cfgTestMatrixStatic["T2_1"] = @{}
	$cfgTestMatrixStatic["T2_1"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T2_1"]["Linux"] = $true;
	$cfgTestMatrixStatic["T2_1"]["Windows"] = $true;
	$cfgTestMatrixStatic["T2_1"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T2_1"]["Description"] = "Check CPU Core Count"

	$cfgTestMatrixStatic["T2_2"] = @{}
	$cfgTestMatrixStatic["T2_2"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T2_2"]["Linux"] = $true;
# (18 Oct 2018 - RayD) Remove check, since it duplicates the Engineering Precheck script
	$cfgTestMatrixStatic["T2_2"]["Windows"] = $false;
	$cfgTestMatrixStatic["T2_2"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T2_2"]["Description"] = "Available RAM"	
	
	$cfgTestMatrixStatic["T2_3"] = @{}
	$cfgTestMatrixStatic["T2_3"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T2_3"]["Linux"] = $true;
# (18 Oct 2018 - RayD) Remove check, since it duplicates the Engineering Precheck script
	$cfgTestMatrixStatic["T2_3"]["Windows"] = $false;
	$cfgTestMatrixStatic["T2_3"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T2_3"]["Description"] = "Disk Throughput > 300MB/s"		

	$cfgTestMatrixStatic["T2_4"] = @{}
	$cfgTestMatrixStatic["T2_4"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T2_4"]["Linux"] = $true;
	$cfgTestMatrixStatic["T2_4"]["Windows"] = $true;
	$cfgTestMatrixStatic["T2_4"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T2_4"]["Description"] = "Disk Space Requirements"	
	
	$cfgTestMatrixStatic["T2_5"] = @{}
	$cfgTestMatrixStatic["T2_5"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T2_5"]["Linux"] = $true;
	$cfgTestMatrixStatic["T2_5"]["Windows"] = $true;
	$cfgTestMatrixStatic["T2_5"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T2_5"]["Description"] = "Installation Requires 10GB of Free Space for Installation"	
	
	$cfgTestMatrixStatic["T2_6"] = @{}
	$cfgTestMatrixStatic["T2_6"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T2_6"]["Linux"] = $true;
	$cfgTestMatrixStatic["T2_6"]["Windows"] = $false;
	$cfgTestMatrixStatic["T2_6"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T2_6"]["Description"] = "pending"	
	
	$cfgTestMatrixStatic["T2_7"] = @{}
	$cfgTestMatrixStatic["T2_7"]["Enabled"] = $false;
	$cfgTestMatrixStatic["T2_7"]["Linux"] = $true;
	$cfgTestMatrixStatic["T2_7"]["Windows"] = $true;
	$cfgTestMatrixStatic["T2_7"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T2_7"]["Description"] = "CPU Speed Checks"		
	#####  REQ 2.0 - Hardware Checks (Group)
	
	#####  REQ 3.0 - Virtualization Checks (Group)
	$cfgTestMatrixStatic["T3_0"] = @{}
	$cfgTestMatrixStatic["T3_0"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T3_0"]["Linux"] = $true;
	$cfgTestMatrixStatic["T3_0"]["Windows"] = $true;
	$cfgTestMatrixStatic["T3_0"]["Description"] = "Virtualizations Checks (Group)"
	
	$cfgTestMatrixStatic["T3_1"] = @{}
	$cfgTestMatrixStatic["T3_1"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T3_1"]["Linux"] = $true;
	$cfgTestMatrixStatic["T3_1"]["Windows"] = $true;
	$cfgTestMatrixStatic["T3_1"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T3_1"]["Description"] = "Verify Guest Additions Installed"		
	
	$cfgTestMatrixStatic["T3_2"] = @{}
	$cfgTestMatrixStatic["T3_2"]["Enabled"] = $false;
	$cfgTestMatrixStatic["T3_2"]["Linux"] = $true;
	$cfgTestMatrixStatic["T3_2"]["Windows"] = $true;
	$cfgTestMatrixStatic["T3_2"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T3_2"]["Description"] = "Check for CPU frequency throttling"	
	#####  REQ 3.0 - Virtualization Checks (Group)
	
	#####  REQ 4.0 - Security Checks (Group)
	$cfgTestMatrixStatic["T4_0"] = @{}
	$cfgTestMatrixStatic["T4_0"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T4_0"]["Linux"] = $true;
	$cfgTestMatrixStatic["T4_0"]["Windows"] = $true;
	$cfgTestMatrixStatic["T4_0"]["Description"] = "Security Checks (Group)"
	
	$cfgTestMatrixStatic["T4_1"] = @{}
	$cfgTestMatrixStatic["T4_1"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T4_1"]["Linux"] = $true;
	$cfgTestMatrixStatic["T4_1"]["Windows"] = $true;
	$cfgTestMatrixStatic["T4_1"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T4_1"]["Description"] = "Confirm Anti-Virus Disabled"		
	
	$cfgTestMatrixStatic["T4_2"] = @{}
	$cfgTestMatrixStatic["T4_2"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T4_2"]["Linux"] = $true;
	$cfgTestMatrixStatic["T4_2"]["Windows"] = $true;
	$cfgTestMatrixStatic["T4_2"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T4_2"]["Description"] = "Confirm Firewall Disabled"	

	$cfgTestMatrixStatic["T4_3"] = @{}
	$cfgTestMatrixStatic["T4_3"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T4_3"]["Linux"] = $true;
	$cfgTestMatrixStatic["T4_3"]["Windows"] = $false;
	$cfgTestMatrixStatic["T4_3"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T4_3"]["Description"] = "pending"	

	$cfgTestMatrixStatic["T4_4"] = @{}
	$cfgTestMatrixStatic["T4_4"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T4_4"]["Linux"] = $true;
	$cfgTestMatrixStatic["T4_4"]["Windows"] = $true;
	$cfgTestMatrixStatic["T4_4"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T4_4"]["Description"] = "Compatible Anti-Virus Present"	
	
	$cfgTestMatrixStatic["T4_5"] = @{}
	$cfgTestMatrixStatic["T4_5"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T4_5"]["Linux"] = $true;
	$cfgTestMatrixStatic["T4_5"]["Windows"] = $false;
	$cfgTestMatrixStatic["T4_5"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T4_5"]["Description"] = "pending"	
	
	$cfgTestMatrixStatic["T4_6"] = @{}
	$cfgTestMatrixStatic["T4_6"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T4_6"]["Linux"] = $false;
	$cfgTestMatrixStatic["T4_6"]["Windows"] = $true;
	$cfgTestMatrixStatic["T4_6"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T4_6"]["Description"] = "UAC is enabled for logged in user"	

	$cfgTestMatrixStatic["T4_7"] = @{}
	$cfgTestMatrixStatic["T4_7"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T4_7"]["Linux"] = $false;
	$cfgTestMatrixStatic["T4_7"]["Windows"] = $true;
	$cfgTestMatrixStatic["T4_7"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T4_7"]["Description"] = "UAC Group Policy"
	
	$cfgTestMatrixStatic["T4_8"] = @{}
	$cfgTestMatrixStatic["T4_8"]["Enabled"] = $false;
	$cfgTestMatrixStatic["T4_8"]["Linux"] = $false;
	$cfgTestMatrixStatic["T4_8"]["Windows"] = $true;
	$cfgTestMatrixStatic["T4_8"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T4_8"]["Description"] = "Lock Pages in Memory"	
	#####  REQ 4.0 - Security Checks (Group)

	#####  REQ 5.0 - Network Checks (Group)
	$cfgTestMatrixStatic["T5_0"] = @{}
	$cfgTestMatrixStatic["T5_0"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T5_0"]["Linux"] = $true;
	$cfgTestMatrixStatic["T5_0"]["Windows"] = $true;
	$cfgTestMatrixStatic["T5_0"]["Description"] = "Network Checks (Group)"
	
	$cfgTestMatrixStatic["T5_1"] = @{}
	$cfgTestMatrixStatic["T5_1"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T5_1"]["Linux"] = $true;
	$cfgTestMatrixStatic["T5_1"]["Windows"] = $true;
	$cfgTestMatrixStatic["T5_1"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_1"]["Description"] = "Confirm Only One NIC Enabled"		

	$cfgTestMatrixStatic["T5_2"] = @{}
	$cfgTestMatrixStatic["T5_2"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T5_2"]["Linux"] = $true;
	$cfgTestMatrixStatic["T5_2"]["Windows"] = $true;
	$cfgTestMatrixStatic["T5_2"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_2"]["Description"] = "Confirm DHCP Client not Enabled"	

	$cfgTestMatrixStatic["T5_3"] = @{}
	$cfgTestMatrixStatic["T5_3"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T5_3"]["Linux"] = $true;
	$cfgTestMatrixStatic["T5_3"]["Windows"] = $false;
	$cfgTestMatrixStatic["T5_3"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_3"]["Description"] = "DNS Entry Validations"	

	$cfgTestMatrixStatic["T5_4"] = @{}
	$cfgTestMatrixStatic["T5_4"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T5_4"]["Linux"] = $true;
	$cfgTestMatrixStatic["T5_4"]["Windows"] = $false;
	$cfgTestMatrixStatic["T5_4"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_4"]["Description"] = "pending"	
	
	$cfgTestMatrixStatic["T5_5"] = @{}
	$cfgTestMatrixStatic["T5_5"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T5_5"]["Linux"] = $false;
	$cfgTestMatrixStatic["T5_5"]["Windows"] = $true;
	$cfgTestMatrixStatic["T5_5"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_5"]["Description"] = "Confirm Length of Hostname <= Netbios"	
	
	$cfgTestMatrixStatic["T5_51"] = @{}
	$cfgTestMatrixStatic["T5_51"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T5_51"]["Linux"] = $true;
# (18 Oct 2018 - RayD) Remove check, since it duplicates the Engineering Precheck script
	$cfgTestMatrixStatic["T5_51"]["Windows"] = $false;
	$cfgTestMatrixStatic["T5_51"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_51"]["Description"] = "Connectivity Validations"	
	
	$cfgTestMatrixStatic["T5_52"] = @{}
	$cfgTestMatrixStatic["T5_52"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T5_52"]["Linux"] = $true;
# (18 Oct 2018 - RayD) Remove check, since it duplicates the Engineering Precheck script
	$cfgTestMatrixStatic["T5_52"]["Windows"] = $false;
	$cfgTestMatrixStatic["T5_52"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_52"]["Description"] = "Connectivity Validations"

# (13 Nov 2018 - RayD) Since the code for the 5.7 test was commented out, and the 5.8 test only contains the current time zone and no test, and since the current zone and server are already printed in the Summary, skip 5.7/5.8
	$cfgTestMatrixStatic["T5_7"] = @{}
	$cfgTestMatrixStatic["T5_7"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T5_7"]["Linux"] = $true;
	$cfgTestMatrixStatic["T5_7"]["Windows"] = $false;
	$cfgTestMatrixStatic["T5_7"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_7"]["Description"] = "Front & Back Time Zones Match"
	
	$cfgTestMatrixStatic["T5_8"] = @{}
	$cfgTestMatrixStatic["T5_8"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T5_8"]["Linux"] = $true;
	$cfgTestMatrixStatic["T5_8"]["Windows"] = $false;
	$cfgTestMatrixStatic["T5_8"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_8"]["Description"] = "Front & Back Time Servers Match"	
	
	$cfgTestMatrixStatic["T5_9"] = @{}
	$cfgTestMatrixStatic["T5_9"]["Enabled"] = $false;
	$cfgTestMatrixStatic["T5_9"]["Linux"] = $false;
	$cfgTestMatrixStatic["T5_9"]["Windows"] = $true;
	$cfgTestMatrixStatic["T5_9"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_9"]["Description"] = "Verify Simple TCP/IP Feature"	

	$cfgTestMatrixStatic["T5_10"] = @{}
	$cfgTestMatrixStatic["T5_10"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T5_10"]["Linux"] = $true;
	$cfgTestMatrixStatic["T5_10"]["Windows"] = $true;
	$cfgTestMatrixStatic["T5_10"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_10"]["Description"] = "Ports free"	
	$cfgTestMatrixStatic["T5_10"]["Params"] = @{ "PORTS" = "80,443" }
	
	$cfgTestMatrixStatic["T5_11"] = @{}
	$cfgTestMatrixStatic["T5_11"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T5_11"]["Linux"] = $true;
	$cfgTestMatrixStatic["T5_11"]["Windows"] = $true;
	$cfgTestMatrixStatic["T5_11"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_11"]["Description"] = "Verify IIS Not Running"
	
	$cfgTestMatrixStatic["T5_12"] = @{}
	$cfgTestMatrixStatic["T5_12"]["Enabled"] = $false;
	$cfgTestMatrixStatic["T5_12"]["Linux"] = $true;
	$cfgTestMatrixStatic["T5_12"]["Windows"] = $true;
	$cfgTestMatrixStatic["T5_12"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_12"]["Description"] = "Verify DNS Server"
	
	$cfgTestMatrixStatic["T5_13"] = @{}
	$cfgTestMatrixStatic["T5_13"]["Enabled"] = $false;
	$cfgTestMatrixStatic["T5_13"]["Linux"] = $true;
	$cfgTestMatrixStatic["T5_13"]["Windows"] = $true;
	$cfgTestMatrixStatic["T5_13"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_13"]["Description"] = "Verify SMTP Server"
	
	$cfgTestMatrixStatic["T5_14"] = @{}
	$cfgTestMatrixStatic["T5_14"]["Enabled"] = $false;
	$cfgTestMatrixStatic["T5_14"]["Linux"] = $true;
	$cfgTestMatrixStatic["T5_14"]["Windows"] = $true;
	$cfgTestMatrixStatic["T5_14"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T5_14"]["Description"] = "Verify AD Server"	
	#####  REQ 5.0 - Network Checks (Group)

	#####  REQ 7.0 - Licensing Checks (Group)
	$cfgTestMatrixStatic["T7_0"] = @{}
	$cfgTestMatrixStatic["T7_0"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T7_0"]["Linux"] = $true;
	$cfgTestMatrixStatic["T7_0"]["Windows"] = $true;
	$cfgTestMatrixStatic["T7_0"]["Description"] = "Licensing Checks (Group)"
	
	$cfgTestMatrixStatic["T7_1"] = @{}
	$cfgTestMatrixStatic["T7_1"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T7_1"]["Linux"] = $true;
	$cfgTestMatrixStatic["T7_1"]["Windows"] = $true;
	$cfgTestMatrixStatic["T7_1"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T7_1"]["Description"] = "Oracle CPU Core Count"
	#####  REQ 7.0 - Licensing Checks (Group)
	
	#####  REQ 10.0 - Support Software (Group)
	$cfgTestMatrixStatic["T10_0"] = @{}
	$cfgTestMatrixStatic["T10_0"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T10_0"]["Linux"] = $true;
	$cfgTestMatrixStatic["T10_0"]["Windows"] = $true;
	$cfgTestMatrixStatic["T10_0"]["Description"] = "Support Software (Group)"
	
	$cfgTestMatrixStatic["T10_1"] = @{}
	$cfgTestMatrixStatic["T10_1"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T10_1"]["Linux"] = $true;
	$cfgTestMatrixStatic["T10_1"]["Windows"] = $true;
	$cfgTestMatrixStatic["T10_1"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T10_1"]["Description"] = "Sysinternals Tools"
	
	$cfgTestMatrixStatic["T10_2"] = @{}
	$cfgTestMatrixStatic["T10_2"]["Enabled"] = $false;
	$cfgTestMatrixStatic["T10_2"]["Linux"] = $true;
	$cfgTestMatrixStatic["T10_2"]["Windows"] = $true;
	$cfgTestMatrixStatic["T10_2"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T10_2"]["Description"] = "Available text editor"	
	
	$cfgTestMatrixStatic["T10_3"] = @{}
	$cfgTestMatrixStatic["T10_3"]["Enabled"] = $false;
	$cfgTestMatrixStatic["T10_3"]["Linux"] = $true;
	$cfgTestMatrixStatic["T10_3"]["Windows"] = $true;
	$cfgTestMatrixStatic["T10_3"]["Platforms"] = @{ "ALL" = $true; }
	$cfgTestMatrixStatic["T10_3"]["Description"] = "SSH client"	
	#####  REQ 10.0 - Support Software (Group)
	
	#####  REQ 99.0 - DEBUG ONLY (Group)
	$cfgTestMatrixStatic["T99_7"] = @{}
	$cfgTestMatrixStatic["T99_7"]["Enabled"] = $true;
	$cfgTestMatrixStatic["T99_7"]["Linux"] = $true;
	$cfgTestMatrixStatic["T99_7"]["Windows"] = $true;
	$cfgTestMatrixStatic["T99_7"]["Platforms"] = @{ "WIN2008" = $true; "WIN2008R2" = $true; "WIN10" = $false; }
	$cfgTestMatrixStatic["T99_7"]["Description"] = "Debug Funciton Logic Only"	
	#####  REQ 99.0 - DEBUG ONLY (Group)

	if ($Platform -eq $null) {
		# Assume we are running on Windows
		$Platform = "Windows";
	}
	
	if ($cfgPlatforms.ContainsValue("$Platform") -ne $true) {
		# Are we running in Pash on Mono?
		Write-Output "[Error]: Unsupported OS."
		return $false
	}

	if ($PlatformVersion -eq $null) {
		# Version string has not been provided, lets read it from the session
		$verRaw = [environment]::OSVersion.Version
		$PlatformVersion = "{0}.{1}" -F $verRaw.Major,$verRaw.Minor
	}
	
	if ($cfgWindowsVersions.ContainsValue("$PlatformVersion") -ne $true) {
		# Version is not recognized return false
		Write-Output "[Error]: Unsupported OS version."
		return $false
	}

	#
	#
	#
	if (($TestGroup -ge 0) -and ($TestNumber -ge 0)) {
		$testIndex = "T{0}_{1}" -f $TestGroup, $TestNumber
	} else {
		Write-Output "[Error]: Negative TestGroup or TestNumber"
		return $null
	}
	
	if ($cfgTestMatrixStatic.ContainsKey("$testIndex")) {
		
		<#
		"Platform {0}" -F $cfgTestMatrixStatic."$testIndex"."$Platform"
		"All version {0}" -f $cfgTestMatrixStatic."$testIndex"."Platforms".ContainsKey("ALL")
		ForEach  ($matchedVersion in ( $cfgWindowsVersions.GetEnumerator() | Where { $_.Value -like "$PlatformVersion" } | Select-Object -Property Name )) {
			"{0} version {1}" -f $matchedVersion.Name, $cfgTestMatrixStatic."$testIndex"."Platforms".ContainsKey("$matchedVersion.Name")
		}
		"This version {0}" -f $cfgTestMatrixStatic."$testIndex"."Platforms".ContainsKey("$PlatformVersion")
		#>
		
		if ($cfgTestMatrixStatic."$testIndex"."Enabled") {
			if ($cfgTestMatrixStatic."$testIndex"."$Platform") {
				if ($TestNumber -eq 0) { return $true } # Drop out early if 0 as these are groups and have no platform parameters
				if (!($cfgTestMatrixStatic."$testIndex"."Platforms".ContainsKey("ALL"))) {
					ForEach  ($matchedVersion in ( $cfgWindowsVersions.GetEnumerator() | Where { $_.Value -like "$PlatformVersion" } | Select-Object -Property Name )) {
						if ($cfgTestMatrixStatic."$testIndex".Platforms.ContainsKey($matchedVersion.Name)) {
							if ($cfgTestMatrixStatic."$testIndex".Platforms.($matchedVersion.Name) -eq $true) { return $true }
						}
					}
					# Fall through to false
					return $false
				}
				# Fall through to true
				return $true
			}
			# Fall through to false
			return $false
		} 
		# Fall through to false as Test is not enabled
		return $false
	} else {
			return $false
	}

	#####

	return $null
}
#---------------------------------------------------------------------------------------------
