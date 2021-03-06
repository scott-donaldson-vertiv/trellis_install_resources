function Get-ReparsePoint {
<#
   	.Synopsis
    Check for symbolic link.
   	.Description
	Tests whether a given path is a symbolic link (using reparse point).
   	.Example
	Test-ReparsePoint -Path c:\testing
	.Parameter Path
	Path to file/folder to be tested.
	.Link
#>
	[cmdletbinding()]
	param (
		[Parameter(Position=0,Mandatory=$true,HelpMessage="Enter a filename and path",
	ValueFromPipeline=$True)]
	[string]$Path
	)
	Process {
		if (Test-Path $Path) {
  			$file = Get-Item $Path -Force -ErrorAction 0
			New-Object -TypeName PSObject -Property @{
				Path=$Path
	        	ReparsePoint=[bool]($file.Attributes -band [IO.FileAttributes]::ReparsePoint)
	        }
		} else {
			Write-Warning "[Error]: Failed to Find $Path"
		}
	}
}

Function Get-HardLink {
<#
   	.Synopsis
    Check for symbolic link.
   	.Description
	Tests whether a given path is a hardlink.
   	.Example
	Get-HardLink -Path c:\testing
	.Parameter Path
	Path to file/folder to be tested.
	.Link
	http://www.itninja.com/media/scriptlogic/Get-Hardlink.ps1
#>
	[cmdletbinding()]
	param(
	[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a filename and path",
	ValueFromPipeline=$True)]
	$Path
	)
	
	Process {
	    #if a file is piped in get the full file name and path
	    if ($Path.GetType().Name -eq "FileInfo") {
	        $filepath=$Path.fullname
	    }
	    elseif ($Path.GetType().Name -eq "DirectoryInfo") {
	        #Write-verbose "Skipping folder $Path"
	        return
	    }
	    else {
	        #otherwise assume it is a string
	        $filepath=$Path
	    }
	    
	    #Verify path
	    #Write-Verbose "Testing $filepath"
	    if (Test-Path $filepath) {
	        $links=fsutil hardlink list $filepath
	        $count=($links | Measure-Object).Count
	        if ($count -gt 1) {
	            #more than one hard link found
	            #Write-Verbose "Found multiple links"
	            $Multiple=$True
	        }
	        else {
	            $Multiple=$False
	        }
	        
	        New-Object -TypeName PSObject -Property @{
	        Path=$filePath
	        Links=$links
	        Count=$count
	        MultipleLinks=$Multiple
	        }
	    }
	    else {
	        Write-Warning "[Error]: Failed to Find $filepath"
	    }
	}
}

# (18 Oct 2018 - RayD) Add check for 8.3 filename support
function Get-8Dot3FilenameEnabled {
<#
   	.Synopsis
    Check if 8.3 filenames are enabled
   	.Description
	Tests whether 8.3 filename support is enabled (i.e. the registry setting is 0).  Returns true or false
   	.Example
	Get-8Dot3FilenameEnabled
	.Link
#>
	param (
	)
	Process {
		# Check the registry setting for a setting of 0, which means "enable on all volumes".  This is better than just checking if the current volume is enabled, since symbolic links can be used
		$result = (Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem -Name NtfsDisable8dot3NameCreation).NtfsDisable8dot3NameCreation
		if ($result -eq 0) {
			return $True
		} else {
			return $False
		}
	}
}


# (22 Oct 2018 - RayD) Add check for 8.3 filename support being reset in a Global Policy Object
function Get-8Dot3FilenameResetInGPO {
<#
   	.Synopsis
    Check for a global policy resetting the 8.3 filename support
   	.Description
	Tests whether the 8.3 filename support registry setting (NtfsDisable8dot3NameCreation) is modified in a Global Policy Object (GPO).  Returns true if modified in the GPO; otherwise false.
   	.Example
	Get-8Dot3FilenameResetInGPO
	.Link
#>
	param (
	)
	Process {
		return (gpresult /V | findstr "NtfsDisable8dot3NameCreation" | Measure-Object).Count
	}
}