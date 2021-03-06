#---------------------------------------------------------------------------------------------
#
#      Copyright (c) 2014, Avocent, Emerson Network Power
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
#         This product includes software developed by the Inbay Ltd.
#      4. Neither the name of the Inbay Ltd. nor the
#         names of its contributors may be used to endorse or promote products
#         derived from this software without specific prior written permission.
#
#      THIS SOFTWARE IS PROVIDED BY INBAY LTD ''AS IS'' AND ANY
#      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#      WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#      DISCLAIMED. IN NO EVENT SHALL INBAY LTD BE LIABLE FOR ANY
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
# Script Name: Trellis-Prereq
# Created: 2014/05/16
# Author: Scott Donaldson [NETPWR/AVOCENT/UK]
# Company: Emerson Network Power
# Group: Professional Services
# Email:scott.donaldson@emerson.com
#---------------------------------------------------------------------------------------------

function Get-CPUs {
<#
   	.Synopsis
    Get CPU and core counts for licensing.
   	.Description
    This script detects available space required for installation and outputs to an XML file.
   	.Example
    Get-CPU -TargetServer localhost
    .Parameter TargetServer
	The server name to run checks against, default is the running system.
	.Parameter Username
	The user name to run checks against, default is the running user.
	.Link
   		https://www.emersonnetworkpower.com
#>
    param (
	[string]$TargetServer = [Environment]::MachineName,	# Server name
	[string]$Username									# Username
	)
	
    if ($Username) {
        $processors = Get-WmiObject -Computername $TargetServer -Credential $Username win32_processor
	} else {
        $processors = Get-WmiObject -Computername $TargetServer win32_processor
    }
	
	#$processors
	
	$output = @{}
	
	$phyv = Get-WmiObject win32_bios -Computer $TargetServer | Select serialnumber
	if ($phyv -like "*-*" -or $phyv -like "*VM*" -or $phyv -like "*vm*") { 
		$output.ResourceType = "Virtual" 
	} else {
		$output.ResourceType = "Physical"
	}
	
	$output.Name = (@($processors)| % {$_.Name});
	$output.Isa = (@($processors)| % {$_.AddressWidth});
	$output.MaxClockSpeed = (@($processors)| % {$_.MaxClockSpeed});
	$output.CurClockSpeed = (@($processors)| % {$_.CurrentClockSpeed});
	$output.Sockets = @(@($processors) | % {$_.SocketDesignation} | Select-Object -unique).Count;
	
    if (@($processors)[0].NumberOfCores) {
        $output.Cores = @($processors).Count * @($processors)[0].NumberOfCores;
    } else {
        $output.Cores = @($processors).Count;
    }

	if (@($processors)[0].NumberOfLogicalProcessors) {
		$output.Threads = @($processors).Count * @($processors)[0].NumberOfLogicalProcessors;
	} else {
		$output.Threads = (@($processors) | % {$_.NumberOfLogicalProcessors});
	}
	New-Object -TypeName PSObject -Property $output
}