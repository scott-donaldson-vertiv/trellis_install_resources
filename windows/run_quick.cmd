::---------------------------------------------------------------------------------------------
::
::      Copyright (c) 2010-2015, Scott Donaldson
::      All rights reserved.
::
::      Redistribution and use in source and binary forms, with or without
::      modification, are permitted provided that the following conditions are met:
::      1. Redistributions of source code must retain the above copyright
::         notice, this list of conditions and the following disclaimer.
::      2. Redistributions in binary form must reproduce the above copyright
::         notice, this list of conditions and the following disclaimer in the
::         documentation and/or other materials provided with the distribution.
::      3. All advertising materials mentioning features or use of this software
::         must display the following acknowledgement:
::         This product includes software developed by the Scott Donaldson.
::      4. Neither the name of the Scott Donaldson nor the
::         names of its contributors may be used to endorse or promote products
::         derived from this software without specific prior written permission.
::
::      THIS SOFTWARE IS PROVIDED BY SCOTT DONALDSON ''AS IS'' AND ANY
::      EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
::      WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
::      DISCLAIMED. IN NO EVENT SHALL SCOTT DONALDSON BE LIABLE FOR ANY
::      DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
::      (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
::      LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
::      ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
::      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
::      SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
::
::---------------------------------------------------------------------------------------------
@echo off

:: General
SET	"SERVER_FQDN=example.emersonnetworkpower.com"
SET "SERVER_PATH=download/current/trellis/prereq"
SET "SERVER_PROTO=https"
SET "SERVER_PORT=443"
SET "PACKAGE_FILE=Trellis.cab"
SET "BITS_FLAGS=/PRIORITY foreground /SETMAXDOWNLOADTIME 30"
::::::

:: Payload
::
:: - Payload encoded in base64 format
::
::set "PAYLOAD_ZIP = x"
::::::

::
:: Save Current Directory & Clear Console
::
pushd %cd%
cls
::::::

::
::  Check Running Privileges
::
:: Ensure ADMIN Privileges
:: adaptation of https://sites.google.com/site/eneerge/home/BatchGotAdmin and http://stackoverflow.com/q/4054937
:: Check for ADMIN Privileges
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
IF '%ERRORLEVEL%' NEQ '0' (
    :: Get ADMIN Privileges
    echo Set UAC = CreateObject^("Shell.Application"^) > "%TEMP%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%TEMP%\getadmin.vbs"
    "%TEMP%\getadmin.vbs"
    del "%TEMP%\getadmin.vbs"
	exit /B
) ELSE (
    :: Got ADMIN Privileges
    pushd "%cd%"
    cd /d "%~dp0"
)
::::::

::
::  Fetch Latest Script Bundle
::
::echo [Info]: Checking for script bundle.
::IF NOT EXIST %PACKAGE_FILE% (
::	echo [Info]: Downloading installation package.
::	bitsadmin /transfer TrellisPrereq %BITS_FLAGS%  %SERVER_PROTO%://%SERVER_FQDN%/%SERVER_PATH%/%PACKAGE_FILE% "%cd%\%PACKAGE_FILE%"
	::
	::  Confirm installer file present now
	::
	::IF NOT EXIST %PACKAGE_FILE% (
	::	echo [Error]: Download failed, please try again.
	::	bitsadmin /Complete TrellisPrereq
	::	SET "ERROR_LEVEL=3"
	::	GOTO :ERROR
	::)
::)
::::::

::
::  Check ENABLEEXTENSIONS is set (Windows NT family)
::
VERIFY OTHER 2>nul
SETLOCAL ENABLEEXTENSIONS
IF ERRORLEVEL 1 ECHO Unable to enable extensions
::::::

::
::  Check for payload variable
::
IF DEFINED PAYLOAD_ZIP ( 
  echo [info] Payload embedded.
  GOTO :PAYLOAD_EXTRACT
) ELSE (
  GOTO :BOOTSTRAP
)
::::::

::
::  Drop Payload
::
:PAYLOAD_EXTRACT
mkdir %TEMP%\emersonnetworkpower\PorServices\PreCheck
IF NOT EXIST %TEMP%\emersonnetworkpower\PorServices\PreCheck (
  echo [error]: Failed to create directory for payload. Script cannnot continue.
  goto :ERROR
  )

:: Write payload to file
echo %PAYLOAD_ZIP% > %TEMP%\emersonnetworkpower\ProServices\PreCheck\payload.b64

IF NOT EXIST %TEMP%\emersonnetworkpower\PorServices\PreCheck\payload.b64 (
  echo [error]: Failed to create payload file.
  goto :ERROR
  )
:::::

certutil -decode  %TEMP%\emersonnetowrkpower\ProServices\PreCheck\payload.b64  %TEMP%\emersonnetowrkpower\ProServices\PreCheck\payload.zip
::::::

::
::  Extract Script Bundle
::
::IF NOT EXIST %PACKAGE_FILE% (
::	echo [Info]: CAB file missing.
::	SET "ERROR_LEVEL=4"
::	GOTO :ERROR
::)
::mkdir trellis-prereq
::extract /L %CD%\trellis-prereq %PACKAGE_FILE%
::::::

::
::  Main Entry Point
::
:BOOTSTRAP

::
::  Check for Winsat Executable
::
IF NOT EXIST %WINDIR%\System32\winsat.exe (
	echo [Info]: Winsat missing.
	expand .\res\winsat.ex_ %WINDIR%\System32\winsat.exe
	IF NOT EXIST %WINDIR%\System32\winsat.exe (
		echo [Info]: Winsat extraction failed.
		SET "ERROR_LEVEL=4"
		GOTO :ERROR
	)
)
:::::

:: Allow Unrestricted Execution Policy
::powershell -ExecutionPolicy ByPass -Command "&  Set-ExecutionPolicy Unrestricted -Scope LocalMachine -Confirm -Force"

:: Launch Shell
powershell -ExecutionPolicy ByPass -WindowStyle Normal -File .\trellis-precheck.ps1 -SelfRepair -OpenOutput 
::-InstallPath U:
::-Verbose

:: Return to Directory
popd
pause
:: exit

::
::  Things went wrong, clean-up and return.
::
:ERROR
popd
ENDLOCAL
exit /b %ERROR_LEVEL%
::::::