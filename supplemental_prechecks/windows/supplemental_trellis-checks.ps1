#---------------------------------------------------------------------------------------------
#
#      Copyright (c) 2014-2018, Avocent, Vertiv Infrastructure Ltd.
#      All rights reserved.
#
#      Redistribution and use in source and binary forms, with or without
#      modification, are permitted provided that the following conditions are met:
#      1. Redistributions of source code must retain the above copyright
#         notice, this list of conditions and the following disclaimer.
#      2. Redistributions in binary form must reproduce the above copyright
#         notice, this list of conditions and the following disclaimer in the
#         documentation and/or other materials provided with the distribution.
#      3. All advertising materials mentioning features or use of this software
#         must display the following acknowledgement:
#         This product includes software developed by the Emerson Electric Co.
#      4. Neither the name of the Emerson Electric Co. nor the
#         names of its contributors may be used to endorse or promote products
#         derived from this software without specific prior written permission.
#
#      THIS SOFTWARE IS PROVIDED BY VERTIV INFRASTRUCTURE LTD ''AS IS'' AND ANY
#      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#      WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#      DISCLAIMED. IN NO EVENT SHALL VERTIV INFRASTRUCTURE LTD BE LIABLE FOR ANY
#      DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#      (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#      LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#      ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#      SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
# Script Name:		supplemental_trellis-checks.ps1
# Created: 			2014/05/15
# Modified: 		2020/07/02
# Author: 			Scott Donaldson [NETPWR/AVOCENT/UK], Ray Daugherty [NETPWR/AVOCENT/US]
# Contributors: 	Ray Daugherty [NETPWR/AVOCENT/US]
# Maintainers: 		Ray Daugherty [NETPWR/AVOCENT/US], Scott Donaldson [NETPWR/AVOCENT/UK]
# Company: 			Vertiv Infrastructure Ltd.
# Group: 			Software Delivery, Services
# Contact: 			global.services.delivery.development@vertivco.com
#---------------------------------------------------------------------------------------------

<#
   	.Synopsis
    This script detects pre-requisits for Trellis® installation are suitably met.
   	.Description
    This script detects a number of configuration parameters and provides the option
	to ammend the setup ready for Trellis® to be installed.
   	.Example
    Trellis-Prereq
    Generates a report based on the current running user and machine in a plain text
	form against the newest release of Trellis®.
   	.Example
    Trellis-Prereq -FrontServer -DetectOtherServers -OutputMethod html
    .Parameter TargetServers
	The server name to run checks against, default is the running system.
	.Parameter UserName
	The user name to run checks against, default is the running user.
	.Parameter DomainName
	The domain to authenticate against, default is the running user's domain.
	.Parameter FrontServer
	Define this system as the frontend server.
	.Parameter BackServer
	Define this system as the backend server.
	.Parameter DetectOtherServers
	Attempt to identify other frontend/backend servers.
	.Parameter OutputMethod
	Output to plain text, html or xml, the default being text.
	.Parameter OpenOutput
	Launch the report file with the system's default viewer.
	.Parameter DeployTools
	(NOT IMPLEMENTED) Silently install bundled support tools.
	.Parameter SelfUpdate
	(NOT IMPLEMENTED) Fetch latest version of scripts from network.
	.Parameter FetchInstaller
	(NOT IMPLEMENTED) Fetch latest Trellis® installation packages.
	.Link
   		https://www.emersonnetworkpower.com
#>
   
#---------------------------------------------------------------------------------------------
#  Arguments
#---------------------------------------------------------------------------------------------
param (
<#
# Defaults when testing
    [string]$TargetServers = [Environment]::MachineName,	# Comma Seperated List
    [string]$UserName = [Environment]::UserName,			# Username only
	[string]$DomainName = [Environment]::UserDomainName,	# Domain name only
	[switch]$AllChecks = $false,							# Perform all possible checks
	[switch]$SilentRepair = $false,							# Run without any user interaction
    [switch]$isTrellisFrontServer,							# Is this the frontend server?
	[string]$trellisFrontIP ="96.236.41.215",								# IP Address of frontend server
	[string]$trellisFrontFQDN = "HSV-MARSHA",
	[switch]$isTrellisBackServer = $true,							# Is this the backend server?
	[string]$trellisBackIP ="10.104.5.177",									# IP Address of backend server
	[string]$trellisBackFQDN = "HSV-DAUGHERTY",
	[switch]$DetectOtherServers = $false,					# Detect front|backend server
	[string]$OutputMethod = 'text',							# text/xml/html
	[switch]$OpenOutput = $false,							# Launch report file upon completion
	[switch]$DeployTools = $false,							# 
	[switch]$SelfUpdate = $false,							# Download latest version of script
	[switch]$FetchInstaller = $false,						# Download Trellis® installation files
	[switch]$SelfRepair = $false,							# Repair  Trellis® installation files
	[string]$InstallPath = $env:SystemDrive,				# Override Installation Path
	[string]$TestVersMaj = '5',
	[string]$TestVersMin = '0',
	[string]$TrellisSizing = "Small",	
	[switch]$Verbose = $false,								# Enable verbose console output
	[switch]$ShowTips = $false,								# Enable tips console output
	[switch]$Logging = $true,								# Log output to text file
	[string]$LogFile = ".\trellis-precheck_" + $env:COMPUTERNAME + "_" + (Get-Date -UFormat %Y%m%d-%H%M) + ".log"			# Default location for logs to be saved
#>

    [string]$TargetServers = [Environment]::MachineName,	# Comma Seperated List
    [string]$UserName = [Environment]::UserName,			# Username only
	[string]$DomainName = [Environment]::UserDomainName,	# Domain name only
	[switch]$AllChecks = $false,							# Perform all possible checks
	[switch]$SilentRepair = $false,							# Run without any user interaction
    [switch]$isTrellisFrontServer,							# Is this the frontend server?
	[string]$trellisFrontIP =$null,								# IP Address of frontend server
	[string]$trellisFrontFQDN = $null,
	[switch]$isTrellisBackServer,							# Is this the backend server?
	[string]$trellisBackIP =$null,									# IP Address of backend server
	[string]$trellisBackFQDN = $null,
	[switch]$DetectOtherServers = $false,					# Detect front|backend server
	[string]$OutputMethod = 'text',							# text/xml/html
	[switch]$OpenOutput = $false,							# Launch report file upon completion
	[switch]$DeployTools = $false,							# 
	[switch]$SelfUpdate = $false,							# Download latest version of script
	[switch]$FetchInstaller = $false,						# Download Trellis® installation files
	[switch]$SelfRepair = $false,							# Repair  Trellis® installation files
	[string]$InstallPath = $env:SystemDrive,				# Override Installation Path
	[string]$TestVersMaj = '5',
	[string]$TestVersMin = '0',
	[string]$TrellisSizing = "Small",	
	[switch]$Verbose = $false,								# Enable verbose console output
	[switch]$ShowTips = $false,								# Enable tips console output
	[switch]$Logging = $true,								# Log output to text file
	[string]$LogFile = ".\trellis-precheck_" + $env:COMPUTERNAME + "_" + (Get-Date -UFormat %Y%m%d-%H%M) + ".log"			# Default location for logs to be saved

)
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
#  Constants / Global Variables
#---------------------------------------------------------------------------------------------
$ConfConfigBase = "config"
$ConfScriptsBase = "common"
$ConfCustomBase = "custom"
$ConfLibBase = "lib"
$ConfResourceBase = "res"
$VersMaj = 5
$VersMin = 0

$GB = (1024*1024*1024)
$MB = (1024*1024)
#---------------------------------------------------------------------------------------------
#  string TimeStamp(void)
#---------------------------------------------------------------------------------------------
function TimeStamp {
	return $(Get-Date -f yyyyMMDD-HH:mm:ss);
}
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
#  void Write-Tip(string)
#---------------------------------------------------------------------------------------------
function Write-Tip {
param(
	[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a string",
	ValueFromPipeline=$True)]$content
	)
	if ($ShowTips) {Write-Host $content -BackgroundColor "Black" -ForegroundColor "Blue"}
	if ($Logging -and $CopyToLog) {
		Add-Content $LogFile "`n$content"
	}	
}
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
#  void Write-Verbose(string)
#---------------------------------------------------------------------------------------------
function Write-Verbose {
param(
	[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a string",
	ValueFromPipeline=$True)]$content,
	[switch]$Force = $false,
	[switch]$CopyToLog = $true
	)
	if ($Verbose -or $Force) {Write-Host $content -BackgroundColor "Black" -ForegroundColor "Gray"}
	if ($Logging -and $CopyToLog) {
		$content = $content -replace "`n","`r`n"
		Add-Content $LogFile "$content"
	}
}

