::---------------------------------------------------------------------------------------------
::
::      Copyright (c) 2010-2020, Scott Donaldson
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

::---------------------------------------------------------------------------------------------
:: Script Name:		run.cmd
:: Created: 		2014/05/15
:: Modified: 		2020/07/02
:: Author: 			Scott Donaldson [NETPWR/AVOCENT/UK]
:: Contributors: 	
:: Maintainers: 	Ray Daugherty [NETPWR/AVOCENT/US], Scott Donaldson [NETPWR/AVOCENT/UK]
:: Company: 		Vertiv Infrastructure Ltd.
:: Group: 			Software Delivery, Services
:: Contact: 		global.services.delivery.development@vertivco.com
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

:: Save Current Directory
pushd %cd%
cls

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
powershell -ExecutionPolicy ByPass -WindowStyle Normal 

:: Return to Directory
popd
pause
:: exit

::
::  Things went wrong, clean-up and return.
::
:ERROR
popd
exit /b %ERROR_LEVEL%
::::::