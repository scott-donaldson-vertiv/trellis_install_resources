  ---------------------------------------------------------------------------------------------------------------------------------------------------
  
  License Compliance:
    
  The following software are used in this product and are subject to the Berkeley Software Distribution 4-Clause ("BSD 4-Clause") as attached.
  Emerson Network Power notifies you hereunder that you have the rights to obtain, modify and/or redistribute the source code of such software in
  accordance with the terms and conditions of BSD 4-Clause attached. Therefore, if you obtain such source code, please read carefully the terms and conditions
  of BSD 4-Clause.

  - Iperf

  ---------------------------------------------------------------------------------------------------------------------------------------------------
  
  The following software are used in this product and are subject to the GNU General Public License ("GPL") as attached. 
  Emerson Network Power notifies you hereunder that you have the rights to obtain, modify and/or redistribute the source code of such software in 
  accordance with the terms and conditions of GPL attached. Therefore, if you obtain such source code, please read carefully the terms and conditions 
  of GPL.

  ---------------------------------------------------------------------------------------------------------------------------------------------------
  
  The following software are used in this product and are subject to the GNU Lesser General Public License ("LGPL") as attached.
  Emerson Network Power notifies you hereunder that you have the rights to obtain, modify and/or redistribute the source code of such software in
  accordance with the terms and conditions of LGPL attached. Therefore, if you obtain such source code, please read carefully the terms and conditions
  of LGPL.
  
  - 7-Zip

  ---------------------------------------------------------------------------------------------------------------------------------------------------
  
  The following software are used in this product and are subject to the Microsoft Public License ("Ms-PL") as attached.
  Emerson Network Power notifies you hereunder that you have the rights to obtain, modify and/or redistribute the source code of such software in
  accordance with the terms and conditions of Ms-PL attached. Therefore, if you obtain such source code, please read carefully the terms and 
  conditions of Ms-PL.
  
  - PowerShell Community Extension

  Microsoft Public License (Ms-PL)

  This license governs use of the accompanying software. If you use the software, you accept this license. If you do not accept the license, do not 
  use the software.

  1. Definitions
   The terms "reproduce," "reproduction," "derivative works," and "distribution" have the same meaning here as under U.S. copyright law.
   A "contribution" is the original software, or any additions or changes to the software.
   A "contributor" is any person that distributes its contribution under this license.
   "Licensed patents" are a contributor's patent claims that read directly on its contribution.

  2. Grant of Rights
   (A) Copyright Grant- Subject to the terms of this license, including the license conditions and limitations in section 3, each contributor grants 
   you a non-exclusive, worldwide, royalty-free copyright license to reproduce its contribution, prepare derivative works of its contribution, and 
   distribute its contribution or any derivative works that you create.
   (B) Patent Grant- Subject to the terms of this license, including the license conditions and limitations in section 3, each contributor grants you
   a non-exclusive, worldwide, royalty-free license under its licensed patents to make, have made, use, sell, offer for sale, import, and/or otherwise
   dispose of its contribution in the software or derivative works of the contribution in the software.

  3. Conditions and Limitations
   (A) No Trademark License- This license does not grant you rights to use any contributors' name, logo, or trademarks.
   (B) If you bring a patent claim against any contributor over patents that you claim are infringed by the software, your patent license from such
   contributor to the software ends automatically.
   (C) If you distribute any portion of the software, you must retain all copyright, patent, trademark, and attribution notices that are present in 
   the software.
   (D) If you distribute any portion of the software in source code form, you may do so only under this license by including a complete copy of this 
   license with your distribution. If you distribute any portion of the software in compiled or object code form, you may only do so under a license 
   that complies with this license.
   (E) The software is licensed "as-is." You bear the risk of using it. The contributors give no express warranties, guarantees or conditions. 
   You may have additional consumer rights under your local laws which this license cannot change. To the extent permitted under your local laws, 
   the contributors exclude the implied warranties of merchantability, fitness for a particular purpose and non-infringement.
  
  ---------------------------------------------------------------------------------------------------------------------------------------------------
  
#####
#
# 	Launching
#

To launch the script you have two methods available.

run.cmd 	- 	This will open a PowerShell console that you can interact 
			with and set additional parameters.

run_quick.com 	-	This will run with the default options to provide a quick
			default overview of the system. It will additionally launch
			notepad with the content of the log file.

#####
#
# 	Parameters
#

-Verbose		Verbose will output additional information to the console window, this
			information is the same as written to the log file.
			e.g. trellis-precheck -Verbose

-SelfRepair		SelfRepair will enable repair capabilities, these will still be confirmed 
			individually before bing applied.
			e.g. trellis-precheck -SelfFix

-LogFile <filename>	LogFile allows for the path & filename of the output log to be overriden.
			e.g. trellis-precheck -LogFile .\mylogfile.txt

-TestVersMaj		Main Version to test against, must be used with -TestVersMin
			e.g. trellis-precheck -MajVer 3 -MinVer 2

-TestVersMin		Main Version to test against, must be used with -TestVersMaj
			e.g. trellis-precheck -MajVer 3 -MinVer 3

-TrellisSizing		Specify intended instance size Development, Small, Medium, Large, Enterprise
			e.g. trellis-precheck -TrellisSizing Medium

#####
#
#  Outstanding Issues
#
N/A

#####
#
#  Outstanding Enhancements
#
ENPTCHK-9	Detect Simple TCP/IP Services
ENPTCHK-11	Detect Whether Windows Update Will Restart The System
ENPTCHK-6	Benchmark Secondary Storage when Detected Symlinks
ENPTCHK-13	Create Command Prompt Admin Shortcut to Trellis Folder on Desktop
ENPTCHK-10	Report Output Enhancement to Use HTML5
ENPTCHK-7	Detect Potential Conflicting IP Addresses

#####
#
#  Fixed (v1.6) 2016/03/09
#
ENPTCHK-3	FQDN & Hostname Not Being Placed at Beginning of Generated Hostfile		
ENPTCHK-8	Detect Presence of IIS	Scott Donaldson	
ENPTCHK-12	IPv6 Break Host File Creation	
ENPTCHK-1	IPv6 Addresses Break Test Validations		
ENPTCHK-2	Disk Throughput Test Can Fail Even Though Criteria is Met		
ENPTCHK-5	Trellis 3.4 Has More Stringent UAC Requirements	(Re-opened)

#####
#
#  Fixed (v1.5)
#
ENPTCHK-5	Trellis 3.4 Has More Stringent UAC Requirements