function Write-Check {
param(
	[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a string",
	ValueFromPipeline=$True)]$content,		# Output message
	[switch]$Failed,						# Output represents failure
	[switch]$Suppress,						# Suppress output to screen
	[switch]$Soft							# Indicates that failure is not critical
	)
	if ($Failed) {
		if (!($Suppress)) { Write-Host $content -BackgroundColor "Black" -ForegroundColor "Red" }
	} elseif ($Soft) {
		if (!($Suppress)) { Write-Host $content -BackgroundColor "Black" -ForegroundColor "DarkYellow" }
	} else {
		if (!($Suppress)) { Write-Host $content -BackgroundColor "Black" -ForegroundColor "Green" }
	}
	if ($Logging) {
		$content = $content -replace "`n","`r`n"
		Add-Content $LogFile "`n$content"
	}

}
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
#  void Write-Notice(string)
#---------------------------------------------------------------------------------------------
function Write-Notice {
param(
	[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a string",
	ValueFromPipeline=$True)]$content
	)
	if ($Verbose) {Write-Host $content -BackgroundColor "Black" -ForegroundColor "Blue"}
	if ($Logging) {
		$content = $content -replace "`n","`r`n"
		Add-Content $LogFile "`n$content"
	}
}
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
#  void Write-Fatal(string)
#---------------------------------------------------------------------------------------------
function Write-Fatal {
param(
	[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a string",
	ValueFromPipeline=$True)]$content
	)
	Write-Host $content -BackgroundColor "Black" -ForegroundColor "Red"
	if ($Logging) {
		$content = $content -replace "`n","`r`n"
		Add-Content $LogFile "`n$content"
	}
}
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
#  void Write-Tip(string)
#---------------------------------------------------------------------------------------------
function Write-Prompt {
<# 
    .Synopsis
        Allows the user to select simple items, returns a number to indicate the selected item. 

    .Description 

        Produces a list on the screen with a caption followed by a message, the options are then
        displayed one after the other, and the user can one. 
  
        Note that help text is not supported in this version. 

    .Example 

        PS> select-item -Caption "Configuring RemoteDesktop" -Message "Do you want to: " -choice "&Disable Remote Desktop",
           "&Enable Remote Desktop","&Cancel"  -default 1
       Will display the following 
  
        Configuring RemoteDesktop   
        Do you want to:   
        [D] Disable Remote Desktop  [E] Enable Remote Desktop  [C] Cancel  [?] Help (default is "E"): 

    .Parameter Choicelist 

        An array of strings, each one is possible choice. The hot key in each choice must be prefixed with an & sign 

    .Parameter Default 

        The zero based item in the array which will be the default choice if the user hits enter. 

    .Parameter Caption 

        The First line of text displayed 

     .Parameter Message 

        The Second line of text displayed     
	.Link
		http://blogs.technet.com/b/jamesone/archive/2009/06/24/how-to-get-user-input-more-nicely-in-powershell.aspx
#>
param(
	[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter choices",ValueFromPipeline=$True)]
	[String[]]$choiceList,
	[Parameter(Position=1,Mandatory=$True,HelpMessage="Enter a caption")]
	[String]$Caption="Please make a selection", 
	[Parameter(Position=2,Mandatory=$True,HelpMessage="Enter a caption")]
   	[String]$Message="Choices are presented below", 
    [int]$default=0
	)
	process {
		$choicedesc = New-Object System.Collections.ObjectModel.Collection[System.Management.Automation.Host.ChoiceDescription] 

	   	$choiceList | foreach  { $choicedesc.Add((New-Object "System.Management.Automation.Host.ChoiceDescription" -ArgumentList $_))} 

	   	$Host.ui.PromptForChoice($caption, $message, $choicedesc, $default)
	}
}
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
#  bool ValidateRunEnviroment(void)
#---------------------------------------------------------------------------------------------
function ValidateRunEnviroment([bool] $OverrideValue) {
	#
	#  Verify necessary scripting components are present prior to execution.
	#
	if (Test-Path variable:$OverrideValue) {
		return $OverrideValue
	}
	
	if (!(Test-Path $ConfConfigBase)) {
		Write-Error -Message "[$(TimeStamp) | Fatal]: Configuration folder $ConfConfigBase is missing, please verify/re-download tool."
		return $false;
	}
	
	if (!(Test-Path $ConfCustomBase)) {
		Write-Error -Message "[$(TimeStamp) | Fatal]: Custom folder $ConfCustomBase is missing, please verify/re-download tool."
		return $false;
	}
	
	if (!(Test-Path $ConfScriptsBase)) {
		Write-Error -Message "[$(TimeStamp) | Fatal]: Scripts $ConfScriptsBase folder is missing, please verify/re-download tool."
		return $false;
	}
	
	#  All folders present
	return $true;
}
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
#  void Unblock-File(void)
#	- See. http://andyarismendi.blogspot.co.uk/2012/02/unblocking-files-with-powershell.html
#---------------------------------------------------------------------------------------------
function Unblock-File {
    [cmdletbinding(DefaultParameterSetName="ByName", SupportsShouldProcess=$True)]
    param (
        [parameter(Mandatory=$true, ParameterSetName="ByName", Position=0)] [string] $FilePath,
        [parameter(Mandatory=$true, ParameterSetName="ByInput", ValueFromPipeline=$true)] $InputObject
    )
    begin {
        Add-Type -Namespace Win32 -Name PInvoke -MemberDefinition @"
        // http://msdn.microsoft.com/en-us/library/windows/desktop/aa363915(v=vs.85).aspx
        [DllImport("kernel32", CharSet = CharSet.Unicode, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool DeleteFile(string name);
        public static int Win32DeleteFile(string filePath) {
            bool is_gone = DeleteFile(filePath); return Marshal.GetLastWin32Error();}
 
        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        static extern int GetFileAttributes(string lpFileName);
        public static bool Win32FileExists(string filePath) {return GetFileAttributes(filePath) != -1;}
"@
    }
    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ByName'  {$input_paths = Resolve-Path -Path $FilePath | ? {[IO.File]::Exists($_.Path)} | Select -Exp Path}
            'ByInput' {if ($InputObject -is [System.IO.FileInfo]) {$input_paths = $InputObject.FullName}}
        }
        $input_paths | % {     
            if ([Win32.PInvoke]::Win32FileExists($_ + ':Zone.Identifier')) {
                if ($PSCmdlet.ShouldProcess($_)) {
                    $result_code = [Win32.PInvoke]::Win32DeleteFile($_ + ':Zone.Identifier')
                    if ([Win32.PInvoke]::Win32FileExists($_ + ':Zone.Identifier')) {
                        Write-Error ("Failed to unblock '{0}' the Win32 return code is '{1}'." -f $_, $result_code)
                    }
                } else {
					Write-Output "[$(TimeStamp) | Debug] $_ Not Processed"
				}
            } else {
				Write-Output "[$(TimeStamp) | Debug] $_ Does Not Exist"
			}
        }
    }
}
#---------------------------------------------------------------------------------------------

function UnblockCmdLets([System.String]$Path) {
	if (Test-Path $PWD\$Path) {
		#Get-ChildItem -Path $PWD\$Path -Filter *.ps* -Recurse | Unblock-File
		Get-ChildItem -Path $PWD\$Path -Filter *.ps* -Recurse | % { cmd /c "echo.>$($_.FullName):Zone.Identifier:$DATA" }
		Get-ChildItem -Path $PWD\$Path -Filter *.ps* -Recurse | % { cmd /c "echo.>$($_.FullName):Zone.Identifier" }
		return $true;
	}
	return $false;
}

function GenerateForm([System.String]$Template) {
	#
	#  Rewrite of http://blogs.technet.com/b/heyscriptingguy/archive/2011/07/24/create-a-simple-graphical-interface-for-a-powershell-script.aspx
	#
	[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null 
	[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null 
	$frmUiMain = New-Object System.Windows.Forms.Form 
	$btnUiMain_Generate = New-Object System.Windows.Forms.Button 
	$btnUiMain_Bundle = New-Object System.Windows.Forms.Button 
	$btnUiMain_Quit = New-Object System.Windows.Forms.Button
	$iniUiMain_State = New-Object System.Windows.Forms.FormWindowState 


	$handler_btnUiMain_Generate_Click = { 
		#
		$TemplateHTML = ''
		$TemplateHTML = GetTemplateSig
		$TemplatePlainText = ''
		$TemplatePlainText = [IO.File]::ReadAllText(".\resources\signature.txt")
		$TemplateRichText = ''
		$TemplateRichText = [IO.File]::ReadAllText(".\resources\signature.rtf")
		ProcessContacts($TemplateHTML)
		ProcessContactsPlaintText($TemplatePlainText)
		ProcessContactsRichText($TemplateRichText)
	}

	$handler_btnUiMain_Bundle_Click = {
		#
		BundleSignatures
		BundleSendToUsers
	}
	
	$handler_btnUiMain_Quit_Click = { 
		#
		$frmUiMain.Close()
	}
	
	$OnLoadForm_StateCorrection = {
		#Correct the initial state of the form to prevent the .Net maximized form issue 
		$frmUiMain.WindowState = $InitialFormWindowState 
	}

	$frmUiMain.Text = "Inbay Signature Builder" 
	$frmUiMain.MaximumSize = New-Object System.Drawing.Size(320,320);
	$frmUiMain.Name = "Footsie v2.0" 
	$frmUiMain.DataBindings.DefaultDataSourceUpdateMode = 0 
	$frmUiMain.ClientSize = New-Object System.Drawing.Size(320,320)

	$btnUiMain_Generate.TabIndex = 0 
	$btnUiMain_Generate.Name = "Generate Signature" 
	$btnUiMain_Generate.Text = "&Generate"
	$btnUiMain_Generate.Size = New-Object System.Drawing.Size(96,64)
	$btnUiMain_Generate.UseVisualStyleBackColor = $True
	
	$btnUiMain_Bundle.TabIndex = 0 
	$btnUiMain_Bundle.Name = "Bundle Signature"
	$btnUiMain_Bundle.Text = "&Bundle"
	$btnUiMain_Bundle.Size = New-Object System.Drawing.Size(96,64)
	$btnUiMain_Bundle.UseVisualStyleBackColor = $True
	
	$btnUiMain_Quit.TabIndex = 2
	$btnUiMain_Quit.Name = "Quit" 
	$btnUiMain_Quit.Text = "&Quit"
	$btnUiMain_Quit.Size = New-Object System.Drawing.Size(96,64)
	$btnUiMain_Quit.UseVisualStyleBackColor = $True

	$btnUiMain_Generate.Location = New-Object System.Drawing.Point(90,202)
	$btnUiMain_Generate.DataBindings.DefaultDataSourceUpdateMode = 0 
	$btnUiMain_Generate.add_Click($handler_btnUiMain_Generate_Click)

	$btnUiMain_Bundle.Location = New-Object System.Drawing.Point(0,202)
	$btnUiMain_Bundle.DataBindings.DefaultDataSourceUpdateMode = 0 
	$btnUiMain_Bundle.add_Click($handler_btnUiMain_Bundle_Click)
	
	$btnUiMain_Quit.Location = New-Object System.Drawing.Point(200,202)
	$btnUiMain_Quit.DataBindings.DefaultDataSourceUpdateMode = 0 
	$btnUiMain_Quit.add_Click($handler_btnUiMain_Quit_Click)

	# Output to Form
	$frmUiMain.Controls.Add($btnUiMain_Generate)
	$frmUiMain.Controls.Add($btnUiMain_Bundle)
	$frmUiMain.Controls.Add($btnUiMain_Quit)

	#Save the initial state of the form 
	$InitialFormWindowState = $frmUiMain.WindowState 
	#Init the OnLoad event to correct the initial state of the form 
	$frmUiMain.add_Load($OnLoadForm_StateCorrection) 
	#Show the Form 
	$frmUiMain.ShowDialog()| Out-Null
} 

# (27 Nov 2018 - RayD) Add function to get values from existing hosts file
function Read-Hosts-File {
param(
	[Parameter(Mandatory=$True)][ref]$BackIP,
	[Parameter(Mandatory=$True)][ref]$BackHostname,
	[Parameter(Mandatory=$True)][ref]$BackFQDN,
	[Parameter(Mandatory=$True)][ref]$FrontIP,
	[Parameter(Mandatory=$True)][ref]$FrontHostname,
	[Parameter(Mandatory=$True)][ref]$FrontFQDN
	)

	# Read the hosts file into an array
	$data = Get-Content -Path "C:\Windows\system32\drivers\etc\hosts"
	# Get the first line that has trellis-back in it
	$firstline = $data | where { $_ -like "*trellis-back*"} | Select-Object -First 1
	# Assume the first word is the back server IP address
	$BackIP.value = ($firstline -split "\s+")[0]
	$theip = $BackIP.value
	# This is often not the first line with the IP address, which we asume has the hostname and FQDN, so refetch the first line with the back server IP
	$firstline = $data | where { $_ -like "*$theip*"} | Select-Object -First 1
	# Now we can get the Hostname and FQDN, which should be the 2nd and 3rd words in the line
	$BackHostname.value = ($firstline -split "\s+")[2]
	$BackFQDN.value = ($firstline -split "\s+")[1]
	# Now we repeat the above using "trellis-front" to get the front server info
	$firstline = $data | where { $_ -like "*trellis-front*"} | Select-Object -First 1
	$FrontIP.value = ($firstline -split "\s+")[0]
	$theip = $FrontIP.value
	$firstline = $data | where { $_ -like "*$theip*"} | Select-Object -First 1
	$FrontHostname.value = ($firstline -split "\s+")[2]
	$FrontFQDN.value = ($firstline -split "\s+")[1]
}


# (27 Nov 2018 - RayD) Add function to return the current Trellis version
# TODO: Clean this up and make it more fault tollerant!
function Read-Trellis-Version {
	return ((Get-Content -Path "C:\u01\trellis\trellis.version") -split "=")[1]
}

#####

#---------------------------------------------------------------------------------------------
#  Entry Point
#---------------------------------------------------------------------------------------------
#Write-Output "[Debug]: $Template"
#GenerateForm($Template)
if (ValidateRunEnviroment($true)) {
	
	#---------------------------------------------------------------------------------------------
	#  Load Required Modules
	#---------------------------------------------------------------------------------------------
	UnblockCmdLets -Path $ConfCustomBase
	UnblockCmdLets -Path $ConfScriptsBase
	UnblockCmdLets -Path $ConfLibBase
	Get-ChildItem -Path $PWD\$ConfCustomBase -Filter *.ps* -Recurse | ForEach-Object { Import-Module $_.FullName }
	Get-ChildItem -Path $PWD\$ConfScriptsBase -Filter *.ps* -Recurse | ForEach-Object { Import-Module $_.FullName }
	
	$Env:PSModulePath = "${Env:PSModulePath};$PWD\$ConfLibBase" #  Set relative path for modules
	Import-Module Pscx -Arg $PWD\$ConfLibBase\pscx\Pscx.UserPreferences.ps1	#  Defined entry point for PSCX
	#---------------------------------------------------------------------------------------------

	#---------------------------------------------------------------------------------------------
	#  Load Testing Criteria
	#---------------------------------------------------------------------------------------------
	
	#---------------------------------------------------------------------------------------------
	
	#---------------------------------------------------------------------------------------------
	#  Begin Testing Requirements
	#---------------------------------------------------------------------------------------------
	$consoleUi = (Get-Host).UI.RawUI
	$consoleUi.BackgroundColor = "black"
	$ConsoleUi.WindowTitle = "Trellis Pre-Requisit Script"
	Clear-Host
	
	#---------------------------------------------------------------------------------------------
	#  Prepare Log File
	#---------------------------------------------------------------------------------------------
	if (Test-Path $LogFile) {
		Clear-Content $LogFile
	}
	#---------------------------------------------------------------------------------------------
	
	#
	#  Summary Information
	#
	Write-Verbose "###############################################################################`n#" -CopyToLog -Force
	Write-Verbose "#`tTrellis© Platform - Windows™ Pre-Install Report (v$VersMaj.$VersMin)`n#" -CopyToLog -Force
	Write-Verbose "#`tCriteria:`tTrellis© Platform v$($TestVersMaj).$($TestVersMin) ($TrellisSizing Instance)`n#" -CopyToLog -Force
	Write-Verbose "###############################################################################`n" -CopyToLog -Force
	Write-Verbose "SUMMARY:`n" -CopyToLog -Force
	Write-Verbose "`tUser Name:`t\\$env:UserDomain\$env:UserName"  -CopyToLog -Force
	Write-Verbose "`tHome Directoy:`t$env:UserProfile" -CopyToLog -Force
	Write-Verbose "`tServer Name:`t$env:COMPUTERNAME" -CopyToLog -Force
	Write-Verbose "`tFQDN:`t`t$(([System.Net.Dns]::GetHostByName(($env:computerName)).HostName))" -CopyToLog -Force
	
	<#Foreach ($ip in ([System.Net.Dns]::GetHostAddresses($TargetServer))) {
		Write-Output "`tIP:`t`t$ip"
	}#>
	if ((Get-IPv4Address).Count -gt 1) {
		$OFS = ', '
		Write-Verbose "`tIPv4:`t`t$(@(Get-IPv4Address))" -CopyToLog -Force
	} else {
		Write-Verbose "`tIPv4:`t`t$(@(Get-IPv4Address))" -CopyToLog -Force
	}
	if ((Get-IPv6Address).Count -le 0) {
		Write-Verbose "`tIPv6:`t`tDisabled" -CopyToLog -Force
	} elseif ((Get-IPv6Address).Count -gt 1) {
		$OFS = ', '
		Write-Verbose "`tIPv6:`t`t$(@(Get-IPv6Address))" -CopyToLog -Force
	} else {
		Write-Verbose "`tIPv6:`t`t$(@(Get-IPv6Address))" -CopyToLog -Force
	}
	Write-Verbose "`tOS Version:`t$((Get-WindowsVersionInfo).Caption)SP$((Get-WindowsVersionInfo).ServicePackMajorVersion)" -CopyToLog -Force
	if ((Get-CPUs).Sockets -lt 2) {
		$cpuName = (Get-CPUs).Name -Replace '\s+', ' '
		$cpuIsa = (Get-CPUs).Isa
		$cpuSockets = (Get-CPUs).Sockets
		$cpuCores = ((Get-CPUs).Cores)
		Write-Verbose "`tProcessor:`t1x $cpuName ($cpuCores core)" -CopyToLog -Force
	} else {
		$cpuName = ((Get-CPUs).Name[0]) -Replace '\s+', ' '
		$cpuIsa = ((Get-CPUs).Isa[0])
		$cpuSockets = ((Get-CPUs).Sockets)
		$cpuCores = (((Get-CPUs).Cores)/$cpuSockets)
		Write-Verbose "`tProcessor:`t$($cpuSockets)x $cpuName ($cpuCores core)" -CopyToLog -Force
	}
	Write-Verbose "`tTotal Cores:`t$((Get-CPUs).Cores)" -CopyToLog -Force
	Write-Verbose "`tMemory:`t`t$([Math]::Round(((Get-PhyMemoryConf -TargetServer $TargetServers).MemoryTotal)/1024))GB" -CopyToLog -Force
	Write-Verbose "`tServer Type:`t$((Get-CPUs).ResourceType) ($(Get-Hypervisor))" -CopyToLog -Force
	Write-Verbose "`tTime Zone:`t$((Get-RegionInfo).TimeZone)" -CopyToLog -Force
	Write-Verbose "`tTime Server:`t$((Get-TimeServer -ComputerName 'localhost').TimeServer)" -CopyToLog -Force
# (13 Nov 2018 - RayD) Add User Culture and Login Culture, since the log only shows pass/fail, and not the current values
	Write-Verbose "`tUser Culture:`t$((Get-Culture).Name)" -CopyToLog -Force
	Write-Verbose "`tLogin Culture:`t$((Get-ItemProperty -Path "Microsoft.PowerShell.Core\Registry::HKEY_USERS\.Default\Control Panel\International"  -Name sLanguage).sLanguage)" -CopyToLog -Force
# (29 Oct 2018 - RayD) Show latest installed version of .NET framework
	Write-Verbose "`tInstalled .Net Versions:`t$(@(Get-AllDotNetFrameworkVersions))" -CopyToLog -Force
	
# (2 Nov 2018 - RayD) Assume this is upgrade if you find the file /u01/trellis/trellis.bat
	if (Test-Path "/u01/trellis/trellis.bat" ) {
		$ThisIsAnUpgrade = $true
	} else {
		$ThisIsAnUpgrade = $false
	}

# (27 Nov 2018 - RayD) For upgrades, include the current Trellis version in the Summary
	if ($ThisIsAnUpgrade) {
		$trellisVersion = Read-Trellis-Version
		Write-Verbose "`tCurrent Trellis Versions:`t$trellisVersion" -CopyToLog -Force
	} 	

# (27 Nov 2018 - RayD) If the hosts file was already modified for Trelis, include it in the Summary.  But skip if test parameters were used
	if (-Not ($trellisBackIP -or $trellisBackFQDN -or $trellisFrontIP -or $trellisFrontFQDN)) {
		$trellisBackIP = " "
		$trellisBackHostname = " "
		$trellisBackFQDN = " "
		$trellisFrontIP = " "
		$trellisFrontHostname = " "
		$trellisFrontFQDN = " "
		Read-Hosts-File ([ref]$trellisBackIP) ([ref]$trellisBackHostname) ([ref]$trellisBackFQDN) ([ref]$trellisFrontIP) ([ref]$trellisFrontHostname) ([ref]$trellisFrontFQDN)
		if ($trellisBackIP) {
			Write-Verbose "`tBack Server IP:`t$trellisBackIP" -CopyToLog -Force		
			Write-Verbose "`tBack Server Hostname:`t$trellisBackHostname" -CopyToLog -Force	
			Write-Verbose "`tBack Server FQDN:`t$trellisBackFQDN" -CopyToLog -Force	
			Write-Verbose "`tFront Server IP:`t$trellisFrontIP" -CopyToLog -Force		
			Write-Verbose "`tFront Server Hostname:`t$trellisFrontHostname" -CopyToLog -Force	
			Write-Verbose "`tFront Server FQDN:`t$trellisFrontFQDN" -CopyToLog -Force	

			# Set isTrellisFrontServer or isTrellisBackServer if the IP's match
            if ((Get-IPv4Address).Count -eq 1) {
                $ipv4address = Get-IPv4Address
                if ($ipv4address = $trellisBackIP) {
                    $isTrellisBackServer = $true
                }
                if ($ipv4address = $trellisFrontIP) {
                    $isTrellisFrontServer = $true
                }

            }
		}
	}

	Write-Verbose "`n" -CopyToLog -Force
	#####

	#
	#  Server Role Confirmation
	#
	if (!($isTrellisFrontServer -xor $isTrellisBackServer)) {
		$tmpAns = Write-Prompt  -Caption "`bWhich server are we running on?" -Message "Do you want to: " -choice "&Front Server", "&Back Server" -default 0
		if ($tmpAns -eq 0) {
			$isTrellisFrontServer = $true
		} else {
			$isTrellisBackServer = $true
		}
	}
	#####
	
	#
	#
	#
	if (!($trellisBackIP) -and ($isTrellisFrontServer)) {
		if (((Get-HostResolutionIPv4 -TargetHostname "trellis-back").IPAddressToString.Count) -gt 0) {
					Write-Verbose "INFO: Get front from hosts." -CopyToLog
					$trellisBackIP = ((Get-HostResolutionIPv4 -TargetHostname "trellis-back").IPAddressToString | Select-Object -Index 0)#.IPAddressToString
					Write-Verbose "INFO:`tCurrent Front Server auto-detected $trellisFrontIP." -CopyToLog -Force
		} else {
			Write-Verbose "INFO:`tCurrent Front Server auto--detection failed." -CopyToLog -Force
		}
	}
	if (!($trellisFrontIP) -and ($isTrellisBackServer)) {
		if (((Get-HostResolutionIPv4 -TargetHostname "trellis-front").IPAddressToString.Count) -gt 0) {
			Write-Verbose "INFO: Get front from hosts." -CopyToLog
			$trellisFrontIP = ((Get-HostResolutionIPv4 -TargetHostname "trellis-front").IPAddressToString | Select-Object -Index 0)#
			Write-Verbose "INFO:`tCurrent Backend Server auto-detected $trellisBackIP." -CopyToLog -Force
		} else {
			Write-Verbose "INFO:`tCurrent Backend Server auto-detection failed." -CopyToLog -Force
		}
	}
	#####

	#
	#  Confirm which server we are running tests for
	#
	if ($isTrellisFrontServer) {
		Write-Verbose "INFO:`t`tRunning checks for Trellis Front Server." -CopyToLog
	} else {
		Write-Verbose "INFO:`t`tRunning checks for Trellis Back Server." -CopyToLog
	}
	Write-Output "`n"
	#####
	
	#
	#  Working on Backend
	#
	if ($isTrellisBackServer) {	
		#
		#  Detect Backend IP Address
		#		
		if (!($trellisBackIP)) {
			if ((Get-IPv4Address).Count -gt 1) {
				$trellisBackIP = $null
				Write-Verbose "INFO:`t`tBackend Server auto-detected failed." -CopyToLog
			} else {
				$trellisBackIP = (Get-IPv4Address).IPAddressToString
				Write-Verbose "INFO:`t`tBackend Server auto-detected $trellisBackIP." -CopyToLog
			}
		}
	} else {	
		#
		#  Detect Frontend IP Address
		#
		if (!($trellisFrontIP)) {
			if ((Get-IPv4Address).Count -gt 1) {
				$trellisFrontIP = $null
				Write-Verbose "INFO:`t`tFrontend Server auto-detected failed." -CopyToLog
			} else {
				$trellisFrontIP = (Get-IPv4Address).IPAddressToString
				Write-Verbose "INFO:`t`tFrontend Server auto-detected $trellisFrontIP." -CopyToLog
			}
		}
	}
	#####
	
	if (!($trellisFrontIP)) {
		#
		#  Detect Frontend or Prompt User
		#
		do {
			if (!($trellisFrontIP)) {
				$userIP = Read-Host "`nPlease Enter IP for Front Server: " -ErrorAction SilentlyContinue
				$trellisFrontIP = ([regex]"(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))").match($userIP).value
			} 
			[int]$tmpAns = Write-Prompt -Caption " "  -Message "Is $trellisFrontIP correct? " -choice "&Yes", "&No" -default 0
			if ($tmpAns -gt 0) {
				$trellisFrontIP = $null		# Reset so we prompt for IP entry
			}				
		} while ($tmpAns -gt 0)
		Write-Verbose "INFO:`t`tFrontend Server IP $trellisFrontIP"
		#####	
	}
	
	if (!($trellisFrontFQDN)) {
		#
		#  Prompt for Front FQDN
		#
		do {
			$trellisFrontFQDN = Read-Host "Please Enter FQDN for Frontend Server" -ErrorAction SilentlyContinue
			$tmpAns = Write-Prompt -Caption " "  -Message "Is $trellisFrontFQDN correct?" -choice "&Yes", "&No" -default 0
		} while ($tmpAns -gt 0)
		Write-Verbose "INFO:`t`tFrontend FQDN $trellisFrontFQDN"
		#####
	}
	
	if(!($trellisBackIP)) {
		#
		#  Detect Backend of Prompt User
		#
		do {
			if (! $trellisBackIP) {
				$userIP = Read-Host "Please Enter IP for Backend Server" -ErrorAction SilentlyContinue
				$trellisBackIP = ([regex]"(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))").match($userIP).value
			}
			[int]$tmpAns = Write-Prompt -Caption " " -Message "Is $trellisBackIP correct?" -Choice "&Yes", "&No" -Default 0
			if ($tmpAns -gt 0) {
				$trellisBackIP = $null		# Reset so we prompt for IP entry
			}
		} while ($tmpAns -gt 0)
		Write-Verbose "INFO:`t`tBackend IP $trellisBackIP"
		#####
	}
	
	if (!($trellisBackFQDN)) {
		do {
			$trellisBackFQDN = Read-Host "`nPlease Enter FQDN for Backend Server" -ErrorAction SilentlyContinue
			$tmpAns = Write-Prompt -Caption " "  -Message "Is $trellisBackFQDN correct?" -choice "&Yes", "&No" -default 0
		} while ($tmpAns -gt 0)
		Write-Verbose "INFO:`t`tBackend FQDN $trellisBackFQDN"
	}
	#####

	#
	#  Verify Specified Servers not the same
	#
	if ($trellisFrontIP -eq $trellisBackIP) {
		Write-Fatal "FATAL: Front IP $trellisFrontIP & Back IP $trellisBackIP are the same."
		exit
	}
	if ($trellisFrontFQDN -eq $trellisBackFQDN) {
		Write-Fatal "FATAL: Front FQDN $trellisFrontFQDN & Back FQDN $trellisBackFQDN are the same."
		exit
	}
	#####

	#
	#  Begin Checks
	#

	#
	#  REQ 1.0 - Windows Checks (Group)
	#
	Write-Verbose "`n########################################################################################`n#`tWindows Checks`n########################################################################################`n"	
	
# (18 Oct 2018 - RayD) Add Get-RunTest and set to false in ConfigurationHandler.  This is already done int the Engineering Precheck (although not the service pack check)
	#
	#  REQ 1.1 - OS is Windows Server 2008 R2
	#
	if (Get-RunTest -TestGroup 1 -TestNumber 1) {
	    $REQ_1_1_PASS = $false
	    if ((Get-WindowsVersionInfo).Caption -like "*Windows Server 2008 R2 Enterprise*") {
		    $REQ_1_1_PASS = $true
		    Write-Check "[REQ 1.1]`tRunning Windows Server 2008 R2 Enterprise.`tPASS"
	    } else {
		    Write-Check "[REQ 1.1]`tRunning Windows Server 2008 R2 Enterprise.`tFAIL" -Failed
	    }
	    Write-Verbose "INFO:`t`t$((Get-WindowsVersionInfo).Caption)"
	    if ((Get-WindowsVersionInfo).ServicePackMajorVersion -gt 0) {
		    Write-Verbose "INFO:`t`tService Pack $((Get-WindowsVersionInfo).ServicePackMajorVersion) installed."
	    } else {
		    Write-Verbose "INFO:`t`tNo Service Pack installed."
	    }
	
	    #
	    #  OPT - Validate Service Pack availability
	    #
	    if ((Get-MaxServicePack((Get-WindowsVersionInfo).Version)) -lt (Get-WindowsVersionInfo).ServicePackMajorVersion) {
		    Write-Tip "TIP:`t`t There are Service Packs that should be applied prior to installation."
	    } else {
		    Write-Verbose "NOTE:`t`tSystem is running latest Service Pack"
	    }
	    #####  OPT - Validate Service Pack availability
    }
	####  REQ 1.1 - OS is Windows Server 2008 R2

	#
	#  REQ 1.2 - Installation Folders
	#
	#  Placed above disk space 1.6.4 checks to facilitate automatic checking of symbolicly linked folders.
	#
	$REQ_1_2_INSTALL_FLD = "\u01","\u02","\u03","\u05" #"\bea\homelist","\Program Files\Oracle"
	$REQ_1_2_PASSED = $true
	
	foreach ($Folder in $REQ_1_2_INSTALL_FLD) {
		if (Test-Path $env:SystemDrive$Folder) {
			#Write-Verbose "INFO:`t`t$env:SystemDrive$Folder Exists."
			if ((Get-HardLink -Path $env:SystemDrive$Folder).Count -gt 1) {
				Write-Verbose "INFO:`t`t$env:SystemDrive$Folder is a hardlink."
			} else {
				if ((Get-ReparsePoint -Path $env:SystemDrive$Folder).ReparsePoint) {
					$SymDest = Get-SymlinkTaregetDirectory -SymlinkDir $env:SystemDrive$Folder
					$SymDestDrv = Split-Path $SymDest -Qualifier
					$SymDestSz = (RunCheckDiskSpace -CheckSpecificDrives $SymDestDrv).FreeSpace
					Write-Verbose "INFO:`t`t$env:SystemDrive$Folder is a symbolic link to $SymDest with $([Math]::Round($SymDestSz/1024))GB free space."
					
					if(-not $InstallPath) {
						$InstallPath = Get-SymlinkTaregetDirectory -SymlinkDir $env:SystemDrive$Folder
					}
				} else {
					Write-Verbose "INFO:`t`t$env:SystemDrive$Folder has $([Math]::Round($SymDestSz/1024))GB free space."
				}
			}
			$REQ_1_2_PASSED = $REQ_1_2_PASSED -and $true
		} else {
			Write-Verbose "INFO:`t`tInstallation folder $env:SystemDrive$Folder is missing."
			if ($SelfRepair) {
				if ($installationRoot -ne '$env:SystemDrive\$Folder') {
					$tmpAns = Write-Prompt -Caption "REPAIR:`t Repair installation folder $Folder ?" -Message "Do you want to: " -choice "&Skip Repair", "&Create Folder $env:SystemDrive$Folder", "&Link Folder $env:SystemDrive$Folder > $InstallPath$Folder" -default 0
					if ($tmpAns -eq '1') {
						New-Item -ItemType Directory -Path $env:SystemDrive\$Folder
						$REQ_1_2_PASSED = $REQ_1_2_PASSED -and $true
					} elseif ($tmpAns -eq '2') {
						Write-Warning "WARNING:`tUnable to create symbolic links. Please create manually."
						$REQ_1_2_PASSED = $REQ_1_2_PASSED -and $false
					} else {
						Write-Verbose "INFO:`tDirectory repair skipped."
						$REQ_1_2_PASSED = $REQ_1_2_PASSED -and $false
					}
				} else {
					$tmpAns = Write-Prompt -Caption "REPAIR:`t Repair installation folder $Folder ?" -Message "Do you want to: " -choice "&Skip Repair", "&Create Folder $env:SystemDrive$Folder", -default 0
					if ($tmpAns -eq '1') {
						New-Item -ItemType Directory -Path $env:SystemDrive\$Folder
					} else {
						Write-Verbose "INFO:`tDirectory repair skipped."
						$REQ_1_2_PASSED = $REQ_1_2_PASSED -and $false
					}
				}
			}
			$REQ_1_2_PASSED = $REQ_1_2_PASSED -and $false
		}
	}
	if ($REQ_1_2_PASSED) {
			Write-Check "[REQ 1.2]`tInstallation folders present & linked.`t`tPASS"
	} else {
			Write-Check "[REQ 1.2]`tInstallation folders present & linked.`t`tFAIL" -Failed
	}

	#####  REQ 1.2 - Installation Folders

	#
	#  REQ 1.5 - A dedicated service account and is member of local administrators
	#
	if (Test-UserGroupMembership Administrators) {
		Write-Check "[REQ 1.5]`tService account is member of Administrators?`tPASS"
	} else {
		Write-Check "[REQ 1.5]`tService account is member of Administrators?`tFAIL" -Failed
	}
	#####  REQ 1.5 - A dedicated service account and is member of local administrators

	#
	#  REQ 1.6 - Remote Desktop Enabled
	#
	switch (Get-RemoteDesktopConfig) {
		"ALL" { Write-Check "[REQ 1.6]`tRemote Desktop Access Available.`t`tPASS"}
		"SECURE" { Write-Check "[REQ 1.6]`tRemote Desktop Access Available.`t`tPASS"}
		default { Write-Check "[REQ 1.6]`tRemote Desktop Access Available.`t`tFAIL" -Failed }
	}
	#####  REQ 1.6 - Remote Desktop Enabled
	
	#
	#  REQ 1.7 - Language & Region English US
	#

	<#if ((Get-RegionInfo).KeyMapSupported) {
		Write-Verbose "INFO:`t`tKeyboard Mapping $((Get-RegionInfo).KeyMap)"
		Write-Check "[REQ 1.1]`tKeyboard & Region is English (US) `t`tPASS"
		$REQ_1_7_PASS = $true
	} else {
		Write-Verbose "INFO:`t`tKeyboard Mapping $((Get-RegionInfo).keymap) is not supported, consider changing."
		Write-Check "[REQ 1.1]`tKeyboard & Regsion is English (US)`t`tFAIL" -Failed
		$REQ_1_7_PASS = $true
	}#>
	if (Get-CultureValid) {
		Write-Check "[REQ 1.7]`tUser Culture is English (US).`t`t`tPASS"
		$REQ_1_7_PASS = $true
	} else {
		Write-Check "[REQ 1.7]`tUser Culture is English (US).`t`t`tFAIL" -Failed
		$REQ_1_7_PASS = $fail
	}
	#####  REQ 1.7 - Language & Region English US
	
	#
	#  REQ 1.8 - Login Language & Region English US
	#
	if (Get-RegionLoginScreenValid) {
		Write-Check "[REQ 1.8]`tLogin Culture is English (US).`t`t`tPASS"
		$REQ_1_8_PASS = $true
	} else {
		Write-Check "[REQ 1.8]`tLogin Culture is English (US).`t`t`tFAIL" -Failed
		$REQ_1_8_PASS = $true
	}
	#####  REQ 1.8 - Login Language & Region English US

	#
	#  REQ 1.9 - Check .NET Framework version
	#
# (18 Oct 2018 - RayD) Add check for the .NET Framework version >= 3.0
	if (Get-RunTest -TestGroup 1 -TestNumber 9) {
        $DotNetVersion = Get-DotNetFrameworkVersion
	    if ($DotNetVersion -ge 3.0) {
			Write-Verbose "`nINFO: Latest .NET Framework version is $DotNetVersion, which is greater than the required 3.0 version."
		    Write-Check "[REQ 1.9]`tConfirm .NET Framework version.`t`t`tPASS"
		    $REQ_1_9_PASS = $true
	    } else {
			Write-Verbose "`nINFO: .NET Framework version is $DotNetVersion, which is less than required 3.0 version."
		    Write-Check "[REQ 1.9]`tConfirm .NET Framework version.`t`t`tFAIL" -Failed
		    $REQ_1_9_PASS = $false
	    }
    }

    #
	#  REQ 1.10 - Check if 8.3 Filename support is enabled
	#
# (18 Oct 2018 - RayD) Add check for 8.3 filename support
	if (Get-RunTest -TestGroup 1 -TestNumber 10) {
		$wrong = $false
		if (-Not (Get-8Dot3FilenameEnabled)) {
			Write-Verbose "`nINFO: 8.3 filename support should be enabled for all drives.  To fix, enter 'fsutil behavior set disable8dot3 0' in an elevated commmand prompt."
			Write-Verbose "INFO: The PowerShell command 'Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem -Name NtfsDisable8dot3NameCreation).NtfsDisable8dot3NameCreation' should return 0"
			$wrong = $true
	    }
		
# (5 Nov 2018 - RayD) Add test if 8.3 support is set in global policy 
		if (Get-8Dot3FilenameResetInGPO) {
			Write-Verbose "`nINFO: There is a Global Policy that is resetting 8.3 filename support.  This needs to be turned off."
			Write-Verbose "INFO: The Powershell command '(gpresult /V | findstr "NtfsDisable8dot3NameCreation" | Measure-Object).Count' should return 0"
			$wrong = $true
		}

	    if ($wrong) {
		    Write-Check "[REQ 1.10]`tConfirm 8.3 filename suppport is enabled.`tFAIL" -Failed
		    $REQ_1_10_PASS = $false
	    } else {
		    Write-Check "[REQ 1.10]`tConfirm 8.3 filename support is enabled.`tPASS"
		    $REQ_1_10_PASS = $true
	    }

    }

    #
	#  REQ 1.11 - Check to see if service account was previously used for an install or upgrade, but skip if we are doing an install
	#
# (18 Oct 2018 - RayD) Add check for previous use of service account.
	if (Get-RunTest -TestGroup 1 -TestNumber 11) {
		# Skip if this in an install instead of an upgrade.  There won't be any prior files to check.
		if ($ThisIsAnUpgrade) {
			if (Get-ServiceAccountPreviouslyUsed) {
				Write-Verbose "INFO: For upgrades, this is the same Service Account that was previously used for the install (i.e. TrellisScripts.zip was found)."
				Write-Check "[REQ 1.11]`tPrior use of service account.`t`t`tPASS"
				$REQ_1_11_PASS = $true
			} else {
				Write-Verbose "INFO: For upgrades, it does not look like this Service Account was used for the install (i.e. TrellisScripts.zip was not found)."
				Write-Check "[REQ 1.11]`tPrior use of service account.`t`t`tAIL" -Failed
				$REQ_1_11_PASS = $false
			}
		} else {
				Write-Check "[REQ 1.11]`tPrior use of service account.`t`t`tSKIPPED"
		}
    }
			
	#####  REQ 1.0 - Windows Checks (Group)
	
	#
	#  REQ 2.0 - Hardware Checks
	#
	Write-Verbose "`n###############################################################################`n#`tHardware Checks`n###############################################################################`n"
	if (Get-RunTest -TestGroup 2 -TestNumber 0) {
		if ($isTrellisBackServer) {
			Write-Verbose "NOTE:`t`tTest criteria for Trellis back server.`n"
		} else {
			Write-Verbose "NOTE:`t`tTest criteria for Trellis front server.`n"
		}
		
		#
		#  Group Flags
		#
		$REQ_2_0_PASS = $true
		#####
	
		#
		#  REQ 2.1 - Check CPU Core Count
		#
		if (Get-RunTest -TestGroup 2 -TestNumber 1) {
			if ($isTrellisBackServer) {
				$REQ_2_1_CPUCORES = [int]((Get-SizeTrellisInstance -TrellisMaj $TestVersMaj -TrellisMin $TestVersMin -sizeDescription $TrellisSizing).GetEnumerator() | % {$_.BACK_CORES})[1]		# Backend Server Requirement CPU cores total
			} else {
				$REQ_2_1_CPUCORES = [int]((Get-SizeTrellisInstance -TrellisMaj $TestVersMaj -TrellisMin $TestVersMin -sizeDescription $TrellisSizing).GetEnumerator() | % {$_.FRONT_CORES})[1]		# Frontend Server Requirement CPU cores total
			}
			
			if ((Get-CPUs).Cores -lt $REQ_2_1_CPUCORES) {
				Write-Verbose "INFO:`t`tProcessor core count of $((Get-CPUs).Cores) is below recommendation of $($REQ_2_1_CPUCORES)."
				$REQ_2_0_PASS = ($REQ_2_0_PASS -band $false);
				Write-Check "[REQ 2.1]`tCPU core count $REQ_2_1_CPUCORES or more.`t`t`tFAIL" -Failed
				$REQ_2_1_PASS = $true
			} else {
				Write-Check "[REQ 2.1]`tCPU core count $REQ_2_1_CPUCORES or more.`t`t`tPASS"
				$REQ_2_1_PASS = $false
			}
			
			Write-Verbose "`nINFO:`t`tSystem features $((Get-CPUs).Sockets) sockets, $((Get-CPUs).Cores) cores, $((Get-CPUs).Threads) threads"
			
			if ((Get-CPUs).ResourceType -eq "Virtual") {
				Write-Tip "INFO:`t`tSystem is running as a Virtual Machine. Please seek advice for optimal configuration."
			} else {
				Write-Tip "INFO:`t`tSystem is running on bare-metal. Please take extra care with configuration changes."
			}
		}
		##### REQ 2.1 - Check CPU Core Count
		
		#
		#  REQ 2.2 - Available RAM
		#
		if (Get-RunTest -TestGroup 2 -TestNumber 2) {

			#
			#  Define Criteria
			#
			if ($isTrellisBackServer) {
				$REQ_2_2_MINRAM = [int]((Get-SizeTrellisInstance -TrellisMaj $TestVersMaj -TrellisMin $TestVersMin -sizeDescription $TrellisSizing).GetEnumerator() | % {$_.BACK_RAM})[1]		# Backend Server Requirement (MB)
			} else {
				$REQ_2_2_MINRAM = [int]((Get-SizeTrellisInstance -TrellisMaj $TestVersMaj -TrellisMin $TestVersMin -sizeDescription $TrellisSizing).GetEnumerator() | % {$_.FRONT_RAM})[1]		# Frontend Server Requirement (MB)
			}
			#####
			
			if ([int]((Get-PhyMemoryConf -TargetServer $TargetServers).MemoryTotal) -ge ($REQ_2_2_MINRAM * 0.98)) {
				#Write-Verbose "INFO:`t`tInstalled RAM of $([Math]::Round(((Get-PhyMemoryConf -TargetServer $TargetServers).MemoryTotal)/1024))GB"
				$REQ_2_0_PASS = ($REQ_2_0_PASS -band $true);
				$REQ_2_2_PASS = $true
				Write-Check "[REQ 2.2]`tAllocated RAM is at-least $($REQ_2_2_MINRAM/1024)GB.`t`t`tPASS"
			} else {
				#Write-Verbose "INFO:`t`tInstalled $([Math]::Round((Get-PhyMemoryConf -TargetServer $TargetServers).MemoryTotal)/1024)GB is below minimum of $($REQ_2_2_MINRAM/1024)GB."
				$REQ_2_0_PASS = ($REQ_2_0_PASS -band $false);
				$REQ_2_2_PASS = $false
				Write-Check "[REQ 2.2]`tAllocated RAM is at-least $($REQ_2_2_MINRAM/1024)GB.`t`t`tFAIL" -Failed
			}
		}
		##### REQ 2.2 - Available RAM
		
		Write-Verbose "INFO:`n" -CopyToLog
		$DiskDrives = Get-FixedDisks
		Write-Verbose "`tDrive [Mount]`tTotal Size`tFree Space" -CopyToLog
		foreach ($Disk in $DiskDrives) {
			Write-Verbose "`t$($Disk.Name) [$($Disk.RootDirectory)]`t$([Math]::Round(($Disk.TotalSize)/$GB))GB`t`t$([Math]::Round(($Disk.TotalFreeSpace)/$GB))GB" -CopyToLog #-Force
		}
		Write-Verbose "`n" -CopyToLog
		
		#
		#  REQ 2.4 - Disk Space Requirements
		#
		if (Get-RunTest -TestGroup 2 -TestNumber 4) {
			$REQ_2_4_INSTALL_FLD = "\u01","\u02","\u03","\u05" #"\bea\homelist","\Program Files\Oracle"	
# (12 Nov 2018 - RayD) Use different amount of storage when checking for upgrade as opposed to install.
			if ($ThisIsAnUpgrade) {
				$REQ_2_4_HDD_MINSPACE = 50000
			} else {
				$REQ_2_4_HDD_MINSPACE = 300000
			}
			if ($InstallPath -ne $env:SystemDrive) {
				Write-Verbose "INFO:`t`tInstallation path $InstallPath."
				if ([int](RunCheckDiskSpace -CheckSpecificDrives $InstallPath).FreeSpace -le $REQ_2_4_HDD_MINSPACE ) {
					Write-Verbose "WARNING:`tFree Space on Drive $InstallPath is $([int](RunCheckDiskSpace -CheckSpecificDrives $InstallPath).FreeSpace/1000)MB"
					Write-Verbose "INFO:`t`tRecommended minimum if installed to $InstallPath is $([int]($REQ_2_4_HDD_MINSPACE/1000))MB"
					$REQ_2_0_PASS = ($REQ_2_0_PASS -band $false);
				} else {	
					Write-Verbose "INFO:`t`tFree space on drive $InstallPath is $([int](RunCheckDiskSpace -CheckSpecificDrives $InstallPath).FreeSpace/1000)MB"
					$REQ_2_0_PASS = ($REQ_2_0_PASS -band $true);
				}
			} else {
				if ([int](RunCheckDiskSpace -CheckSpecificDrives "$env:SystemDrive").FreeSpace -le $REQ_2_4_HDD_MINSPACE) {
					Write-Verbose "INFO:`t`tFree Space on Drive $InstallPath is $([int](RunCheckDiskSpace -CheckSpecificDrives $InstallPath).FreeSpace/1000)MB"
					Write-Verbose "WARNING:`tRecommended Minimum if Installed to $InstallPath is $([int]($REQ_2_4_HDD_MINSPACE/1000))MB"
					$REQ_2_0_PASS = ($REQ_2_0_PASS -band $false)
				} else {	
					Write-Verbose "INFO:`t`tFree Space on Drive $InstallPath is $([int](RunCheckDiskSpace -CheckSpecificDrives $InstallPath).FreeSpace/1000)MB"
					$REQ_2_0_PASS = ($REQ_2_0_PASS -band $true)
				}
			}	
		}
		##### REQ 2.4 - Disk Space Requirements
		
		#
		#  REQ 2.3 - Disk Throughput > 300MB/s
		#
		#Write-Verbose "`n###############################################################################`n#`tPerformance Checks`n###############################################################################`n`n"	
		if (Get-RunTest -TestGroup 2 -TestNumber 3) {
		
			$REQ_2_3_HDD_READSEQ = 150
			$REQ_2_3_HDD_READRAND = 150
			$REQ_2_3_HDD_WRITESEQ = 150
			$REQ_2_3_HDD_WRITERAND = 150
		
			#$drive0 = @{}
			#$drive0 = (Get-DiskThroughPut -TargetDrive $InstallPath)
			#Write-Verbose "`n" -Force -CopyToLog
			<#if ($InstallPath -ne $env:SystemDrive) {
				$drive1 = Get-DiskThroughPut -TargetDrive $env:SystemDrive
				Write-Verbose "`tSequential Benchmark $env:SystemDrive `n`t`tRead $($drive0.ReadSequential) `tWrite $($drive0.WriteSequential)" -Force -CopyToLog
				Write-Verbose "`tRandom Benchmark $env:SystemDrive `n`t`tRead $($drive0.ReadRandom) `tWrite $($drive0.WriteRandom)" -CopyToLog
				Write-Verbose "`tSequential Benchmark $InstallPath `n`t`tRead $($drive1.ReadSequential) `tWrite $($drive1.WriteSequential)" -Force -CopyToLog
				Write-Verbose "`tRandom Benchmark $InstallPath `n`t`tRead $($drive1.ReadRandom) `tWrite $($drive1.WriteRandom)" -CopyToLog
				if ([int](($drive1.ReadSequential) -match "\d*\.\d*") -ge 150 ) {
					$REQ_2_3_PASS = ($REQ_2_3_PASS -band $true)
					Write-Check "[REQ 2.3]`tDisk throughput is 150MB/s.`t`t`tPASS"
				} else {
					$REQ_2_3_PASS = ($REQ_2_3_PASS -band $false)
					Write-Check "[REQ 2.3]`tDisk throughput is 150MB/s.`t`t`tFAIL" -Failed
				}
			} else {
				Write-Verbose "`t`tSequential Benchmark $env:SystemDrive `n`t`tRead $($drive0.ReadSequential) `tWrite $($drive0.ReadSequential)" -Force	-CopyToLog
				Write-Verbose "`t`tRandom Benchmark $env:SystemDrive `n`t`tRead $($drive0.ReadRandom) `tWrite $($drive0.WriteRandom)" -CopyToLog
				$REQ_2_3_PASS = ($REQ_2_3_PASS -band $true)
				if ([int](($drive0.ReadSequential) -match "\d*\.\d*") -ge 150 ) {
					$REQ_2_3_PASS = ($REQ_2_3_PASS -band $true)
					Write-Check "[REQ 2.3]`tDisk throughput is 150MB/s.`t`t`tPASS"
				} else {
					$REQ_2_3_PASS = ($REQ_2_3_PASS -band $false)
					Write-Check "[REQ 2.3]`tDisk throughput is 150MB/s.`t`t`tFAIL" -Failed
				}
			}#>

			$benchmarkResults = Get-AllDisksSpeed
			Write-Verbose "`t`t** Benchmarking Disks - Please be Patient **" -Force
			if ($InstallPath -ne $env:SystemDrive) {
			
				$allDrivesPass = $true	# Initialize as true as and will fail to false
				
				ForEach ($fixedDisk in (Get-FixedDisks | Select-Object -Property Name)) {
					$workingDisk = (($fixedDisk).Name).Trim(":\")
					Write-Verbose "`t`t$($workingDisk): Sequential Benchmark Read $($benchmarkResults.($workingDisk).ReadSequential)MB/s `tWrite $($benchmarkResults.($workingDisk).WriteSequential)MB/s" -Force -CopyToLog
					Write-Verbose "`t`t$($workingDisk): Random Benchmark Read $($benchmarkResults.($workingDisk).ReadRandom)MB/s `t`tWrite $($benchmarkResults.($workingDisk).WriteRandom)MB/s" -Force -CopyToLog
					if (($benchmarkResults.($workingDisk).ReadSequential -ge $REQ_2_3_HDD_READSEQ) -and ($benchmarkResults.($workingDisk).WriteSequential -ge $REQ_2_3_HDD_WRITESEQ)) {
						$allDrivesPass = $allDrivesPass -and $true
					} else {
						$allDrivesPass = $allDrivesPass -and $false
					}
				}
				if ($allDrivesPass) {
					Write-Check "[REQ 2.3]`tAll disks throughput at least $($REQ_2_3_HDD_READSEQ)MB/s.`t`tPASS"
				} else {
					Write-Check "[REQ 2.3]`tAll disks throughput at least $($REQ_2_3_HDD_READSEQ)MB/s.`t`tFAIL" -Failed
				}
			} else {
				$systemDrive = ($env:SystemDrive).Trim(":\")
				Write-Verbose "`t`t$env:SystemDrive Sequential Benchmark $($benchmarkResults.($systemDrive).ReadSequential)MB/s `tWrite $($benchmarkResults.($systemDrive).WriteSequential)MB/s" -Force -CopyToLog
				Write-Verbose "`t`t$env:SystemDrive Random Benchmark $($benchmarkResults.($systemDrive).ReadRandom)MB/s `t`tWrite $($benchmarkResults.($systemDrive).WriteRandom)MB/s" -Force -CopyToLog
				if (($benchmarkResults.($systemDrive).ReadSequential -ge $REQ_2_3_HDD_READSEQ) -and ($benchmarkResults.($systemDrive).WriteSequential -ge $REQ_2_3_HDD_WRITESEQ)) {
					Write-Check "[REQ 2.3]`tDisk throughput at least $($REQ_2_3_HDD_READSEQ)MB/s.`t`tPASS"
				} else {
					Write-Check "[REQ 2.3]`tDisk throughput at least $($REQ_2_3_HDD_READSEQ)MB/s.`t`tFAIL" -Failed
				}
			}
		}
		##### REQ 2.3 - Disk Throughput > 150MB/s

		#
		#  REQ 2.4 - Disk Space Validations
		#
		if (Get-RunTest -TestGroup 2 -TestNumber 4) {
			if ($ThisIsAnUpgrade) {
				if ([int](RunCheckDiskSpace -CheckSpecificDrives $InstallPath).FreeSpace -lt $REQ_2_4_HDD_MINSPACE) {
					Write-Check "[REQ 2.4]`tFree Space on $InstallPath sufficient for installation.`tFAIL" -Failed
					$REQ_2_4_PASS = $false	
				} else {
					Write-Check "[REQ 2.4]`tFree Space on $InstallPath sufficient for installation.`tPASS"
					$REQ_2_4_PASS = $true
				}
			} else {
				if ([int](RunCheckDiskSpace -CheckSpecificDrives $InstallPath).FreeSpace -lt $REQ_2_4_HDD_MINSPACE) {
					Write-Check "[REQ 2.4]`tFree Space on $InstallPath sufficient for upgrade.`tFAIL" -Failed
					$REQ_2_4_PASS = $false	
				} else {
					Write-Check "[REQ 2.4]`tFree Space on $InstallPath sufficient for upgrade.`tPASS"
					$REQ_2_4_PASS = $true
				}
			}
		}
		#####  REQ 2.4 - Disk Space Validations	
		
		#
		#  REQ 2.5 - Installation Requires 10GB of Free Space for Installation
		#
		if (Get-RunTest -TestGroup 2 -TestNumber 5) {
			$REQ_2_5_HDD_OS_MIN = 10240
			Write-Verbose "INFO:`n`t`tDisk space on $env:SystemDrive is $(([int](RunCheckDiskSpace -CheckSpecificDrives $env:SystemDrive).FreeSpace))MB" -CopyToLog
			if ($InstallPath -notlike $env:SystemDrive) {
				if ([int](RunCheckDiskSpace -CheckSpecificDrives $env:SystemDrive).FreeSpace -le $REQ_2_5_HDD_OS_MIN) {
					Write-Check "[REQ 2.5]`tSufficient space on $env:SystemDrive for installation.`tFAIL" -Failed
					$REQ_2_5_PASS = $false
				} else {
					Write-Check "[REQ 2.5]`tSufficient space on $env:SystemDrive for installation.`tPASS"
					$REQ_2_5_PASS = $true
				}
			}
		}
		#####  REQ 2.5 - Installation Requires 10GB of Free Space for Installation

		#
		#  REQ 2.7 - CPU Speed Checks
		#
		if (Get-RunTest -TestGroup 2 -TestNumber 7) {
			
			$REQ_2_7_CpuFreq = [int]((Get-SizeTrellisInstance -TrellisMaj $TestVersMaj -TrellisMin $TestVersMin -sizeDescription $TrellisSizing).GetEnumerator() | % {$_.CPU_FREQ})[1]		# CPU Minimum Frequency (MHz)
						
			#Write-Verbose "INFO:`t`t$(((Get-CPUs).Name) -Replace '\s+', ' ') [$((Get-CPUs).Isa)-bits]"
			if ((Get-CPUs).MaxClockSpeed -le $REQ_2_7_CpuFreq) {
				Write-Check "[REQ 2.7]`tCPU above minimum of $($REQ_2_7_CpuFreq)MHz.`t`t`tFAIL" -Failed -Soft
			} else {
				Write-Check "[REQ 2.7]`tCPU above minimum of $($REQ_2_7_CpuFreq)MHz.`t`t`tPASS" -Soft
				$REQ_2_0_PASS = ($REQ_2_0_PASS -band $true);
			}
		}
		##### REQ 2.7 - CPU Speed Checks
		
	} else {
		Write-Verbose "INFO:`tTests group 2.x checks disabled."
	}
	#####  REQ 2.0 - Hardware Checks

	#
	#  REQ 3.0 - Virtualization Checks (Group)
	#
	Write-Verbose "`n###############################################################################`n#`tVirtualization Checks`n###############################################################################`n"
	if (Get-RunTest -TestGroup 3 -TestNumber 0) {
		if ((Get-CPUs).ResourceType -eq "Virtual") {
		
			#
			#  REQ 3.1 - Verify Guest Additions Installed
			#
			if (Get-RunTest -TestGroup 3 -TestNumber 1) {
				Write-Verbose "INFO:`t`tRunning as a guest on $(Get-Hypervisor)"
				if (Get-GuestTools(Get-Hypervisor)) {
					Write-Verbose "INFO:`t`tName:`t`t$((Get-GuestTools(Get-Hypervisor)).Name)"
					Write-Verbose "`t`tVendor:`t`t$((Get-GuestTools(Get-Hypervisor)).Vendor)"
					Write-Verbose "`t`tVersion:`t$((Get-GuestTools(Get-Hypervisor)).Version)`n"
					Write-Check "[REQ 3.1]`tVirtual Machine Guest additions installed.`tPASS"
				} else {
					Write-Check "[REQ 3.1]`tVirtual Machine Guest additions installed.`tFAIL" -Fail
				}
			}
			##### REQ 3.1 - Verify Guest Additions Installed
			
			#
			#  REQ 3.2 - Check for CPU frequency throttling
			#
			if (Get-RunTest -TestGroup 3 -TestNumber 2) {
				if ((Get-CPUs).Sockets -lt 2) {
					if ([Math]::Round((Get-CPUs).CurClockSpeed) -lt [Math]::Round(((Get-CPUs).MaxClockSpeed))) {
						$REQ_3_2_PASS = $false
					} else {
						$REQ_3_2_PASS = $true
					}
				} else {
					if ([Math]::Round(((Get-CPUs).CurClockSpeed)[0]) -lt [Math]::Round(((Get-CPUs).MaxClockSpeed)[0])) {
						$REQ_3_2_PASS = $false
					} else {
						$REQ_3_2_PASS = $true
					}
				}

				if ($REQ_3_2_PASS) {
					Write-Tip "TIP:`t`tProcessor power management appears to be enabled, consider disabling power management."
					Write-Check "[REQ 3.2]`tCPU Power Management Disabled.`t`t`tFAIL" -Fail
					$REQ_3_2_PASS = $false
				} else {
					Write-Check "[REQ 3.2]`tCPU Power Management Disabled.`t`t`tPASS"
					$REQ_3_2_PASS = $true
				}
			}
			##### REQ 3.2 - Check for CPU frequency throttling	
			
		} else {
			Write-Verbose "INFO:`tRunning system is a physical host, 3.x checks skipped."
		}
	} else {
		Write-Verbose "INFO:`tTests group 3.x checks disabled."
	}
	#####  REQ 3.0 - Virtualization Checks (Group)
	
	#
	#  REQ 4.0 - Security Checks (Group)
	#
	Write-Verbose "`n###############################################################################`n#`tSecurity Checks`n###############################################################################`n"	
# (7 Nov 2018 - RayD) Turn off check, since it is hard to accurately determine if anti-virus is running.   Get-CheckRunningAv test used in older version of this script for Windows Server 2008 no longer works.
	if (Get-RunTest -TestGroup 4 -TestNumber 0) {
		#
		#  REQ 4.1 - Confirm Anti-Virus Disabled
		#

		if (Get-RunTest -TestGroup 4 -TestNumber 1) {
<#
			Write-Verbose "INFO:`t`tAnti-Virus Product Information.`n"
			Write-Verbose "`tName:`t`t$((Get-CheckRunningAv -TargetServer $TargetServers).DisplayName)"
			Write-Verbose "`tStatus:`t`t$((Get-CheckRunningAv -TargetServer $TargetServers).Status)"
			Write-Verbose "`tDefinitions:`t$((Get-CheckRunningAv -TargetServer $TargetServers).Definitions)"
			Write-Verbose "`tVersion:`t$((Get-CheckRunningAv -TargetServer $TargetServers).Version)"
			Write-Verbose "`tProgam Folder:`t$((Get-CheckRunningAv -TargetServer $TargetServers).ProgramLocation)"
			Write-Verbose "`n"
			if (New-Eicar) {
				Write-Verbose "INFO:`t`tAnti-Virus Scanner Active? `t`t`tFALSE"
				Write-Check "[REQ 4.1]`tConfirm Anti-Virus Disabled?`t`t`tPASS"
				$REQ_4_1_PASS = $true
				Write-Check "[REQ 4.4]`tCompatible Anti-Virus Present?`t`t`tN/A" -Failed -Suppress
				$REQ_4_4_PASS = $true
			} else {
				$REQ_4_1_PASS = $false
				Write-Verbose "WARNING: Anti-Virus Scanner Active?`t`t`tTrue."
				if ($(Get-CheckRunningAv -TargetServer $TargetServers).DisplayName -like "*Symantec*" ) {
					Write-Check "[REQ 4.1]`tConfirm Anti-Virus Disabled?`t`t`tFAIL" -Failed -Suppress
					Write-Check "[REQ 4.4]`tCompatible Anti-Virus Present?`t`t`tPASS"
					$REQ_4_4_PASS = $true
					Write-Verbose "INFO:`tOnly Symantec Anti-Virus Scanner Supported."
				} else {
					Write-Check "[REQ 4.1]`tConfirm Anti-Virus Disabled?`t`t`tFAIL" -Failed -Suppress
					Write-Check "[REQ 4.4]`tCompatible Anti-Virus Present?`t`t`tFAIL" -Failed
					$REQ_4_4_PASS = $false
					Write-Verbose "INFO:`tOnly Symantec Anti-Virus Scanner Supported."
				}
			}
#>
			Write-Check "[REQ 4.1]`tConfirm Anti-Virus Disabled?`t`t`tAsk Customer" -Soft
		}
		##### REQ 4.1 - Confirm Anti-Virus Disabled

		#
		# REQ 4.2 - Confirm Firewall Disabled
		#
		if (Get-RunTest -TestGroup 4 -TestNumber 2) {
			$REQ_4_2_PASS = $true
			$REQ_4_2_PASS = $REQ_4_2_PASS -band (!(CheckFirewallState).Current)	
			Write-Verbose "`nINFO:`t`tFirewall Currently Enabled?`t`t`t`t$((CheckFirewallState).Current)"
			if ($(CheckFirewallState).Current) {
				Write-Verbose "INFO:`t`tFirewall Domain Profile Enabled? `t`t$((CheckFirewallState).Domain)"
				Write-Verbose "INFO:`t`tFirewall Standard Profile Enabled? `t`t$((CheckFirewallState).Standard)"
				Write-Verbose "INFO:`t`tFirewall Public Profile Enabled? `t`t$((CheckFirewallState).Public)"
				Write-Tip "TIP:`t`tFirewall rules have not been individually validated."
			}
			
			#$REQ_4_2_PASS = $REQ_4_2_PASS -band ((CheckFirewallState).ExceptionsNotAllowed)	
			Write-Verbose "INFO:`t`tFirewall Exceptions Permitted? `t`t`t$(!(CheckFirewallState).ExceptionsNotAllowed)"

			if ($REQ_4_2_PASS) {
				Write-Check "[REQ 4.2]`tConfirm firewall disabled?`t`t`tPASS"
			} else {
				Write-Check "[REQ 4.2]`tConfirm firewall disabled?`t`t`tFAIL" -Failed
			}
		}
		##### REQ 4.2 - Confirm Firewall Disabled	

		#
		#  REQ 4.6 - UAC is enabled for logged in user
		#
		if (Get-RunTest -TestGroup 4 -TestNumber 6) {
			Write-Verbose "`nINFO:`t`tUser is Member of Administrators?`t`t$(Test-UserGroupMembership Administrators)"
			if (Get-SystemUACStatus) {
				#Write-Verbose "INFO:`t`tUser Access Control Enabled? `t`t`t$(Get-SystemUACStatus)"
				Write-Check "[REQ 4.6]`tUAC is enabled for logged in user.`t`tPASS"
			} else {
				Write-Check "[REQ 4.6]`tUAC is enabled for logged in user.`t`tFAIL" -Failed
				Write-Tip "TIP:`t`tTrellis versions from 3.01 requires this to be enabled."
			}
		}
		#####  REQ 4.6 - UAC is enabled for logged in user
		
		#
		#  REQ 4.7 - UAC Group Policy
		#
		if (Get-RunTest -TestGroup 4 -TestNumber 7) {
			if (Get-SystemUacGpo -UacSetting "ConsentPromptBehaviorAdmin" -MatchString "Elevate without prompting") {
				Write-Check "[REQ 4.7]`tUAC policy for logged in user.`t`t`tPASS"
			} else {
				Write-Check "[REQ 4.7]`tUAC policy for logged in user.`t`t`tFAIL" -Failed
			}
		}
		##### REQ 4.7 - UAC Group Policy #####

		#
		#  REQ 4.8 - Lock Pages in Memory
		#
		if (Get-RunTest -TestGroup 4 -TestNumber 8) {
			if (Get-SystemLpimGpo -UacSetting "ConsentPromptBehaviorAdmin" -MatchValue "Elevate without prompting") {
				Write-Check "[REQ 4.8]`tLocal Policy allows Locked Pages in Memory.`t`tPASS" -Soft
			} else {
				Write-Check "[REQ 4.8]`tLocal Policy allows Locked Pages in Memory.`tFAIL" -Failed -Soft
			}
		}
		##### REQ 4.8 - Lock Pages in Memory #####
	}
	#####  REQ 4.0 - Security Checks (Group)

	#
	#  REQ 5.0 - Network Checks (Group)
	#
	Write-Verbose "`n###############################################################################`n#`tNetworking Checks`n###############################################################################`n"	
	if (Get-RunTest -TestGroup 5 -TestNumber 0) {

		#
		#  REQ 5.1 - Confirm Only One NIC Enabled
		#
		if (Get-RunTest -TestGroup 5 -TestNumber 1) {
			switch ($(Run-CheckNIC -TargetServer $TargetServers | Measure).Count) {
				0 { 
					Write-Verbose "INFO: No NICs found!"
					Write-Check "[REQ 5.1]`tConfirm only 1 NIC is enabled.`t`t`tFAIL" -Failed 
				  }
				1 { 
					Write-Verbose "INFO:`n"
					foreach ($nic in $(Run-CheckNIC -TargetServer $TargetServers)) {
						Write-Verbose "`tDescription:`t$($nic.Description)`n"
						Write-Verbose "`tIP:`t`t$($nic.IPAddress)"
						Write-Verbose "`tDHCP:`t`t$($nic.DHCPEnabled)" 
						Write-Verbose "`tDomain:`t`t$($nic.DNSDomain)`n"
					}
					Write-Check "[REQ 5.1]`tConfirm only 1 NIC is enabled.`t`t`tPASS" 
				  }
				default { 
					Write-Verbose "INFO:`t`tToo many NICs found."
					Write-Check "[REQ 5.1]`tConfirm only 1 NIC is enabled.`t`t`tFAIL" -Failed
					Write-Tip "TIP:`t`tAdditional NICs can be re-enabled post installation."
					Write-Verbose "DETAILS:`n"
					foreach ($nic in $(Run-CheckNIC -TargetServer $TargetServers)) {
						Write-Verbose "`t`tDescription:`t$($nic.Description)`n"
						Write-Verbose "`t`tIP:`t`t$($nic.IPAddress)"
						Write-Verbose "`t`tDHCP:`t`t$($nic.DHCPEnabled)" 
						Write-Verbose "`t`tDomain:`t`t$($nic.DNSDomain)"
					}
				}
			}
		}
		##### REQ 5.1 - Confirm Only One NIC Enabled
		
		#
		# REQ 5.2 - Confirm DHCP Client not Enabled
		#
		if (Get-RunTest -TestGroup 5 -TestNumber 2) {
			if (-not (Run-CheckDhcp)) {
				Write-Check "[REQ 5.2]`tConfirm DHCP Client not Enabled?`t`tPASS"
				$REQ_5_2_PASS = $true
				Write-Verbose "INFO:`t`tNo interfaces are utilizing DHCP." 
			} else {
				Write-Check "[REQ 5.2]`tConfirm DHCP Client not Enabled?`t`tFAIL" -Failed
				$REQ_5_2_PASS = $false
				Write-Verbose "INFO:`t`tNICs found utilizing DHCP."
				Write-Verbose "DETAILS:`n $Run-CheckDhcp"
			}
		}
		##### REQ 5.2 - Confirm DHCP Client is not Enabled
		
		#
		#  REQ 5.3 - DNS Entry Validations
		#
		if (Get-RunTest -TestGroup 5 -TestNumber 3) {
			#
			#  List of aliases, followed up by defined hostname
			#
			$reqDnsEntriesFront = "weblogic-admin","Presentation-Operational-internal","Presentation-Analytical-internal","BAM-internal","SOA-Operational-internal","SOA-Analytical-internal","MPS-proxy-internal","CEP-Engine-internal","OHS-Balancer-internal","OSB-Server-internal","Authentication-internal","Authorization-internal-local","Flexera-Server-internal","vip-external","3rdparty-vip-external","vip-internal","MPS-proxy-external","Search-internal","Reporting-internal","trellis-front","trellis-platform"
			$reqDnsEntriesBack = "MDS-Database-internal","CDM-Database-internal","TSD-Database-internal","TSD-Database-external","Authorization-internal-admin","trellis-back"
			
			if ($trellisFrontFQDN) { 
				$reqDnsEntriesFront += $trellisFrontFQDN
				$reqDnsEntriesFront += $trellisFrontFQDN.Split('.') | Select -First 1
			}
			
			
			if ($trellisBackFQDN) { 
				$reqDnsEntriesBack += $trellisBackFQDN 
				$reqDnsEntriesBack += $trellisBackFQDN.Split('.') | Select -First 1
			}
			#####
			
			$REQ_5_3_PASS = $true		# Initialized as true for logical comparison
			$FIX_1_5_3_BYPASS = $false	# Initialized as false for logical comparison, will trigger flag
			
			Write-Verbose "INFO:`tChecking DNS entries for front server.`n" -CopyToLog
			foreach ($hostEntry in $reqDnsEntriesFront) {
				if (Resolve-Host -ComputerName $hostEntry -ErrorAction SilentlyContinue) {
					if ((Get-HostResolutionIPv4 -TargetHostname $hostEntry).IPAddressToString -like $trellisFrontIP) {
						Write-Verbose "`t pass - $hostEntry is present & resolves." -CopyToLog
						$REQ_5_3_PASS = $REQ_5_3_PASS -band $true
					} else {
						Write-Verbose "`t fail - $hostEntry resolves incorrectly." -CopyToLog
						$REQ_5_3_PASS = $REQ_5_3_PASS -band $false
						$FIX_1_5_3_BYPASS = $FIX_1_5_3_BYPASS -or $true
					}
				} else {
					Write-Verbose "`t fail - $hostEntry is missing." -CopyToLog
					$REQ_5_3_PASS = $REQ_5_3_PASS -band $false
				}
			}

			Write-Verbose "`nINFO:`t Checking DNS entries for back server.`n"
			foreach ($hostEntry in $reqDnsEntriesBack) {
				if (Resolve-Host -ComputerName $hostEntry -ErrorAction SilentlyContinue) {
					if ((Get-HostResolutionIPv4 -TargetHostname $hostEntry).IPAddressToString -like $trellisBackIP) {
						Write-Verbose "`t pass - $hostEntry is present & resolves." -CopyToLog
						$REQ_5_3_PASS = $REQ_5_3_PASS -band $true
					} else {
						Write-Verbose "`t fail - $hostEntry resolves incorrectly." -CopyToLog
						$REQ_5_3_PASS = $REQ_5_3_PASS -band $false
					}
				} else {
					Write-Verbose "`t fail - $hostEntry is missing." -CopyToLog
					$REQ_5_3_PASS = $REQ_5_3_PASS -band $false
				}
			}

			if ($REQ_5_3_PASS) {
				Write-Check "[REQ 5.3]`tConfirm DNS entries correct Enabled?`t`tPASS"
				#Write-Fix "[FIX 1.5.3]`tVerify content of $(env:windir)\system32\drivers\etc\hosts"
			} else {
				if ($SelfRepair) {
						if ($FIX_1_5_3_BYPASS) {
							$tmpAns = 1
							Write-Verbose "INFO:`t`tHost file already modified, requires manual repair." -CopyToLog
						} else {
							$tmpAns = Write-Prompt  -Caption "REPAIR: REQ 5.3?" -Message "Would you like to create required entries in hosts file?" -choice "&Yes", "&No" -default 1
						}
						if ($tmpAns -eq '0') {
						
							Add-HostFileComment -Comment "`n#`n#Host FQDN Definitions`n#"
						 	Add-HostFileEntry -IP $([string]$trellisFrontIP) -DNS $([string]($trellisFrontFQDN + " " + ($trellisFrontFQDN.Split('.') | Select -First 1)))
							Add-HostFileEntry -IP $([string]$trellisBackIP) -DNS $([string]($trellisBackFQDN + " " + ($trellisBackFQDN.Split('.') | Select -First 1)))
						
							#
							#  Iterate through frontend entries
							#
							Add-HostFileComment -Comment "`n#`n#Front Aliases`n#"
							$Iteration = 4
							$Qty = ($reqDnsEntriesFront).Count
							do {
								$Qty -= $Iteration
								if ($Qty -lt 0) { 
									$Iteration += $Qty
									$Qty = 0
								}
								Add-HostFileEntry -IP $([string]$trellisFrontIP) -DNS $([string]($reqDnsEntriesFront | Select -First $Iteration -Skip $Qty))
							} while ($Qty -gt 0)
							
							#
							#  Iterate through backend entries
							#
							Add-HostFileComment -Comment "`n#`n#Back Aliases`n#"
							$Iteration = 4
							$Qty = ($reqDnsEntriesBack).Count
							do {
								$Qty -= $Iteration
								if ($Qty -lt 0) { 
									$Iteration += $Qty
									$Qty = 0
								}
								Add-HostFileEntry -IP $([string]$trellisBackIP) -DNS $([string]($reqDnsEntriesBack | Select -First $Iteration -Skip $Qty))
							} while ($Qty -gt 0)
							Write-Check "[REQ 5.3]`tHosts File Entries Updated.`t`t`tFIXED"
							$REQ_5_3_PASS = $true
						} else {
							Write-Check "[REQ 5.3]`tHosts File Entries Updated.`t`t`tFAIL" -Failed
						}
				} else {
					Write-Check "[REQ 5.3]`tConfirm DNS entries correct Enabled?`t`tFAIL" -Failed
				}
			}
		}
		#####  REQ 5.3 - DNS Entry Validations

		#
		#  REQ 5.5 - Confirm Length of Hostname <= Netbios
		#
		if (Get-RunTest -TestGroup 5 -TestNumber 5) {
			$tmpHostName = ([System.Net.Dns]::GetHostEntry([string]$env:computername).HostName).Split('.')[0]
			if ($tmpHostName.Length -gt 15) {
				Write-Check "[REQ 5.5]`tHostname does not exceed NetBIOS name?`t`tFALSE" -Failed
				Write-Verbose "WARNING:`tHostnames should be shorter than 15 char."
				$REQ_5_5_PASS = $false
			} else {
				Write-Check "[REQ 5.5]`tHostname does not exceed NetBIOS name?`t`tPASS"
				$REQ_5_5_PASS = $true
			}
		}
		#####

		#
		#  REQ 5.51 - Connectivity Validations
		#
		if (Get-RunTest -TestGroup 5 -TestNumber 51) {
			if (Test-Connection -ComputerName $env:COMPUTERNAME -BufferSize 16 -Count 1 -ErrorAction Continue -Quiet) {
				#
				#  Verify Connectivity to Front Server
				#
				if ((Test-Connection -ComputerName "trellis-front" -Quiet -TimeToLive 1 -Delay 1 -Count 2) -and (Test-Connection -ComputerName $trellisFrontIP -Quiet -TimeToLive 1 -Delay 1 -Count 2)) {
					Write-Check "[REQ 5.51]`tConfirm Connectivity to Front Server?`t`tPASS"
				} else {
					Write-Check "[REQ 5.51]`tConfirm Connectivity to Front Server?`t`tFAIL" -Failed
				}
				#####
			} else {
					Write-Verbose "INFO:`t`tConnectivity failed, there appears to be a networking fault."
					Write-Check "[REQ 5.51]`tConfirm Connectivity to Front Server?`t`tFAIL" -Failed
			}
		}
		#####  REQ 5.51 - Connectivity Validations
		
		#
		#  REQ 5.52 - Connectivity Validations
		#
		if (Get-RunTest -TestGroup 5 -TestNumber 52) {
			if (Test-Connection -ComputerName $env:COMPUTERNAME -BufferSize 16 -Count 1 -ErrorAction Continue -Quiet) {
				#
				#  Verify Connectivity to Back Server
				#
				if ((Test-Connection -ComputerName "trellis-back" -Quiet -TimeToLive 1 -Delay 1 -Count 2) -and (Test-Connection -ComputerName $trellisBackIP -Quiet -TimeToLive 1 -Delay 1 -Count 2)) {
					Write-Check "[REQ 5.52]`tConfirm Connectivity to Back Server?`t`tPASS"
				} else {
					Write-Verbose "INFO:`t`tConnectivity failed, there appears to be a networking fault."
					Write-Check "[REQ 5.52]`tConfirm Connectivity to Back Server?`t`tFAIL" -Failed
				}
				#####
			} else {
					Write-Check "[REQ 5.52]`tConfirm Connectivity to Back Server?`t`tFAIL" -Failed
			}
		}
		#####  REQ 5.52 - Connectivity Validations

		#
		#  REQ 5.7 - Front & Back Time Zones Match
		#
		if (Get-RunTest -TestGroup 5 -TestNumber 7) {
			# Write-Verbose "INFO:`t`tTime Zone $((Get-RegionInfo).TimeZone)"
			<#
			try {
				if (Test-Connection -ComputerName 'trellis-front' -ErrorAction Stop -BufferSize 16 -Count 1 -Quiet) {
					if (Test-Connection -ComputerName 'trellis-back' -BufferSize 16 -Count 1 -ErrorAction Continue -Quiet) {
						if ((Get-RegionInfo -TargetServer 'trellis-front').TimeZone -eq (Get-RegionInfo -TargetServer 'trellis-back').TimeZone) {
							Write-Check "[REQ 5.7]`tTime Zones on Front & Back Servers Match.`tPASS"	
						} else {
							Write-Check "[REQ 5.7]`tTime Zones on Front & Back Servers Match.`tFAIL" -Failed
						}
					} else {
						Write-Check "[REQ 5.7]`tTime Zones on Front & Back Servers Match.`tN/A" -Failed
					}
				} else {
					Write-Check "[REQ 5.7]`tTime Zones on Front & Back Servers Match.`tN/A" -Failed	
				}
			} catch {
				Write-Check "[REQ 5.7]`tTime Zones on Front & Back Servers Match.`tN/A" -Soft
			}
			#>
		}
		##### REQ 5.7 - Front & Back Time Zones Match
		
		#
		#  REQ 5.8 - Front & Back Time Servers Match
		#
		if (Get-RunTest -TestGroup 5 -TestNumber 8) {
			Write-Verbose "INFO:`t`tTime Server $((Get-TimeServer -ComputerName 'localhost').TimeServer)"
		}
		#####
		
		#
		#  REQ 5.9 - Verify Simple TCP/IP Feature
		#
		if (Get-RunTest -TestGroup 5 -TestNumber 9) {
			Write-Check "[REQ 5.9]`tSimple TCP/IP Feature Installed? NOT IMPLEMENTED `tN/A" -Soft
		}
		#####
		
		#
		#  REQ 5.10 - Verify Ports Free
		#
		if (Get-RunTest -TestGroup 5 -TestNumber 10) {
			$REQ_5_10_PORTS_FRONT = "80","443","5556","5559","6010","6443","6700","6701","7001", "7002", "7003", "7005", "7011", "7012", "7028","7890","8001","8011","8012","8088"
			$REQ_5_10_PORTS_BACK = "1158","1521","3938","5520","5556","5559","6701","7013","7014","7022","7023","7024","7026","7027","7031","8080","31313","36467","37869","46982"
			if ($isTrellisFrontServer) { 
				$REQ_5_10_PORTS = $REQ_5_10_PORTS_FRONT
			} else {
				$REQ_5_10_PORTS = $REQ_5_10_PORTS_BACK
			}
			$REQ_5_10_PASS = $true
			
			Write-Verbose "`nPort Bind Testing:`n" -CopyToLog
			ForEach ($port in $REQ_5_10_PORTS) {
				$REQ_5_10_PASS = $REQ_5_10_PASS -and (Get-PortCanBind -PortNum $port -Protocol tcp)
				Write-Verbose "`tPort: $port `tCan Bind? $((Get-PortCanBind -PortNum $port -Protocol tcp))" -CopyToLog
			}
			
			if ($REQ_5_10_PASS) {
				Write-Check "[REQ 5.10]`tNo service port conflicts.`t`t`tPASS"
			} else {
				Write-Check "[REQ 5.10]`tNo service port conflicts.`t`t`tFAIL" -Failed
			}
		}
		#####
		
		#
		#  REQ 5.11 - Verify IIS Not Installed
		#
		if (Get-RunTest -TestGroup 5 -TestNumber 11) {
			if (Get-IisWebServerRunning) {
				Write-Check "[REQ 5.11]`tIIS Service not present/running.`t`tFAIL" -Failed
			} else {
				Write-Check "[REQ 5.11]`tIIS Service not present/running.`t`tPASS"
			}
		}
		#####
	}	
	#####  REQ 5.0 - Network Checks (Group)

	#
	#  REQ 7.0 - Oracle Licensing Checks (Group)
	#
	Write-Verbose "`n###############################################################################`n#`tOracle License Checks`n###############################################################################`n"
	if (Get-RunTest -TestGroup 7 -TestNumber 0) {
		#
		#  REQ 7.1 - CPU Core Count
		#
		if (Get-RunTest -TestGroup 7 -TestNumber 1) {
			$REQ_7_1_SOCKET_LIMIT = 4
			if ((Get-CPUs).Sockets -gt $REQ_7_1_SOCKET_LIMIT) {
				Write-Verbose "INFO:`t`tProcessor count exceeds base platform license, ensure CPU License Pack applied."
				$REQ_7_1_PASS = $false;
				Write-Check "[REQ 7.1]`tCPU Count Meets License Limit.`t`t`tFAILED" -Failed #-Suppress
			} else {
				$REQ_7_1_PASS = $true;
				Write-Check "[REQ 7.1]`tCPU Count Meets License Limit.`t`t`tPASS" #-Suppress
			}
		}
		#####  REQ 7.1 - CPU Core Count
	}
	#####  REQ 7.0 - Oracle Licensing Checks (Group)

	#
	#  REQ 10.0 - Support Software (Group)
	#
	Write-Verbose "`n###############################################################################`n#`tSupport Software Checks`n###############################################################################`n"
	if (Get-RunTest -TestGroup 10 -TestNumber 0) {
		#
		#  REQ 10.1 - Sysinternals Tools
		#
		if (Get-RunTest -TestGroup 10 -TestNumber 1) {
			$REQ_10_1_PASS = Get-SysInternalBundle -SourcePath .\$ConfResourceBase\sysinternals -DestinationPath $env:windir
			if ($REQ_10_1_PASS) {
				Write-Check "[REQ 10.1]`tSysinternal Bundle Installed.`t`t`tPASS"
			} else {
				if ($SelfRepair) {
					$tmpAns = Write-Prompt  -Caption "REPAIR: REQ 10.1?" -Message "Would you like to install required tools?" -choice "&Yes", "&No" -default 1
					if ($tmpAns -eq '0') {
						Deploy-SysInternalBundle -SourcePath .\$ConfResourceBase\sysinternals -DestinationPath $env:windir
						Write-Check "[REQ 10.1]`tSysinternal Bundle Installed.`t`t`tPASS"
						$REQ_10_0_PASS = $true
					}
				} else {
					Write-Check "[REQ 10.1]`tSysinternal Bundle Installed.`t`t`tFAIL" -Failed
				}
			}
			#####
		}
	}
	##### REQ 10.0 - Support Software (Group)

	Write-Verbose "`n###############################################################################`n#`tExtra Details`n###############################################################################`n`n" -CopyToLog
	Write-Verbose "Hosts File:" -CopyToLog
	$dumpHosts = Get-Content $env:windir\system32\drivers\etc\hosts
	Write-Verbose "$dumpHosts"  -CopyToLog
	#Get-ChildItem -filter "file?.txt" | % { Get-Content $_ -ReadCount 0 | Add-Content .\combined_files.txt }
	
	
	<#
	Write-Verbose "$([string](Get-Process))"
	Write-Verbose "$([string](Get-PSDrive))" -CopyToLog
	Write-Verbose "$([string](Get-Host))" -CopyToLog
	Write-Verbose "$([string](Get-HostFileEntries))" -CopyToLog
	#>
	
	#
	#
	<#
	if($TargetCredential) { 
	    $AllLocalAccounts = Get-WmiObject -Class Win32_UserAccount -Namespace "root\cimv2" -Filter "LocalAccount='$True'" -ComputerName $Computer -Credential $TargetCredential -ErrorAction Stop 
	} else { 
	    $AllLocalAccounts = Get-WmiObject -Class Win32_UserAccount -Namespace "root\cimv2" -Filter "LocalAccount='$True'" -ComputerName $Computer -ErrorAction Stop 
	}
	Write-Verbose "$AllLocalAccounts"
	#####>
	
	Write-Verbose "`n###############################################################################`n"
	#
	#  Open Log File with System Default Application
	#
	if ($OpenOutput) {
		Write-Verbose "INFO:`t Opening log file."
		Invoke-Item $LogFile
	}
	#####
}
#####
