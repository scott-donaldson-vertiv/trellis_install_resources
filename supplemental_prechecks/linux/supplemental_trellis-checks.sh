#!/bin/bash

#---------------------------------------------------------------------------------------------
#
#      Copyright (c) 2013-2020, Avocent, Vertiv Infrastructure Ltd.
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
#         This product includes software developed by Vertiv.
#      4. Neither the name of the Vertiv nor the
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
# Script Name: 		supplemental_trellis-checks.sh
# Created: 			2013/05/01
# Modified: 		2020/07/02
# Authors:			Scott Donaldson [NETPWR/AVOCENT/UK], Ray Daugherty [NETPWR/AVOCENT/US]
#					Mark Zagorski [NETPWR/AVOCENT/UK] 
# Contributors: 	Richard Golstein [NETPWR/AVOCENT/UK], Chris Bell [NETPWR/AVOCENT/US]
# Maintainers: 		Ray Daugherty [NETPWR/AVOCENT/US], Scott Donaldson [NETPWR/AVOCENT/UK]
# Company: 			Vertiv Infrastructure Ltd.
# Group: 			Software Delivery, Services
# Contact: 			global.services.delivery.development@vertivco.com
#---------------------------------------------------------------------------------------------

#
#  Global Variables
#
#true=true
#false=false

SCRIPT_VERSION=5.0.1		# Bump this for each release
TRELLIS_NEW_INSTALL=		# true if new install, false if upgrade
BACK_OR_FRONT=				# "back" if back server, "front" if front server
DEBUG_MODE=false
RC=fail						# values of pass/fail/skip

ENV_CURRENT_USER=`whoami`	# running user
ENV_REAL_USER=`who am i | awk '{print $1}'`
ENV_HOSTNAME=`hostname`
ENV_ORIGIN_FOLDER=`pwd`

DD_PARAM_FLUSHED=bs=8k count=100k conv=fdatasync
DD_PARAM_CACHED=bs=8k count=100k
DD_OUTFILE=/tmp/output.img

#CFG_OUTPUT_FOLDER=~${ENV_REAL_USER}
#CFG_OUTPUT_TMP_FOLDER=/tmp
CFG_LOGFILE=trellis-precheck_${ENV_HOSTNAME}_`date +%Y%m%d-%H%M`.log
#CFG_LOGFILE_PATH=${CFG_OUTPUT_TMP_FOLDER}/${CFG_LOGFILE}
CFG_LOGFILE_PATH=${ENV_ORIGIN_FOLDER}/${CFG_LOGFILE}
$CFG_OUTPUT_BUNDLE_FOLDER="${CFG_OUTPUT_TMP_FOLDER}/trellis_config"

# The following are used for terminal output
NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'


show_help()
{
echo 'Syntax: trellis_precheck -<h/v/n/u> -d'
echo '       h = show help file'
echo '       v = show script version'
echo '       n = execute tests for a new Trellis install'
echo '       u = execute tests for a Trellis upgrade'
echo '       d = print additional debug info at end of log'
echo
echo 'Description:'
echo ' 		Execute tests to check if the server is ready for a Trellis install or upgrade.  The'
echo '		script will check the hosts file to see if this is the Trellis front server or back server.'
echo ' 		If neither -n nor -u is specified, the script will assume it is an upgrade if it finds the'
echo '		/etc/init.d/trellis folder'
echo 
echo '		The script must be run as root user.  The /etc/hosts file must already have been updated' 
echo '		with the trellis server information.'
}

show_version()
{
	echo "Version is $SCRIPT_VERSION"
}

# function to print a line the log file and/or the terminal
# syntax: print_data -<b|t> string
#    -b = print to both log file and terminal
#    -t = only print to terminal
#    no switch = only print to log file

print_data ()
{	
	if [ $# -gt 0 ]; then
		case $1 in
			-b ) 			echo -e "$2";
							echo -e "$2" > `tty`;;
			-t )			echo -e "$2" > `tty`;;
			* )				echo -e "$1";;
		esac
	fi
}

# same as print_data, except only prints if in debug mode
print_debug ()
{
	if [ "$DEBUG_MODE" = true ]; then
		if [ $# -gt 0 ]; then
			case $1 in
				-b ) 			echo "$2";
								echo -e "$2" > `tty`;;
				-t )			echo -e "$2" > `tty`;;
				* )				echo "$1";;
			esac
		fi
	fi
}

# common function to handle return code from tests
processRC ()
(
	if [ "$RC" = pass ]; then
		print_data "==>Passed"
		print_data -t "$1${GREEN}Passed${NONE}"
	elif [ "$RC" = skip ]; then
		print_data "==>Skipped"
		print_data -t "$1${YELLOW}Skipped${NONE}"
	else
		print_data "==>Failed"
		print_data -t "$1${RED}Fsiled${NONE}"
fi
)

# common function to print the test type in the log file
print_testtype ()
{
print_data " "
print_data "*************************************************************"
print_data "*************************************************************"
print_data " $1"
print_data "*************************************************************"
print_data "*************************************************************"
}

# common function to print the header for the test in the log file
print_header ()
{
print_data "\n*************************************************************"
print_data " $1"
if [ -n "$2" ]; then
	print_data " $2"
fi
if [ -n "$3" ]; then
	print_data " $3"
fi
if [ -n "$4" ]; then
	print_data " $4"
fi
if [ -n "$5" ]; then
	print_data " $5"
fi
if [ -n "$6" ]; then
	print_data " $6"
fi
print_data "*************************************************************"
}

1-51-checkOracleUser()
{
	print_header "[REQ 1.51]  Checking Oracle User is configured correctly" \
				"Confirm line exists: oracle:x:500:500::/home/oracle:/bin/bash" \
				"Note: Does not have to be 500:500"

	RC=pass
	USER_ORACLE=`cat /etc/passwd | grep oracle | grep /home/oracle:/bin/bash | wc -l`
	print_data "`cat /etc/passwd | grep oracle`"
	if [ $USER_ORACLE != 1 ]; then
		RC=fail
	fi
	
	processRC "[REQ 1.51] Checking Oracle User is configured correctly... \t"
}

1-52-checkGroupInfo()
{
	print_header "[REQ 1.52]  Checking Trellis group info in /etc/group" \
					"Confirm line exists: dba:x:501:oracle" \
					"Confirm line exists: oinstall:x:500:" \
					"Note: Does not have to be 501 and 500" \
	
	RC=pass;
	print_data "`cat /etc/group | egrep 'dba|oinstall'`"
	GROUP_dba=`cat /etc/group | grep dba | grep :oracle | wc -l`
	if [ $GROUP_dba != 1 ]; then
		RC=fail
		print_data "Group dba is not configured correctly in /etc/group."
		print_data "If you want to do it manually you will need to run 'groupadd dba' from the command line"
	fi
	
	GROUP_oinstall=`cat /etc/group | grep oinstall | wc -l`
	if [ $GROUP_oinstall != 1 ]; then
		RC=fail
		print_data "Group oinstall is not configured correctly in /etc/group."
		print_data "If you want to do it manually you will need to run 'groupadd oinstall' from the command line"
	fi
	
	processRC "[REQ 1.52] Checking dba and oinstall groups in eto/group... \t"
}

1-53-checkEnvironmentVariables()
{
	print_header "[REQ 1.53]  Checking Oracle user environment variables " \
					"The output should contain the below 4 lines:" \
					"PATH should contain /sbin/ or /usr/sbin" \
					"MW_HOME=/u01/fm/11.1.1.7/" \
					"ORACLE_HOME=/u01/app/oracle/product/12.1.0.2" \
					"ORACLE_SID=orcl"

	print_data "`su - oracle -c 'echo PATH=${PATH}'`"
	print_data "`su - oracle -c 'echo MW_HOME=${MW_HOME}'`"
	print_data "`su - oracle -c 'echo ORACLE_HOME=${ORACLE_HOME}'`"
	print_data "`su - oracle -c 'echo ORACLE_SID=${ORACLE_SID}'`"

	RC=pass

	# (16 Oct 2018 - RayD) Look for /sbin and/or /usr/sbin.  /sbin can be a symbolic link to /usr/sbin.
	ORA_PATH=`su - oracle -c 'echo ${PATH}' | grep -c -e "[:|=]/sbin" -e "[:|=]/usr/sbin"`
	print_data ""
	if [ $ORA_PATH -ne 1 ]; then
		RC=fail
		print_data "Oracle env PATH is NOT configured correctly"
	fi

	ORA_MW_HOME=`su - oracle -c 'echo ${MW_HOME}'`
	if [ $ORA_MW_HOME  != /u01/fm/11.1.1.7/ ]; then
		RC=fail
		print_data "Oracle env MW_HOME is NOT configured correctly"
	fi

	ORA_ORACLE_HOME=`su - oracle -c 'echo ${ORACLE_HOME}'`
	# (27 Sep 2018 - RayD) Change ORACLE_HOME path from 11.2.0 to 12.1.0.2
	if [ $ORA_ORACLE_HOME  != /u01/app/oracle/product/12.1.0.2 ]; then
		RC=fail
		print_data "Oracle env ORACLE_HOME is NOT configured correctly"
	fi

	ORA_ORACLE_SID=`su - oracle -c 'echo ${ORACLE_SID}'`
	if [ $ORA_ORACLE_SID  != orcl ]; then
		RC=fail
		print_data "Oracle env ORACLE_SID is NOT configured correctly"
	fi
	
	processRC "[REQ 1.53] Checking Oracle User environment variables... \t"
}

1-54-checkOraInst()
{
	print_header "[REQ 1.54]  Checking /etc/oraInst.loc" \
					"The output should contain 3 lines" \
					"inventory_loc=/u01/app/oraInventory" \
					"inst_group=oinstall" \
					"3rd line should show -rw-r--r-- permissions and root ownership*"

	RC=pass
	print_data "Contents of /etc/oraInst:"
	print_data "`cat /etc/oraInst.loc`"
	#DIFF_counter=`diff $CFG_OUTPUT_BUNDLE_FOLDER/oraInst.loc /etc/oraInst.loc | wc -l`
	DIFF_counter=0
	if [ $DIFF_counter != 0 ]; then
		RC=fail
		print_data "Automatic check for /etc/oraInst.loc failed!"
	fi
	
	properties=`ls -ld /etc/oraInst.loc`
	permission=`echo $properties | awk '{print $1}' | cut -f1 -d"."`
	ownership=`echo $properties | awk '{print $3}'`
	print_data "$properties"
		
	if [ $permission != -rw-r--r-- ]; then
		RC=fail
		print_data "Permissions on /etc/oraInst.loc are wrong"
	fi
	
	if [ $ownership != root ]; then
		RC=fail
		print_data "Ownership on /etc/oraInst.loc is wrong"
	fi

	processRC "[REQ 1.54] Checking oraInst content & permissions... \t\t"
}

1-55-checkOraTab()
{
	print_header "[REQ 1.55]  Checking /etc/oraInst.loc" "Should show -rw-rw-r-- permissions and oracle oinstall ownership"

	RC=pass
	properties=`ls -ld /etc/oratab`
	permission=`echo $properties | awk '{print $1}' | cut -f1 -d"."`
	ownership=`echo $properties | awk '{print $3}'`
	group_ownership=`echo $properties | awk '{print $4}'`
	print_data "$properties"
	
	if [ $permission != -rw-rw-r-- ]; then
		RC=fail
		print_data "Permissions on /etc/oratab are wrong"
	fi
	if [ $ownership != oracle ]; then
		RC=fail
		print_data "Ownership on /etc/oratab is wrong"
	fi
	if [ $group_ownership != oinstall ]; then
		RC=fail
		print_data "Group ownership on /etc/oratab is wrong"
	fi
	
	processRC "[REQ 1.55] Checking oraTab content & permissions... \t\t"
}


1-59-checkPackages()
{
	print_header "[REQ 1.59]  Checking installed packages"

	RC=pass

	TMP_ERROR_COUNT=0
	CMD_RPM_SEARCH='`rpm -q $i`'
	REQ_1_59_PACKAGES_REQUIRE=""

	for i in $REQ_1_59_PACKAGES; do    
		if [ "$CMD_RPM_SEARCH" != "package $i is not installed" ]; then
			print_data "\tValidate package $i\t- PASS"
		else
			print_data "\tValidate package $i\t- FAIL"
			$REQ_1_59_PACKAGES_REQUIRE="${REQ_1_59_PACKAGES_REQUIRE} ${i}"
			TMP_ERROR_COUNT=`expr $TMP_ERROR_COUNT + 1`
		fi
	done

	if [ "$TMP_ERROR_COUNT" != 0 ]; then
		RC=fail
		print_data "\n$TMP_ERROR_COUNT required packages are not installed. The following commands can be used to install them."
		print_data "yum install ${REQ_1_59_PACKAGES_REQUIRE}" 
	fi
	
	processRC "[REQ 1.59] Checking required packages... \t\t\t"
}

1-60-checkAntPackage()
{
	print_header "[REQ 1.60]  Checking that ANT package is not installed"

	RC=pass
	CMD_RPM_SEARCH=`rpm -q apache-ant`
	print_data "`rpm -q apache-ant`"
	# (19 Sep 2018 - RayD) Changed string in test from ant to apache-ant
	if [ "$CMD_RPM_SEARCH" != "package apache-ant is not installed" ]; then
		RC=fail
		print_data "ANT is installed"
	fi
	
	processRC "[REQ 1.60] Checking ANT package is not installed... \t\t"
}


1-61-checkSysCtl()
{
	print_header "[REQ 1.61]  Checking sysctl.conf is configured correctly"

	RC=pass
	print_data "Contents of /etc/sysctl.conf:"
	print_data "`cat /etc/sysctl.conf`"

	# The first two parameters are static values so the entire line must be compared
	SYSCTRL_PARM="kernel.sem"
	SYSCTRL_PARM_value="250 32000 100 128"
	SYSCTRL_PARM_current=`grep $SYSCTRL_PARM /etc/sysctl.conf | grep -v "#" | tr -d $SYSCTRL_PARM | tr -d "=" | sed 's/^[ \t]*//;s/[ \t]*$//'`
	rows=`grep $SYSCTRL_PARM /etc/sysctl.conf | grep -v "#" | wc -l`

	print_data "Checking $SYSCTRL_PARM parameter"

	if [ $rows == 0 ]; then
		print_data "- WARNING: $SYSCTRL_PARM does not exist in /etc/sysctl.conf, this should have a value of $SYSCTRL_PARM_value"
		RC=fail
	elif [ $rows -ge 2 ]; then 
		print_data "- WARNING: $SYSCTRL_PARM is duplicated in /etc/sysctl.conf, this should have a value of $SYSCTRL_PARM_value"
		RC=fail    
	elif [ $SYSCTRL_PARM_current == $SYSCTRL_PARM_value ]; then
		print_data "- $SYSCTRL_PARM value OK "
	else
		print_data "- WARNING: $SYSCTRL_PARM value is $SYSCTRL_PARM_current, which is different to the required value of '$SYSCTRL_PARM_value' for Trellis"
		RC=fail
	fi

	SYSCTRL_PARM="net.ipv4.ip_local_port_range"
	# (27 Sep 2018 - RayD) Changed value from 65535 to 65500, taken from the 7.3 kickstart
	SYSCTRL_PARM_value="9000 65500"
	SYSCTRL_PARM_current=`grep $SYSCTRL_PARM /etc/sysctl.conf | grep -v "#" | tr -d $SYSCTRL_PARM | tr -d "=" | sed 's/^[ \t]*//;s/[ \t]*$//'`
	rows=`grep $SYSCTRL_PARM /etc/sysctl.conf | grep -v "#" | wc -l`

	print_data "Checking $SYSCTRL_PARM parameter"

	if [ $rows == 0 ]; then
		print_data "- WARNING: $SYSCTRL_PARM does not exist in /etc/sysctl.conf, this should have a value of $SYSCTRL_PARM_value"
		RC=fail
	elif [ $rows -ge 2 ]; then 
		print_data "- WARNING: $SYSCTRL_PARM is duplicated in /etc/sysctl.conf, this should have a value of $SYSCTRL_PARM_value"
		RC=fail    
	elif [ $SYSCTRL_PARM_current == $SYSCTRL_PARM_value ]; then
		print_data "- $SYSCTRL_PARM value OK "
	else
		print_data "- WARNING: $SYSCTRL_PARM value is $SYSCTRL_PARM_current, which is different to the required value of '$SYSCTRL_PARM_value' for Trellis"
		RC=fail
	fi

	#Build Sysctrl parameter list
	SYSCTRL_LIST="fs.aio-max-nr"
	SYSCTRL_LIST="$SYSCTRL_LIST fs.file-max"
	SYSCTRL_LIST="$SYSCTRL_LIST kernel.shmall"
	SYSCTRL_LIST="$SYSCTRL_LIST kernel.shmmax"
	SYSCTRL_LIST="$SYSCTRL_LIST kernel.shmmni"
	SYSCTRL_LIST="$SYSCTRL_LIST net.core.rmem_default"
	SYSCTRL_LIST="$SYSCTRL_LIST net.core.rmem_max"
	SYSCTRL_LIST="$SYSCTRL_LIST net.core.wmem_default"
	SYSCTRL_LIST="$SYSCTRL_LIST net.core.wmem_max"
	# (27 Sep 2018 - RayD) Remove kernel.random.write_wakeup_threshold, which is not in the 7.3 kickstart
	# SYSCTRL_LIST=$SYSCTRL_LIST kernel.random.write_wakeup_threshold

	for i in $SYSCTRL_LIST
	do
	  SYSCTRL_PARM=$i
	  SYSCTRL_PARM_MAX=`grep $SYSCTRL_PARM /etc/sysctl.conf | grep -v "#" | awk '{ print $NF }'`
	  rows=`grep $SYSCTRL_PARM /etc/sysctl.conf | grep -v "#" | wc -l`    
	  
	  print_data "Checking $i parameter"

	  if [ "$SYSCTRL_PARM" = "fs.aio-max-nr" ]; then
		SYSCTRL_PARM_min=1048576
	  elif [ "$SYSCTRL_PARM" = "fs.file-max" ]; then
		SYSCTRL_PARM_min=6815744
	  elif [ "$SYSCTRL_PARM" = "kernel.shmall" ]; then
	# (27 Sep 2018 - RayD) Changed value from 2097152 to 3774873, taken from the 7.3 kickstart
		SYSCTRL_PARM_min=3774873
	  elif [ "$SYSCTRL_PARM" = "kernel.shmmax" ]; then
	# (27 Sep 2018 - RayD) Changed value from 536870912 to 15461882265, taken from the 7.3 kickstart
		  SYSCTRL_PARM_min=15461882265
	  elif [ "$SYSCTRL_PARM" = "kernel.shmmni" ]; then
		SYSCTRL_PARM_min=4096
	  elif [ "$SYSCTRL_PARM" = "net.core.rmem_default" ]; then
		SYSCTRL_PARM_min=262144
	  elif [ "$SYSCTRL_PARM" = "net.core.rmem_max" ]; then
		SYSCTRL_PARM_min=4194304  
	  elif [ "$SYSCTRL_PARM" = "net.core.wmem_default" ]; then
		SYSCTRL_PARM_min=262144  
	  elif [ "$SYSCTRL_PARM" = "net.core.wmem_max" ]; then
		SYSCTRL_PARM_min=1048586  
	# (27 Sep 2018 - RayD) Remove kernel.random.write_wakeup_threshold, which is not in the 7.3 kickstart
	#  elif [ $SYSCTRL_PARM = kernel.random.write_wakeup_threshold ]; then
	#	SYSCTRL_PARM_min=1024  
	  fi
	  
	  if [ $rows == 0 ]; then
		print_data "- WARNING: $SYSCTRL_PARM does not exist in /etc/sysctl.conf, this should have a min value of $SYSCTRL_PARM_min"
		RC=fail
	  elif [ $rows -ge 2 ]; then 
		print_data "- WARNING: $SYSCTRL_PARM is duplicated in /etc/sysctl.conf, this should have a min value of $SYSCTRL_PARM_min"
		RC=fail    
	  elif [ $SYSCTRL_PARM_MAX == $SYSCTRL_PARM_min ]; then
		print_data "- $SYSCTRL_PARM value OK "
	  elif [ $SYSCTRL_PARM_MAX -ge $SYSCTRL_PARM_min ]; then
		print_data "- $SYSCTRL_PARM value OK "
		print_data "- INFO: $SYSCTRL_PARM value is $SYSCTRL_PARM_MAX, which is greater than the required value of $SYSCTRL_PARM_min for Trellis "
	  else
		print_data "- WARNING: $SYSCTRL_PARM value is $SYSCTRL_PARM_MAX, which is less than the required value of $SYSCTRL_PARM_min for Trellis "
		RC=fail
	  fi
	done
	
	processRC "[REQ 1.61] Checking sysctl.conf is configured correctly... \t"
}

1-63-checkPamFile()
{
	print_header "[REQ 1.63]  Checking /etc/pam.d/login is configured correctly" "Confirm line exists containing: /lib64/security/pam_limits.so"

	RC=pass
	print_data "`cat /etc/pam.d/login`"
	print_data "`file /etc/pam.d/login`"
	LOG_CHECK=`grep /lib64/security/pam_limits.so /etc/pam.d/login | wc -l`
	if [ $LOG_CHECK -eq 0 ]; then
		RC=fail
		print_data "Could not find line containing '/lib64/security/pam_limits.so'"
#		print_data "Consider appending /etc/pam.d/login with the contents of $CFG_OUTPUT_BUNDLE_FOLDER/pam.d-login"
	fi
	
	processRC "[REQ 1.63] Checking /etc/pam.d/login is configured correctly... "
}

1-64-checkUmask()
{
	print_header "[REQ 1.64]  Checking oracle user umask" "Confirm umask is set to 000 or 002"

	RC=pass
	print_data "`cat /home/oracle/.bashrc`"
	print_data "`file /home/oracle/.bashrc`"
	UMASK_CHECK=`runuser -l oracle -c 'umask' | egrep "0002|0000" | wc -l`
	if [ $UMASK_CHECK -ne 1 ]; then
		RC=fail
		print_data "Umask should be set to 0000 or 0002 in the /home/oracle/.bashrc file"
	fi
	
	processRC "[REQ 1.64] Checking oracle user umask... \t\t\t"
}

1-65-checkLicenseSymlinks()
{
	print_header "[REQ 1.65]  Checking for Licence server symlinks (back only)" "Confirm links exist in /u02/licensing folder"

	RC=pass
	# (13 Oct 2018 - RayD) Skip test if not 6.x or this is the front server
	# (18 Mar 2020 - RayD) Skip test if this is the front server (i.e. drop 6.x test)
	if [ $BACK_OR_FRONT = back ]; then
	# (27 Sep 2018 - RayD) Change licensing folder to /u02/licensing
		existing_symlinks=`ls -l /u02/licensing | egrep "libcrypto.so.1.0.0 -> /usr/lib/libcrypto.so.1.0.1e|libssl.so.1.0.0 -> /usr/lib/libssl.so.1.0.1e" | wc -l`
		print_data ="`ls -l /u02/licensing | egrep 'libcrypto.so.1.0.0 -> /usr/lib/libcrypto.so.1.0.1e|libssl.so.1.0.0 -> /usr/lib/libssl.so.1.0.1e'`"
		if [ $existing_symlinks -ne 2 ]; then
			RC=fail
			print_data "INFO: You can manually fix this by doing 'mkdir -p /usr/lib/licenseserver && ln -s /usr/lib/libcrypto.so.10 /usr/lib/licenseserver/libcrypto.so.1.0.0 && ln -s /usr/lib/libssl.so.10 /usr/lib/licenseserver/libssl.so.1.0.0' before the install. If you wait until after the install, you will have to delete the auto-generated ones first"    
		fi	
	else 
		RC=skip
		print_data "Skipping symlinks test since this is the front server"
	fi
	
	processRC "[REQ 1.65] Checking for Licence Server symlinks (back only)...\t"
}

1-66-checkRetainedPermissions()
{
	print_header "[REQ 1.66]  Checking file permissions are retained" "Confirm files copied to /tmp retain permissions of -rwxr-xr-x"

	RC=pass
	su - oracle -c 'touch /home/oracle/abc.txt'
	su - oracle -c 'chmod -R 755 /home/oracle/abc.txt'
	properties=`ls -l /home/oracle/abc.txt`
	permission=`echo $properties | awk '{print $1}' | cut -f1 -d"."`
	print_data "Permissions on files created in /tmp = "$permission

	if [ $permission != -rwxr-xr-x ]; then
		RC=fail
	else
		su - oracle -c 'cp /home/oracle/abc.txt /tmp/abc.txt'
		properties=`ls -l /tmp/abc.txt`
		permission=`echo $properties | awk '{print $1}' | cut -f1 -d"."`    
		print_data "Permissions on files copied to /tmp = "$permission
		
		if [ $permission != -rwxr-xr-x ]; then
			RC=fail
		fi
		su - oracle -c 'rm /tmp/abc.txt'
	fi
	su - oracle -c 'rm /home/oracle/abc.txt'
	
	processRC "[REQ 1.66] Checking file permissions are retained...\t\t"
}

1-67-checkCreatedPermissions()
{
	print_header "[REQ 1.67]  Checking /tmp permissions are correct"

	RC=fail
	su - oracle -c touch /tmp/testwrite.txt
	if sudo -u oracle test -f '/tmp/testwrite.txt'; then
		RC = pass
	fi
	
	processRC "[REQ 1.67] Checking /tmp permissions are correct...\t\t"
}

1-68-checkJavaVersion()
(
	print_header "[REQ 1.68]  Checking global Java version"

	RC=pass
	if sudo -u oracle test -e `which java`]; then
		_java=java
		print_data "Java location is $_java"
	elif [[ -n $JAVA_HOME ]] && [[ -x $JAVA_HOME/bin/java ]];  then
		_java=$JAVA_HOME/bin/java
		print_data "Java location is $_java"
	else
		print_data "Java not found."
	fi

	if [ $_java ]; then
		version=$($_java -version 2>&1 | awk -F '' '/version/ {print $2}' | cut -d '.' -f 1,2 )
		if [ $version == 1.7 ] | [ $version == 1.6 ]; then
			RC=pass
		else
			RC=fail
		fi
	else
		RC=fail
	fi
	
	processRC "[REQ 1.68] Checking global Java version...\t\t\t"
)

1-69-checkHomeOracleOwnership()
{
	print_header "[REQ 1.69]  Checking /home/oracle ownership" "Confirm ownership of /home/oracle is oracle:oinstall"
	
	RC=pass
    properties=`ls -ld /home/oracle`
    ownership=`echo $properties | awk '{print $3}'`
    group_ownership=`echo $properties | awk '{print $4}'`
	print_data "$properties"
	
    if [ $ownership != oracle ]; then
        RC=fail
        print_data "Ownership of %ownership on /home/oracle is wrong"
    fi
    if [ $group_ownership != oinstall ]; then
        RC=fail
        print_data "Group ownership of $group_ownership on /home/oracle is wrong"
    fi
	
	processRC "[REQ 1.69] Checking /home/oracle ownership...\t\t\t"
}

1-70-checkSwapFileSpace()
{
	print_header "[REQ 1.70]  Checking swap file space" "Confirm at least 10F free swap file space"

	RC=pass
    swaptotal=`free -h | grep 'Swap:' | awk '{print $2}'`
    swapfree=`free -h | grep 'Swap:' | awk '{print $4}'`
	swapfreenumber=`free -h | grep 'Swap:' | awk '{print $4}' | cut -d 'G' -f 1`
	print_data "There is $swapfree of free swap file space out of $swaptotal total.  You should have at least 10G free before you begin the install/upgrade."
    if [ $swapfreenumber -lt 10 ]; then
        RC=fail
    fi
	
	processRC "[REQ 1.70] Checking swap file space...\t\t\t\t"
}

2-4-checkHDDCapacity()
{
	print_header "[REQ 2.4]   Checking HDD Destination Capacity"

	RC=pass
	
	if [ $TRELLIS_NEW_INSTALL = true ]; then

		print_data 'Verify that server has 300GB Space or the following:'
		print_data ' - /home/oracle = 20GB'
		print_data ' - /tmp = 10GB'
		print_data ' - /u01 = 100GB'
		print_data ' - /u02 = 100GB'
		print_data ' - /u03 = 30GB'
		print_data ' - /u05 = 30GB'
		print_data ' - / = 10GB'
		print_data
		df -h
		print_data
		free -m
		##  Check partition sizes
		##  Using df -kP to get all sizes in 1k blocks for use in size calculations.
		##  The P makes the output in Posix format, so the lines don't get broken if
		##  too long.
		PARTITION_LIST_FULL="/ /home/oracle /tmp /u01 /u02 /u03 /u05"
		PARTITION_LIST_SHORT="/home/oracle|/tmp|/u01|/u02|/u03|/u05"
		PARTITION_SHORT_COUNT=`df | egrep -w $PARTITION_LIST_SHORT | wc -l`
		print_data ""
		print_data "---CHECKING DISK SIZES---"
		#Check for root
		ROOT=`df -kP | awk '{ print $6, $4 }' | grep '/' -w | awk '{ print $2 }'`
		ROOT_MIN_NO_PARTITION=313629081
		ROOT_REAL_NO_PARTITION=314572800
		ROOT_MIN_YES_PARTITION=10391388
		ROOT_REAL_YES_PARTITION=10485760
		print_data "Checking root partition size and determine if partitions exist..."
		if [ -z $ROOT ]; then
		  print_data " - WARNING: Root partition does not exist"
		  RC=fail
		else 
		  if [ $PARTITION_SHORT_COUNT -gt 0 ]; then
			PARTITION_CHECK=y
			print_data " - INFO: Partitions detected"
			if [ $ROOT -lt $ROOT_MIN_NO_PARTITION ]; then
			  ROOT_ABOVE_MIN_NO_PARTITION=n
			else
			  ROOT_ABOVE_MIN_NO_PARTITION=y
			fi    
		  else
			CHECK_DIR_NAME="/"
			CHECK_DIR_MIN=$ROOT_MIN_NO_PARTITION
			CHECK_DIR_REAL=$ROOT_REAL_NO_PARTITION
			PARTITION_CHECK=n  
			if [ $ROOT -lt $ROOT_MIN_NO_PARTITION ]; then
			  ROOT_ABOVE_MIN_NO_PARTITION=n
			  RC=fail      
#			  print_data " - WARNING: Root partition is" `bc -l <<< "scale=2; $ROOT / (1024^2)"`"GB which is less than the" `bc -l <<< "scale=0; $CHECK_DIR_REAL / (1024^2)"`"GB required for Trellis and no other partitions are detected"
			  echo " - WARNING: Root partition is" `bc -l <<< "scale=2; $ROOT / (1024^2)"`"GB which is less than the" `bc -l <<< "scale=0; $CHECK_DIR_REAL / (1024^2)"`"GB required for Trellis and no other partitions are detected"
			  print_data " - INFO: Please provision more space for the root partition or re-partition the Trellis server according to the Trellis installation manual"
			else
			  ROOT_ABOVE_MIN_NO_PARTITION=y
#			  print_data " - SUCCESS: Root partition is" `bc -l <<< "scale=2; $ROOT / (1024^2)"`"GB which is OK for Trellis"      
			  echo " - SUCCESS: Root partition is" `bc -l <<< "scale=2; $ROOT / (1024^2)"`"GB which is OK for Trellis"      
			  if [ $BACK_OR_FRONT = back ]; then
				print_data " - INFO:  If site manager is to be installed, please manually check this partition for additional sizing requirements"     
			  fi
			  
			fi
		  fi
		fi
		print_data ""
		print_data "Checking partition sizes..."
		if [ $PARTITION_CHECK = 'y' ]; then
		  for i in $PARTITION_LIST_FULL
		  do
			  CHECK_DIR_NAME=$i
			  CHECK_DIR_VALUE=`df -kP | awk '{ print $6, $2 }' | grep $CHECK_DIR_NAME -w | awk '{ print $2 }'`
			  print_data "Checking $i partition"
			
			  if [ "$CHECK_DIR_NAME" = "/" ]; then
				CHECK_DIR_MIN=$ROOT_MIN_YES_PARTITION
				CHECK_DIR_REAL=$ROOT_REAL_YES_PARTITION		
			  elif [ "$CHECK_DIR_NAME" = "/home/oracle" ]; then
				CHECK_DIR_MIN=20027801
				CHECK_DIR_REAL=20971520
			  elif [ "$CHECK_DIR_NAME" = "/tmp" ]; then
				CHECK_DIR_MIN=10391388
				CHECK_DIR_REAL=10485760
			  elif [ "$CHECK_DIR_NAME" = "/u01" ]; then
				CHECK_DIR_MIN=103913881
				CHECK_DIR_REAL=104857600
			  elif [ "$CHECK_DIR_NAME" = "/u02" ]; then
				CHECK_DIR_MIN=103913881
				CHECK_DIR_REAL=104857600
			  elif [ "$CHECK_DIR_NAME" = "/u03" ]; then
				CHECK_DIR_MIN=30513561
				CHECK_DIR_REAL=31457280
			  elif [ "$CHECK_DIR_NAME" = "/u05" ]; then
				CHECK_DIR_MIN=30513561      
				CHECK_DIR_REAL=31457280		
			  fi
			
			  if [ -z $CHECK_DIR_VALUE ]; then
				if [ $ROOT_ABOVE_MIN_NO_PARTITION = y ]; then
#				  print_data " - INFO: $CHECK_DIR_NAME partition does not exist, however it should not matter as the ROOT directory is greater than" `bc -l <<< "scale=0; $ROOT_MIN_NO_PARTITION / (1024^2)"`"GB"
				  echo " - INFO: $CHECK_DIR_NAME partition does not exist, however it should not matter as the ROOT directory is greater than" `bc -l <<< "scale=0; $ROOT_MIN_NO_PARTITION / (1024^2)"`"GB"
				else
#				  print_data " - WARNING: $CHECK_DIR_NAME partition does not exist, this should be a minimum of" `bc -l <<< "scale=0; $CHECK_DIR_MIN / (1024^2)"`"GB required for Trellis as the ROOT directory is less than" `bc -l <<< "scale=0; $ROOT_MIN_NO_PARTITION / (1024^2)"`"GB"
				  echo " - WARNING: $CHECK_DIR_NAME partition does not exist, this should be a minimum of" `bc -l <<< "scale=0; $CHECK_DIR_MIN / (1024^2)"`"GB required for Trellis as the ROOT directory is less than" `bc -l <<< "scale=0; $ROOT_MIN_NO_PARTITION / (1024^2)"`"GB"
				  RC=fail
				fi
			  else  
				if [ $CHECK_DIR_VALUE -lt $CHECK_DIR_MIN ]; then
				  echo " - WARNING: $CHECK_DIR_NAME partition is" `bc -l <<< "scale=2; $CHECK_DIR_VALUE / (1024^2)"`"GB which is less than the" `bc -l <<< "scale=0; $CHECK_DIR_REAL / (1024^2)"`"GB required for Trellis, please repartition Trellis server according to the Trellis installation manual"
#				  print_data " - WARNING: $CHECK_DIR_NAME partition is" `bc -l <<< "scale=2; $CHECK_DIR_VALUE / (1024^2)"`"GB which is less than the" `bc -l <<< "scale=0; $CHECK_DIR_REAL / (1024^2)"`"GB required for Trellis, please repartition Trellis server according to the Trellis installation manual"
				  RC=fail
				else
				  print_data " - SUCCESS: $CHECK_DIR_NAME partition is" `bc -l <<< "scale=2; $CHECK_DIR_VALUE / (1024^2)"`"GB which is OK for Trellis"
				  
				  if [ $BACK_OR_FRONT = back -a $CHECK_DIR_NAME = "/u02" ]; then
#					print_data "INFO:  If site manager is to be installed, please manually check this partition for additional sizing requirements"     
					echo "INFO:  If site manager is to be installed, please manually check this partition for additional sizing requirements"     
				  fi
				  
				fi
			  fi    
		  done
		else
		  print_data " - INFO: No partitions detected - Skipping partition checks"
		fi

	# this is an upgrade.  Look for 10G of free TMP space, and either 50GB free if no paritiions, or 25G in /u01 and /u02
	else
		print_data 'Verify that server has 50GB available space and 10GB of /tmp available space, or the following:'
		print_data ' - /tmp = 10GB free'
		print_data ' - /u01 = 22.5GB free'
		print_data ' - /u02 = 22.5GB free'
		print_data ' - / = 5GB free'
		print_data
		df -h
		print_data
		free -m
		##  Check partition sizes
		##  Using df -kP to get all sizes in 1k blocks for use in size calculations.
		##  The P makes the output in Posix format, so the lines don't get broken if
		##  too long.
		PARTITION_LIST_FULL="/ /home/oracle /tmp /u01 /u02"
		PARTITION_LIST_SHORT="/home/oracle|/tmp|/u01|/u02"
		PARTITION_SHORT_COUNT=`df | egrep -w $PARTITION_LIST_SHORT | wc -l`
		print_data ""
		print_data "---CHECKING DISK SIZES---"
		#Check for root
		ROOT=`df -kP | awk '{ print $6, $2 }' | grep '/' -w | awk '{ print $2 }'`
		ROOT_MIN_NO_PARTITION=23357030
		ROOT_REAL_NO_PARTITION=23592960
		ROOT_MIN_YES_PARTITION=5195694
		ROOT_REAL_YES_PARTITION=5242880
		print_data "Checking root partition size and determine if partitions exist..."
		if [ -z $ROOT ]; then
		  print_data " - WARNING: Root partition does not exist"
		  RC=fail
		else 
		  if [ $PARTITION_SHORT_COUNT -gt 0 ]; then
			PARTITION_CHECK=y
			print_data " - INFO: Partitions detected"
			if [ $ROOT -lt $ROOT_MIN_NO_PARTITION ]; then
			  ROOT_ABOVE_MIN_NO_PARTITION=n
			else
			  ROOT_ABOVE_MIN_NO_PARTITION=y
			fi    
		  else
			CHECK_DIR_NAME="/"
			CHECK_DIR_MIN=$ROOT_MIN_NO_PARTITION
			CHECK_DIR_REAL=$ROOT_REAL_NO_PARTITION
			PARTITION_CHECK=n  
			if [ $ROOT -lt $ROOT_MIN_NO_PARTITION ]; then
			  ROOT_ABOVE_MIN_NO_PARTITION=n
			  RC=fail      
#			  print_data " - WARNING: Root partition has" `bc -l <<< "scale=2; $ROOT / (1024^2)"`"GB available which is less than the" `bc -l <<< "scale=0; $CHECK_DIR_REAL / (1024^2)"`"GB required for Trellis upgrades and no other partitions are detected"
			  echo " - WARNING: Root partition has" `bc -l <<< "scale=2; $ROOT / (1024^2)"`"GB available which is less than the" `bc -l <<< "scale=0; $CHECK_DIR_REAL / (1024^2)"`"GB required for Trellis upgrades and no other partitions are detected"
			  print_data " - INFO: Please provision more space for the root partition or re-partition the Trellis server according to the Trellis installation manual"
			else
			  ROOT_ABOVE_MIN_NO_PARTITION=y
#			  print_data " - SUCCESS: Root partition has" `bc -l <<< "scale=2; $ROOT / (1024^2)"`"GB available which is OK for Trellis upgrades"      
			  echo " - SUCCESS: Root partition has" `bc -l <<< "scale=2; $ROOT / (1024^2)"`"GB available which is OK for Trellis upgrades"      
			  if [ $BACK_OR_FRONT = back ]; then
				print_data " - INFO:  If site manager is to be installed, please manually check this partition for additional sizing requirements"     
			  fi  
			fi
		  fi
		fi
		print_data ""
		print_data "Checking partition sizes..."
		if [ $PARTITION_CHECK = 'y' ]; then
		  for i in $PARTITION_LIST_FULL
		  do
			  CHECK_DIR_NAME=$i
			  CHECK_DIR_VALUE=`df -kP | awk '{ print $6, $4 }' | grep $CHECK_DIR_NAME -w | awk '{ print $2 }'`
			  print_data "Checking $i partition"
			
			  if [ "$CHECK_DIR_NAME" = "/" ]; then
				CHECK_DIR_MIN=$ROOT_MIN_YES_PARTITION
				CHECK_DIR_REAL=$ROOT_REAL_YES_PARTITION		
			  elif [ "$CHECK_DIR_NAME" = "/home/oracle" ]; then
				CHECK_DIR_MIN=20027801
				CHECK_DIR_REAL=20971520
			  elif [ "$CHECK_DIR_NAME" = "/tmp" ]; then
				CHECK_DIR_MIN=10391388
				CHECK_DIR_REAL=10485760
			  elif [ "$CHECK_DIR_NAME" = "/u01" ]; then
				CHECK_DIR_MIN=23357030
				CHECK_DIR_REAL=23592960
			  elif [ "$CHECK_DIR_NAME" = "/u02" ]; then
				CHECK_DIR_MIN=23357030
				CHECK_DIR_REAL=23592960
			  elif [ "$CHECK_DIR_NAME" = "/u03" ]; then
				CHECK_DIR_MIN=30513561
				CHECK_DIR_REAL=31457280
			  elif [ "$CHECK_DIR_NAME" = "/u05" ]; then
				CHECK_DIR_MIN=30513561      
				CHECK_DIR_REAL=31457280		
			  fi
			
			  if [ -z $CHECK_DIR_VALUE ]; then
				if [ $ROOT_ABOVE_MIN_NO_PARTITION = y ]; then
				   echo " - INFO: $CHECK_DIR_NAME partition does not exist, however it should not matter as the ROOT directory has greater than" `bc -l <<< "scale=0; $ROOT_MIN_NO_PARTITION / (1024^2)"`"GB available"
#				   print_data " - INFO: $CHECK_DIR_NAME partition does not exist, however it should not matter as the ROOT directory has greater than `bc -l <<< scale=0; $ROOT_MIN_NO_PARTITION / (1024^2)`GB available"
				else
				  echo " - WARNING: $CHECK_DIR_NAME partition does not exist, this should have a minimum of" `bc -l <<< "scale=0; $CHECK_DIR_MIN / (1024^2)"`"GB available for Trellis as the ROOT directory is less than" `bc -l <<< "scale=0; $ROOT_MIN_NO_PARTITION / (1024^2)"`"GB"
#				  print_data " - WARNING: $CHECK_DIR_NAME partition does not exist, this should have a minimum of `bc -l <<< scale=0; $CHECK_DIR_MIN / (1024^2)`GB available for Trellis as the ROOT directory is less than `bc -l <<< scale=0; $ROOT_MIN_NO_PARTITION / (1024^2)`GB"
				  wrong=1
				fi
			  else  
				if [ $CHECK_DIR_VALUE -lt $CHECK_DIR_MIN ]; then
				  echo " - WARNING: $CHECK_DIR_NAME partition has" `bc -l <<< "scale=2; $CHECK_DIR_VALUE / (1024^2)"`"GB available which is less than the" `bc -l <<< "scale=0; $CHECK_DIR_REAL / (1024^2)"`"GB required for Trellis, please repartition Trellis server according to the Trellis installation manual"
#				  print_data " - WARNING: $CHECK_DIR_NAME partition has `bc -l <<< scale=2; $CHECK_DIR_VALUE / (1024^2)`GB available which is less than the `bc -l <<< scale=0; $CHECK_DIR_REAL / (1024^2)`GB required for Trellis, please repartition Trellis server according to the Trellis installation manual"
				  wrong=1
				else
				  echo " - SUCCESS: $CHECK_DIR_NAME partition has" `bc -l <<< "scale=2; $CHECK_DIR_VALUE / (1024^2)"`"GB available which is OK for Trellis"
#				  print_data " - SUCCESS: $CHECK_DIR_NAME partition has `bc -l <<< scale=2; $CHECK_DIR_VALUE / (1024^2)`GB available which is OK for Trellis"
				  
				  if [ $BACK_OR_FRONT = back -a $CHECK_DIR_NAME = "/u02" ]; then
					echo "INFO:  If site manager is to be installed, please manually check this partition for additional sizing requirements"     
				  fi
				  
				fi
			  fi    
		  done
		else
		  print_data " - INFO: No partitions detected - Skipping partition checks"
		fi
	fi	
	
	processRC "[REQ 2.4]  Checking HDD Destination Capacity...\t\t\t"
}

2-7-checkCPUFrequency() {
	print_header "[REQ 2.7]   Checking CPU Frequency" "Confirm a frequency of at least 2.2GHz, and preferably over 2.6GHz"

	RC=pass
	print_data "CPU Details: (contents of /proc/info)"
	print_data "`cat /proc/cpuinfo`"
	print_data " "
	CPU_FREQ="`cat /proc/cpuinfo | grep "cpu MHz" -m 1 | cut -f2 -d":" | cut -f1 -d"." | sed 's/^[ \t]*//;s/[ \t]*$//'`"
	print_data "CPU Frequency = $CPU_FREQ"

	if [ $CPU_FREQ -gt 2200 ]; then

		if [ $CPU_FREQ -gt 2600 ]; then
			print_data "CPU Frequency Optimal Frequency. OK"
		else
			print_data "CPU Frequency Sufficient. OK"
			print_data "INFO: It is recommended that the CPU frequency is greater than 2.6GHz"
		fi
	else
		RC=fail
	fi
	
	processRC "[REQ 2.7]  Checking /home/oracle ownership...\t\t\t"
}

2-9-checkCPUCoreCount() {
	print_header "[REQ 2.9]   Checking CPU Core Count" "Confirm a CPU core count of <= 4"

	RC=pass
	TOTAL_CORES=`nproc`
	print_data "CPU Total Core Count = $TOTAL_CORES"
	if [ $TOTAL_CORES -lt 4 ]; then
		RC=fail
	fi
	
	processRC "[REQ 2.9]  Checking CPU Core Count...\t\t\t\t"
}

3-1-checkVirtualizationDrivers() {
	print_header "[REQ 3.1]  Checking VMWare Tools is installed" "Confirm either vmware-toolbox-cmd or open-vm-tools files exist"
	
	RC=pass
	# (12 Oct 2018 - RayD) Add test open-vm-tools
	if [ "$CUR_VIRTUAL_STATUS" == "Yes" ]; then 
		if [ -e /usr/bin/vmware-toolbox-cmd ]; then
			print_data "VMWare Guest Tools version `vmware-toolbox-cmd -v` installed."	
		else
			if [ -e /usr/bin/open-vm-tools ]; then
				print_data "VMWare Open VM Tools version `open-vm-tools -v` installed."
			else
				RC=fail
				echo "VMWare Guest Tools not detected."	
			fi
		fi
	else
		print_data "Not a virtual machine."
		RC=skip
	fi
	
	processRC "[REQ 3.1]  Checking VMWare Tools is installed...\t\t"
}

3-5-checkRNGDOptions() {
	print_header "[REQ 3.5]  Checking RNGD options configured" "Confirm EXTRAOPTIONS in the rngd service=$ENTROPY_EXTRAOPTIONS"

	RC=pass
	
	if [ "$RELEASE_VERSION" = "6" ]; then
		print_data "`cat /etc/sysconfig/rngd`"

		if [ "$CUR_VIRTUAL_STATUS" == "Yes" ]; then
			RNGD_OPTIONS=`cat /etc/sysconfig/rngd | grep "EXTRAOPTIONS" | grep -v '^#' | cut -f2 -d"="`
			if [ "$RNGD_OPTIONS" != '"'"$ENTROPY_EXTRAOPTIONS"'"' ]; then
				print_data "Please update /etc/sysconfig/rngd with the following line EXTRAOPTIONS=$ENTROPY_EXTRAOPTIONS"
				RC=fail
			fi
		else
			print_data "Not a virtual machine"
			RC=skip
		fi
	else
		print_data "Contents of /usr/lib/systemd/system/rngd.service"
		print_data "`cat /usr/lib/systemd/system/rngd.service`"
		print_data "******"

		if [ "$CUR_VIRTUAL_STATUS" == "Yes" ]; then
			RNGD_OPTIONS=`cat /usr/lib/systemd/system/rngd.service | grep "ExecStart" | grep -v '^#' | cut -f2 -d"="`			
			if [ "$RNGD_OPTIONS" != '"'"$ENTROPY_EXTRAOPTIONS"'"' ]; then
				print_data "Please update /usr/lib/systemd/system/rngd.service with the following line ExecStart=$ENTROPY_EXTRAOPTIONS"
				RC=fail
			fi
		else
			print_data "Not a virtual machine"
			RC=skip
		fi
	fi
	
	processRC "[REQ 3.5]  Checking RNGD options configured...\t\t\t"
}

4-2-checkFirewall() {
	print_header "[REQ 4.2]  Checking firewall disabled" "Confirm iptables off for 6.x systems"

	RC=pass

	# (10 Oct 2018 - RayD) Only do iptables check for 6.x systems
	if [ "$RELEASE_VERSION" = "6" ]; then
		IPTABLES=`service iptables status`
		##  Added for RH6.5 where the status returns trailing special characters
		IPTABLES=`echo $IPTABLES`
		if [ `echo "$IPTABLES" | grep "$IPTABLES_RESULT" | wc -l` != 1 ]; then
			RC=fail
			print_data "If you want to stop the service manually you will need to run 'service iptables stop && chkconfig iptables off' on the command line"
			if [ $RELEASE = "6.5" ]; then
				echo "Once complete please restart the OS for changes to be reflected in the service status"
			fi
		fi
	else
		print_data "Skip iptables check for 7.x systems"
		RC=skip
	fi
	
	processRC "[REQ 4.2]  Checking firewall disabled......\t\t\t"
}


4-3-checkEntropyService() {
	print_header "[REQ 4.3]  Checking RNGD service enabled and autostart" \
					"Confirm RNGD service is enabled and starts with server, and current entropy level"


	RC=pass
	
	ENT=`cat /proc/sys/kernel/random/entropy_avail`
	print_data "Entropy at: $ENT"

	if [ "$RELEASE_VERSION" = "6" ]; then
		print_data "Current rngd service status:"
		print_data "`service rngd status`"
		print_data ""
		print_data "Current rngd startup status:"
		print_data "`chkconfig | grep rngd`"
		print_data ""
		RNGD_STATUS_COUNT=`service rngd status | grep "is running" |  wc -l`
		RNGD_STARTUP=`chkconfig | grep rngd`
		RNGD_STARTUP_COUNT=`echo $RNGD_STARTUP | grep "3:on 4:on 5:on" | wc -l`
	else
		print_data "Current rngd service status:"
		print_data "`systemctl status rngd`"
		print_data ""
		print_data "Current rngd startup status:"
		print_data "`cat /usr/lib/systemd/system/rngd.service`"
		print_data ""
		RNGD_STATUS_COUNT=`systemctl status rngd | grep "(running)" |  wc -l`
		RNGD_STARTUP_COUNT=`cat /usr/lib/systemd/system/rngd.service | grep "ExecStart" | grep -v '^#' | wc -l`
	fi

	if [ "$RNGD_STATUS_COUNT" == 1 ]; then
		print_data "RNGD Service is started"
		
		##  Check entropy levels
		##  Since both the front and back server use Oracle and Oracle installations
		##  entropy is an important part of the puzzle as they use it to encrypt 
		##  various pieces as they go. 150 was the original leve we checked for, 
		##  JJ Everett mentioned that it should be over 200 at the very least
		##  The engineering release notes expect this to be over 1000
		##  There is no "check" needed as this needs to be checked prior to the installation anyway as if the server is rebooted this will be reset to 0.  
		## This script may as well generate some entropy if it is needed, just to be useful.
		if [ $ENT -le 1000 ]; then
			print_data "Entropy less than 1000.... generating more..."
			$ENTROPY
			ENT=`cat /proc/sys/kernel/random/entropy_avail`
			echo "Entropy at: $ENT"
		fi
	else
		print_data "RNGD Service is NOT started"
		RC=fail
		print_data "Starting the entropy service..."
		$ENTROPY
		ENT=`cat /proc/sys/kernel/random/entropy_avail`
		echo "Entropy at: $ENT"
	fi

	if [ "$RNGD_STARTUP_COUNT" == 1 ]; then
		print_data "RNGD Service is set to start correctly"
	else
		print_data "RNGD Service is NOT set to start correctly"
		print_data "This can be set to start by using the command 'chkconfig --levels 345 rngd on'"
		RC=fail
	fi
	
	processRC "[REQ 4.3]  Checking RNGD servce enabled and autostart...\t"
}

4-4-checkSELinux() {
	print_header "[REQ 4.4]  Checking SELinux is disabled"

	RC=pass
	print_data "Contents of /etc/selinux/config:"
	print_data "`cat /etc/selinux/config`"
	SELINUX=`cat /etc/selinux/config | grep "SELINUX=" | grep -v "#" | cut -f2 -d"="`
	if [ "$SELINUX" != "disabled" ]; then
		RC=fail
		print_data "If you want to do it manually you will need to edit /etc/selinux/config and replace the $SELINUX in SELINUX= with disabled"    
	fi
	
	processRC "[REQ 4.4]  Checking SELinux is disabled...\t\t\t"
}

4-5-checkIp6tables() {
	print_header "[REQ 4.5]  Checking ip6tables is disabled"

	RC=pass
	if [ "$RELEASE_VERSION" = "6" ]; then
		IP6TABLES_STATUS=`service ip6tables status`
		print_data "`service ip6tables status`"
		if [ `echo $IP6TABLES_STATUS | grep "ip6tables: Firewall is not running." | wc -l` != 1 ]; then
			RC=fail
			echo "If you want to do it manually you will need to run 'service ip6tables stop && chkconfig ip6tables off' on the command line"   
		fi
	else
		IP6TABLES_STATUS=`systemctl status ip6tables`
		if [ `echo $IP6TABLES_STATUS | grep "Unit ip6tables.service could not be found." | wc -l` != 1 ]; then
			RC=fail
			echo "If you want to stop it manually you will need to run 'systemctl stop ip6tables' on the command line"   
		fi
	fi
	
	processRC "[REQ 4.5]  Checking ip6tables is disabled...\t\t\t"	
}


4-6-checkFirewalld() {
	print_header "[REQ 4.6]  Checking Firewalld is disabled" "Confirm Firewalld service is disabled on 7.x systems."

	RC=pass
	if [ "$RELEASE_VERSION" = "6" ]; then
		print_data "Skipping Firewalld test for 6.x system"
	else
		if [ `echo systemctl status firewalld.service | grep "could not be found" | wc -l` != 1 ]; then
			RC=fail
			echo "If you want to stop it manually you will need to run ''systemctl stop firewalld.service && systemctl disable firewalld.service'' on the command line"   
		fi
	fi
	
	processRC "[REQ 4.6]  Checking Firewalld is disabled...\t\t\t"	
}


5-1-checkNICs ()
{
	print_header "[REQ 5.1]  Checking only 1 NIC enabled" "Confirm there is only 1 routable IP for this server other than 127.0.0.1"

	RC=pass

	print_data "ifconfig:"	
	print_data "`ifconfig`"
	#(15 Oct 2018 - RayD) Change test due to 7.x from 'inet addr:' to 'inet '
	IP_count=`ifconfig | grep "inet " | grep -v "127.0.0.1" | wc -l`
	print_data "The number of IP's found = $IP_count"
	if [ "$IP_count" != 1 ]; then
		RC=fail
	fi
	
	processRC "[REQ 5.1]  Checking only 1 NIC enabled...\t\t\t"	
}

5-2-checkDHCP ()
{
	print_header "[REQ 5.2]  Checking IP address is static" "Confirm DHCP set to static or none"

	RC=pass
	if [ "$RELEASE_VERSION" = "6" ]; then
		# Parsing a line like "eth0      Link encap:Ethernet  HWaddr 09:00:12:90:e3:e5" to extract "eth0"
		NIC="`ifconfig | grep "Link encap" | grep -v lo | awk  -F" "  '{ print $1 }'`"
	else
		# Parsing a line like "eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 9001" to extract "eth0"
		NIC="`ifconfig | grep "flags=" | grep -v lo | awk  -F" "  '{ print $1 }' | awk  -F":"  '{ print $1 }'`"	
	fi
	print_data "NIC=$NIC"
	print_data "Checking the file /etc/sysconfig/network-scripts/ifcfg-${NIC} for a BOOTPROTO value of static or none"
	print_data "`cat /etc/sysconfig/network-scripts/ifcfg-${NIC}`"
	IP_set=`cat /etc/sysconfig/network-scripts/ifcfg-${NIC} | grep "BOOTPROTO" | cut -f2 -d"="`
	if [ $IP_set != 'static' -a $IP_set != '"static"' -a $IP_set != 'none' -a $IP_set != '"none"' ]; then
		RC=fail
	fi
	
	processRC "[REQ 5.2]  Checking IP address is static...\t\t\t"	
}

5-8-checkTime ()
{
	print_header "[REQ 5.8]  Checking Time Zone" "Confirm Time Zone is in the supported time zone list"

	RC=pass
	print_data "Time Zone: $CUR_TIMEZONE"
	print_data "Time Server: $CUR_TIMESERVER"
	
	# (18 Sep 2018 - RayD) Change Timezone test to use CUR_TIMEZONE, which is OS-dependent
	ts_count=`echo $TIMEZONE_LIST | grep -ow $CUR_TIMEZONE | wc -l`

	if [ "$ts_count" != 1 ]; then
		RC=fail
		print_data "Time zone is not one of the supported zones."
	fi
	
	processRC "[REQ 5.8]  Checking Time Zone...\t\t\t\t"	
}


print_debuginfo ()
{
	###############################################################################
	#       DEBUG INFORMATION
	###############################################################################
	print_data "*****************************Process Info***********************************"
	top -b -n 1
	print_data ""
	print_data '**********************Displaying Memory Information*************************'
	/proc/meminfo 
	print_data ""
	print_data "***************************Displaying /etc/fstab****************************"
	cat /etc/fstab
	print_data ""
	print_data "**************************Displaying NUMA Topology**************************"
	if [ "`numactl` | grep 'command not found' | wc -l" -eq 0 ]; then
		numactl --hardware
	else
		print_data "No NUMA information"
	fi
	print_data ""
	print_data "************************Displaying Huge Page Support************************"
	sysctl -a | grep huge
	print_data ""
	print_data "***********************Transparent Huge Pages Enabled***********************"
	if [ -f /sys/kernel/mm/redhat_transparent_hugepage/enabled ]; then
		cat /sys/kernel/mm/redhat_transparent_hugepage/enabled
	elif [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
		cat /sys/kernel/mm/transparent_hugepage/enabled
	else
		print_data "No hugepage information"	
	fi
	print_data
	print_data "*************************Displaying System JDK/JRE**************************"
	java -version
	print_data ""
	print_data JAVA_HOME=$JAVA_HOME
	print_data MW_HOME=$MW_HOME
	print_data ""
	print_data '****************************************************************************'
	print_data ""
}


#**************************************************************************************************************************************
# Design:
# - Check for root user, and exit if not
# - Process the arguments, and display help file and exit if wrong # of arguments
# - Determine if new install or upgrade
# - Parse the etc/hosts file, and exit if can't parse trellis-front and trellis-back
# - Determine if this if front or back server, and exit it can't
# - Set up the log file
# - Display system info
# - Perform tests
#
# Each test is set up the same way for consistency and as a model to follow for additional tests:
# 1) Create a function.  Add it to the list of functions being executed at the bottom of this script
# 2) Use print_header to print a header section in the output log with up to 6 lines in the header (see test 1.51 as an example of how to do this)
# 3) Perform the test, which should set the global variable RC (return code) to one of 3 values: pass/fail/skip
# 4) Call ProcessRC to write a result line to both the log file and console
#**************************************************************************************************************************************

#**************************************************************************************************************************************
# Check for root user, and exit if not
#**************************************************************************************************************************************
if [ $ENV_CURRENT_USER != root ]; then
    echo -n '[Info]: Script not launched by root user.'
    if [ `id -u` -eq 0 ]; then
			echo -n '[Info]: Script elevated with sudo.'
	else
		echo -n '[Error]: Script neither elevated with sudo or run by root, cannot continue.'
		exit 1
	fi
fi

#**************************************************************************************************************************************
# Process the arguments, and display help file and exit if wrong # of arguments
#**************************************************************************************************************************************

# Check for 0-2 arguments. 
if [ "$#" -gt 2 ]; then
    show_help
	exit -1
fi

# Process argument 1, if specified
if [ "$#" -gt 0 ]; then
	case $1 in
		-h | --help ) 	show_help
						exit;;
		-v )			show_version
						exit;;
		-n )			TRELLIS_NEW_INSTALL=true;;
		-u ) 			TRELLIS_NEW_INSTALL=false;;
		-d )			DEBUG_MODE=true;;
		* )				show_help
						exit;;
	esac
fi

# Process argument 2, if specified
if [ "$#" -eq 2 ] && [ "$2" -eq "-d"]; then
    DEBUG_MODE=true
fi


#**************************************************************************************************************************************
# Determine if new install or upgrade
#**************************************************************************************************************************************

# If neither -n or -u were specified, assume this is an upgrade if the /etc/init.d/trellis file is found
if [ -z "$TRELLIS_NEW_INSTALL" ] && [ -e /etc/init.d/trellis ]; then
    TRELLIS_NEW_INSTALL=false
fi

# If upgrading, find the current Trellis version
if [ "$TRELLIS_NEW_INSTALL" = false ]; then 
	TRELLIS_INSTALLED_VERSION=`cat /u01/trellis/trellis.version | grep trellis.version | cut -f2 -d=`	
fi


#**************************************************************************************************************************************
# Parse the etc/hosts file, and exit if can't parse trellis-front and trellis-back
#**************************************************************************************************************************************
  
if [ `cat /etc/hosts | grep trellis-front -c` = 1 ]; then  
    DETECTED_FRONT_CHECK=`ping trellis-front -c 1 | grep PING`
    DETECTED_FRONT_IP=`echo $DETECTED_FRONT_CHECK | awk '{ print $3 }' | tr -d '(' | tr -d ')'`   
	# more than one row can have the ip address.  Assume the first such row has the front host name as the 2nd argument
	DETECTED_FRONT_FIRSTROWWITHIP=`cat /etc/hosts | grep $DETECTED_FRONT_IP -m 1`
    DETECTED_FRONT_NAME=`echo $DETECTED_FRONT_FIRSTROWWITHIP | awk '{ print $2 }'`
else
 	echo -n '[Error]: Could not find trellis-front in /etc/hosts file'
	exit -1
fi
 
if [ `cat /etc/hosts | grep trellis-back -c` = 1 ]; then  
	DETECTED_BACK_CHECK=`ping trellis-back -c 1 | grep PING`
    DETECTED_BACK_IP=`echo $DETECTED_BACK_CHECK | awk '{ print $3 }' | tr -d '(' | tr -d ')'`  
	# more than one row can have the ip address.  Assume the first such row has the back host name as the 2nd argument	
	DETECTED_BACK_FIRSTROWWITHIP=`cat /etc/hosts | grep $DETECTED_BACK_IP -m 1`
    DETECTED_BACK_NAME=`echo $DETECTED_BACK_FIRSTROWWITHIP | awk '{ print $2 }'`  
else
 	echo -n '[Error]: Could not find trellis-back in /etc/hosts file'
	exit -1
fi

#**************************************************************************************************************************************
# Determine if this is front or back server, and exit if can't determine
#**************************************************************************************************************************************

THIS_HOST=`hostname -f`
THIS_HOST_SHORT=`hostname -s`
THIS_IP=`hostname -I`

if [ $THIS_IP = "$DETECTED_FRONT_IP" ]; then
	BACK_OR_FRONT=front
elif [ $THIS_IP = "$DETECTED_BACK_IP" ]; then
	BACK_OR_FRONT=back
else
	echo -n '[Error]: Could not determine if front or back by comparing this ip '$THIS_IP' to trellis-front '$DETECTED_FRONT_IP' or trellis-back '$DETECTED_FRONT_IP
	exit -1
fi


#**************************************************************************************************************************************
# Set up the log file
#**************************************************************************************************************************************
touch ${CFG_LOGFILE_PATH}
chmod 775 ${CFG_LOGFILE_PATH}
chown $ENV_REAL_USER:`id -gn ${ENV_REAL_USER}` ${CFG_LOGFILE_PATH}


#**************************************************************************************************************************************
# Display system info
#**************************************************************************************************************************************


# Determine OS and release
OSWORD=`cat /etc/redhat-release | awk '{print $1}'`
if [ $OSWORD == Centos ]; then
	OSNAME=Centos
	RELEASE=`cat /etc/redhat-release | awk '{print $4}'`
	RELEASE_VERSION=`cat /etc/redhat-release | awk '{print $4}' | cut -f1 -d"."`
else
	OSNAME=RHEL
	RELEASE=`cat /etc/redhat-release | awk '{print $7}'`
	RELEASE_VERSION=`cat /etc/redhat-release | awk '{print $7}' | cut -f1 -d"."`
fi
if [ -z $RELEASE_VERSION ]; then
    echo -n '[Info]: Could not determine OS release.  Assume 7'
	RELEASE_VERSION=7
fi

# Determine 32 vs 64 bit
ARCHITECTURE=`uname -m`
if [ "$ARCHITECTURE" = "x86_64" ]
then 
    CUR_OS="`cat /etc/redhat-release` [64 Bit]"
elif [$ARCHITECTURE = i686 ]; then
    CUR_OS="`cat /etc/redhat-release` [32 Bit]"
else
    CUR_OS="`cat /etc/redhat-release`"
fi

CUR_PROCESSOR="`cat /proc/cpuinfo | grep "model name" -c` x `cat /proc/cpuinfo | grep "model name" -m 1 | cut -f2 -d":"` (`lscpu | grep "Core(s) per socket" | cut -f2 -d":" | sed 's/^[ \t]*//;s/[ \t]*$//'` core)"
CUR_TOTAL_CORES=`nproc`
CUR_MEMORY="`bc -l <<< "scale=2; $(cat /proc/meminfo | grep MemTotal | tr -cd '[[:digit:]]') / (1024^2)"` GB"

# Determine if virtual server
if [ -e /usr/sbin/virt-what ];
then 
    CUR_VIRTUAL_TYPE=`virt-what`
    
    if [ -z "$CUR_VIRTUAL_TYPE" ]
    then
        CUR_VIRTUAL_STATUS="No"
		CUR_SERVER_TYPE="Physical"
        CUR_VIRTUAL_SUMMARY="$CUR_SERVER_TYPE"	
    else
	    CUR_VIRTUAL_STATUS="Yes"
		CUR_SERVER_TYPE="Virtual"
        CUR_VIRTUAL_SUMMARY="$CUR_SERVER_TYPE ($CUR_VIRTUAL_TYPE)"		
	fi
else
    #This may not be the case, however we need to find another way to determine if its virtual
    CUR_VIRTUAL_STATUS="No"
    CUR_SERVER_TYPE="Physical"
    CUR_VIRTUAL_SUMMARY="$CUR_SERVER_TYPE"		
fi

#Time Server and Zone information
# (12 Oct 2018 - RayID) Time commands changed in 7.x
if [ $RELEASE_VERSION = "6" ]; then
	CUR_TIMEZONE=`cat /etc/sysconfig/clock | grep ZONE | cut -f2 -d '=' | sed 's/[\"]//g'`
	CUR_TIMESERVER=`cat /etc/ntp.conf | grep server | grep -v \# | cut -f2 -d" " | sed ':a;N;$!ba;s/\n/ /g' | sed 's/ /\n\t                  /g'`
else
	CUR_TIMEZONE=`timedatectl | grep 'Time zone' | awk '{print $3}'`
	if [ -x "/etc/ntp.conf" ]; then
		CUR_TIMESERVER=`ntpq -p | grep -v 'refid' | grep -v '=====' | cut -f1 | sed ':a;N;$!ba;s/\n/ /g' | sed 's/ /\n\t                  /g'`
	else	
		CUR_TIMESERVER="No time server"
	fi
fi
CUR_DATE=`date`


#  Redirect Output to Log File by Default
exec > ${CFG_LOGFILE_PATH} 2>&1

print_data -b "###############################################################################"
print_data -b "#"
print_data -b "#       Trellis 5.x Pre-Install Report (Version: $SCRIPT_VERSION)"
print_data -b "#"
print_data -b "###############################################################################"
if [ $TRELLIS_NEW_INSTALL = false ]; then
	print_data -b "Check for install or upgrade: Upgrade"
	print_data -b "Current Trellis Version:      "$TRELLIS_INSTALLED_VERSION
else
	print_data -b "Check for install or upgrade: Install"
fi
print_data -b "Server  Name:                 $THIS_HOST_SHORT"
print_data -b "Fullly Qualified Name:        $THIS_HOST"
print_data -b "IP Address:                   $THIS_IP"
print_data -b "OS Version:                   $CUR_OS"
print_data -b "Trellis Front Server:         $DETECTED_FRONT_NAME"
print_data -b "Trellis Front Server IP:      $DETECTED_FRONT_IP"
print_data -b "Trellis Back Server:          $DETECTED_BACK_NAME"
print_data -b "Trellis Back Server IP:       $DETECTED_BACK_IP"
print_data -b "Processor(s):                 $CUR_PROCESSOR"
print_data -b "Total Core(s):                $CUR_TOTAL_CORES"
print_data -b "Memory:                       $CUR_MEMORY"
print_data -b "Server Type:                  $CUR_VIRTUAL_SUMMARY"
print_data -b "Date Time:                    $CUR_DATE"
print_data -b "Time Zone:                    $CUR_TIMEZONE"
print_data -b "Time Server:                  $CUR_TIMESERVER"
print_data -b " "

#**************************************************************************************************************************************
# Perform tests
#**************************************************************************************************************************************

# set OS release dependent variables
if [ "$RELEASE" == "7.5" ] || [ "$RELEASE" == "7.6" ] || [ "$RELEASE" == "7.7" ]; then
  IPTABLES_RESULT="iptables: Firewall is not running."
  REQ_1_59_PACKAGES="binutils compat-db compat-libcap1 compat-libstdc++-33 compat-libstdc++-33.i686 device-mapper-multipath dos2unix elfutils-libelf elfutils-libelf-devel emacs fipscheck gcc gcc-c++ glibc glibc.i686 glibc-common glibc-devel glibc-devel.i686 hdparms initscripts iptraf kexec-tools ksh libXext libXi libXtst libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libsane-hpaio libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 make mtools nmap openmotif openssl openssl.i686 pax python-dmidecode redhat-lsb redhat-lsb-core.i686 screen sgpio strace sysstat unixODBC unixODBC-devel xinetd.x86_64 xorg-xll-server-utils xorg-x11-utils"
  ENTROPY="rngd -r /dev/urandom -o /dev/random"
  ENTROPY_EXTRAOPTIONS="/sbin/rngd -f -r /dev/urandom -o /dev/random"  
  TIMEZONE_LIST="Africa/Abidjan Africa/Accra Africa/Addis_Ababa Africa/Algiers Africa/Asmara Africa/Asmera Africa/Bamako Africa/Bangui Africa/Banjul Africa/Bissau Africa/Blantyre Africa/Brazzaville Africa/Bujumbura Africa/Cairo Africa/Casablanca Africa/Ceuta Africa/Conakry Africa/Dakar Africa/Dar_es_Salaam Africa/Djibouti Africa/Douala Africa/El_Aaiun Africa/Freetown Africa/Gaborone Africa/Harare Africa/Johannesburg Africa/Kampala Africa/Khartoum Africa/Kigali Africa/Kinshasa Africa/Lagos Africa/Libreville Africa/Lome Africa/Luanda Africa/Lubumbashi Africa/Lusaka Africa/Malabo Africa/Maputo Africa/Maseru Africa/Mbabane Africa/Mogadishu Africa/Monrovia Africa/Nairobi Africa/Ndjamena Africa/Niamey Africa/Nouakchott Africa/Ouagadougou Africa/Porto-Novo Africa/Sao_Tome Africa/Timbuktu Africa/Tripoli Africa/Tunis Africa/Windhoek America/Adak America/Anchorage America/Anguilla America/Antigua America/Araguaina America/Argentina/Buenos_Aires America/Argentina/Catamarca America/Argentina/ComodRivadavia America/Argentina/Cordoba America/Argentina/Jujuy America/Argentina/La_Rioja America/Argentina/Mendoza America/Argentina/Rio_Gallegos America/Argentina/Salta America/Argentina/San_Juan America/Argentina/San_Luis America/Argentina/Tucuman America/Argentina/Ushuaia America/Aruba America/Asuncion America/Atikokan America/Atka America/Bahia America/Barbados America/Belem America/Belize America/Blanc-Sablon America/Boa_Vista America/Bogota America/Boise America/Buenos_Aires America/Cambridge_Bay America/Campo_Grande America/Cancun America/Caracas America/Catamarca America/Cayenne America/Cayman America/Chicago America/Chihuahua America/Coral_Harbour America/Cordoba America/Costa_Rica America/Cuiaba America/Curacao America/Danmarkshavn America/Dawson America/Dawson_Creek America/Denver America/Detroit America/Dominica America/Edmonton America/Eirunepe America/El_Salvador America/Ensenada America/Fort_Wayne America/Fortaleza America/Glace_Bay America/Godthab America/Goose_Bay America/Grand_Turk America/Grenada America/Guadeloupe America/Guatemala America/Guayaquil America/Guyana America/Halifax America/Havana America/Hermosillo America/Indiana/Indianapolis America/Indiana/Knox America/Indiana/Marengo America/Indiana/Petersburg America/Indiana/Tell_City America/Indiana/Vevay America/Indiana/Vincennes America/Indiana/Winamac America/Indianapolis America/Inuvik America/Iqaluit America/Jamaica America/Jujuy America/Juneau America/Kentucky/Louisville America/Kentucky/Monticello America/Knox_IN America/La_Paz America/Lima America/Los_Angeles America/Louisville America/Maceio America/Managua America/Manaus America/Marigot America/Martinique America/Mazatlan America/Mendoza America/Menominee America/Merida America/Mexico_City America/Miquelon America/Moncton America/Monterrey America/Montevideo America/Montreal America/Montserrat America/Nassau America/New_York America/Nipigon America/Nome America/Noronha America/North_Dakota/Center America/North_Dakota/New_Salem America/Panama America/Pangnirtung America/Paramaribo America/Phoenix America/Port_of_Spain America/Port-au-Prince America/Porto_Acre America/Porto_Velho America/Puerto_Rico America/Rainy_River America/Rankin_Inlet America/Recife America/Regina America/Resolute America/Rio_Branco America/Rosario America/Santiago America/Santo_Domingo America/Sao_Paulo America/Scoresbysund America/Shiprock America/St_Barthelemy America/St_Johns America/St_Kitts America/St_Lucia America/St_Thomas America/St_Vincent America/Swift_Current America/Tegucigalpa America/Thule America/Thunder_Bay America/Tijuana America/Toronto America/Tortola America/Vancouver America/Virgin America/Whitehorse America/Winnipeg America/Yakutat America/Yellowknife Antarctica/Casey Antarctica/Davis Antarctica/DumontDUrville Antarctica/Mawson Antarctica/McMurdo Antarctica/Palmer Antarctica/South_Pole Antarctica/Syowa Arctic/Longyearbyen Asia/Aden Asia/Almaty Asia/Amman Asia/Anadyr Asia/Aqtau Asia/Aqtobe Asia/Ashgabat Asia/Ashkhabad Asia/Baghdad Asia/Bahrain Asia/Baku Asia/Bangkok Asia/Beirut Asia/Bishkek Asia/Brunei Asia/Calcutta Asia/Choibalsan Asia/Chongqing Asia/Chungking Asia/Colombo Asia/Dacca Asia/Damascus Asia/Dhaka Asia/Dili Asia/Dubai Asia/Dushanbe Asia/Gaza Asia/Harbin Asia/Ho_Chi_Minh Asia/Hong_Kong Asia/Hovd Asia/Irkutsk Asia/Istanbul Asia/Jakarta Asia/Jayapura Asia/Jerusalem Asia/Kabul Asia/Kamchatka Asia/Karachi Asia/Kashgar Asia/Kathmandu Asia/Katmandu Asia/Kolkata Asia/Krasnoyarsk Asia/Kuala_Lumpur Asia/Kuching Asia/Kuwait Asia/Macao Asia/Macau Asia/Magadan Asia/Makassar Asia/Manila Asia/Muscat Asia/Nicosia Asia/Novosibirsk Asia/Omsk Asia/Oral Asia/Phnom_Penh Asia/Pontianak Asia/Pyongyang Asia/Qatar Asia/Qyzylorda Asia/Rangoon Asia/Riyadh Asia/Saigon Asia/Sakhalin Asia/Samarkand Asia/Seoul Asia/Shanghai Asia/Singapore Asia/Taipei Asia/Tashkent Asia/Tbilisi Asia/Tehran Asia/Tel_Aviv Asia/Thimbu Asia/Thimphu Asia/Tokyo Asia/Ujung_Pandang Asia/Ulaanbaatar Asia/Ulan_Bator Asia/Urumqi Asia/Vientiane Asia/Vladivostok Asia/Yakutsk Asia/Yekaterinburg Asia/Yerevan Atlantic/Azores Atlantic/Bermuda Atlantic/Canary Atlantic/Cape_Verde Atlantic/Faeroe Atlantic/Faroe Atlantic/Jan_Mayen Atlantic/Madeira Atlantic/Reykjavik Atlantic/South_Georgia Atlantic/St_Helena Atlantic/Stanley Australia/ACT Australia/Adelaide Australia/Brisbane Australia/Broken_Hill Australia/Canberra Australia/Currie Australia/Darwin Australia/Eucla Australia/Hobart Australia/LHI Australia/Lindeman Australia/Lord_Howe Australia/Melbourne Australia/North Australia/NSW Australia/Perth Australia/Queensland Australia/South Australia/Sydney Australia/Tasmania Australia/Victoria Australia/West Australia/Yancowinna Brazil/Acre Brazil/DeNoronha Brazil/East Brazil/West Canada/Atlantic Canada/Central Canada/Eastern Canada/East-Saskatchewan Canada/Mountain Canada/Newfoundland Canada/Pacific Canada/Saskatchewan Canada/Yukon CET Chile/Continental Chile/EasterIsland CST CST6CDT Cuba EET Egypt Eire EST EST5EDT Etc/GMT Etc/GMT+0 Etc/GMT+1 Etc/GMT+10 Etc/GMT+11 Etc/GMT+12 Etc/GMT+2 Etc/GMT+3 Etc/GMT+4 Etc/GMT+5 Etc/GMT+6 Etc/GMT+7 Etc/GMT+8 Etc/GMT+9 Etc/GMT0 Etc/GMT-0 Etc/GMT-1 Etc/GMT-10 Etc/GMT-11 Etc/GMT-12 Etc/GMT-13 Etc/GMT-14 Etc/GMT-2 Etc/GMT-3 Etc/GMT-4 Etc/GMT-5 Etc/GMT-6 Etc/GMT-7 Etc/GMT-8 Etc/GMT-9 Etc/Greenwich Europe/Amsterdam Europe/Andorra Europe/Athens Europe/Belfast Europe/Belgrade Europe/Berlin Europe/Bratislava Europe/Brussels Europe/Bucharest Europe/Budapest Europe/Chisinau Europe/Copenhagen Europe/Dublin Europe/Gibraltar Europe/Guernsey Europe/Helsinki Europe/Isle_of_Man Europe/Istanbul Europe/Jersey Europe/Kaliningrad Europe/Kiev Europe/Lisbon Europe/Ljubljana Europe/London Europe/Luxembourg Europe/Madrid Europe/Malta Europe/Mariehamn Europe/Minsk Europe/Monaco Europe/Moscow Europe/Nicosia Europe/Oslo Europe/Paris Europe/Prague Europe/Riga Europe/Rome Europe/Samara Europe/San_Marino Europe/Sarajevo Europe/Simferopol Europe/Skopje Europe/Sofia Europe/Stockholm Europe/Tallinn Europe/Tirane Europe/Tiraspol Europe/Uzhgorod Europe/Vaduz Europe/Vatican Europe/Vienna Europe/Vilnius Europe/Volgograd Europe/Warsaw Europe/Zagreb Europe/Zaporozhye Europe/Zurich GB GB-Eire GMT GMT+0 GMT0 GMT-0 Greenwich Hongkong HST Iceland Indian/Antananarivo Indian/Chagos Indian/Christmas Indian/Cocos Indian/Comoro Indian/Kerguelen Indian/Mahe Indian/Maldives Indian/Mauritius Indian/Mayotte Indian/Reunion Iran Israel Jamaica Japan Kwajalein Libya MET Mexico/BajaNorte Mexico/BajaSur Mexico/General MST MST7MDT Navajo NZ NZ-CHAT Pacific/Apia Pacific/Auckland Pacific/Chatham Pacific/Easter Pacific/Efate Pacific/Enderbury Pacific/Fakaofo Pacific/Fiji Pacific/Funafuti Pacific/Galapagos Pacific/Gambier Pacific/Guadalcanal Pacific/Guam Pacific/Honolulu Pacific/Johnston Pacific/Kiritimati Pacific/Kosrae Pacific/Kwajalein Pacific/Majuro Pacific/Marquesas Pacific/Midway Pacific/Nauru Pacific/Niue Pacific/Norfolk Pacific/Noumea Pacific/Pago_Pago Pacific/Palau Pacific/Pitcairn Pacific/Ponape Pacific/Port_Moresby Pacific/Rarotonga Pacific/Saipan Pacific/Samoa Pacific/Tahiti Pacific/Tarawa Pacific/Tongatapu Pacific/Truk Pacific/Wake Pacific/Wallis Pacific/Yap Poland Portugal PRC PST PST8PDT ROC ROK Singapore Turkey US/Alaska US/Aleutian US/Arizona US/Central US/Eastern US/East-Indiana US/Hawaii US/Indiana-Starke US/Michigan US/Mountain US/Pacific US/Pacific-New US/Samoa UTC WET W-SU"
  TIMEZONE_CMD="timedatectl | grep 'Time zone' | awk '{print $3}'"
elif [ "$RELEASE" == "6.5" ] || [ "$RELEASE" == "6.6" ] || [ "$RELEASE" == "6.7" ] || [ "$RELEASE" == "6.8" ] || [ "$RELEASE" == "6.9" ] || [ "$RELEASE" == "6.10" ]; then
  IPTABLES_RESULT="iptables: Firewall is not running."
  REQ_1_59_PACKAGES="zlib zlib.i686 binutils compat-db compat-libcap1 compat-libstdc++-33 compat-libstdc++-33.i686 device-mapper-multipath dos2unix elfutils-libelf elfutils-libelf-devel emacs fipscheck gcc gcc-c++ glibc glibc.i686 glibc-devel glibc-devel.i686 kexec-tools ksh libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libsane-hpaio libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 libXext libXi libXtst make openmotif openssl openssl.i686 redhat-lsb redhat-lsb-core.i686 screen sgpio sysstat unixODBC unixODBC-devel xinetd.x86_64 java-1.6.0-openjdk java-1.7.0-openjdk"
  ENTROPY="rngd -r /dev/urandom -o /dev/random -t 0.01"
  ENTROPY_EXTRAOPTIONS=" -r /dev/urandom -o /dev/random -b"  
  TIMEZONE_LIST="Africa/Abidjan Africa/Accra Africa/Addis_Ababa Africa/Algiers Africa/Asmara Africa/Asmera Africa/Bamako Africa/Bangui Africa/Banjul Africa/Bissau Africa/Blantyre Africa/Brazzaville Africa/Bujumbura Africa/Cairo Africa/Casablanca Africa/Ceuta Africa/Conakry Africa/Dakar Africa/Dar_es_Salaam Africa/Djibouti Africa/Douala Africa/El_Aaiun Africa/Freetown Africa/Gaborone Africa/Harare Africa/Johannesburg Africa/Kampala Africa/Khartoum Africa/Kigali Africa/Kinshasa Africa/Lagos Africa/Libreville Africa/Lome Africa/Luanda Africa/Lubumbashi Africa/Lusaka Africa/Malabo Africa/Maputo Africa/Maseru Africa/Mbabane Africa/Mogadishu Africa/Monrovia Africa/Nairobi Africa/Ndjamena Africa/Niamey Africa/Nouakchott Africa/Ouagadougou Africa/Porto-Novo Africa/Sao_Tome Africa/Timbuktu Africa/Tripoli Africa/Tunis Africa/Windhoek America/Adak America/Anchorage America/Anguilla America/Antigua America/Araguaina America/Argentina/Buenos_Aires America/Argentina/Catamarca America/Argentina/ComodRivadavia America/Argentina/Cordoba America/Argentina/Jujuy America/Argentina/La_Rioja America/Argentina/Mendoza America/Argentina/Rio_Gallegos America/Argentina/Salta America/Argentina/San_Juan America/Argentina/San_Luis America/Argentina/Tucuman America/Argentina/Ushuaia America/Aruba America/Asuncion America/Atikokan America/Atka America/Bahia America/Barbados America/Belem America/Belize America/Blanc-Sablon America/Boa_Vista America/Bogota America/Boise America/Buenos_Aires America/Cambridge_Bay America/Campo_Grande America/Cancun America/Caracas America/Catamarca America/Cayenne America/Cayman America/Chicago America/Chihuahua America/Coral_Harbour America/Cordoba America/Costa_Rica America/Cuiaba America/Curacao America/Danmarkshavn America/Dawson America/Dawson_Creek America/Denver America/Detroit America/Dominica America/Edmonton America/Eirunepe America/El_Salvador America/Ensenada America/Fort_Wayne America/Fortaleza America/Glace_Bay America/Godthab America/Goose_Bay America/Grand_Turk America/Grenada America/Guadeloupe America/Guatemala America/Guayaquil America/Guyana America/Halifax America/Havana America/Hermosillo America/Indiana/Indianapolis America/Indiana/Knox America/Indiana/Marengo America/Indiana/Petersburg America/Indiana/Tell_City America/Indiana/Vevay America/Indiana/Vincennes America/Indiana/Winamac America/Indianapolis America/Inuvik America/Iqaluit America/Jamaica America/Jujuy America/Juneau America/Kentucky/Louisville America/Kentucky/Monticello America/Knox_IN America/La_Paz America/Lima America/Los_Angeles America/Louisville America/Maceio America/Managua America/Manaus America/Marigot America/Martinique America/Mazatlan America/Mendoza America/Menominee America/Merida America/Mexico_City America/Miquelon America/Moncton America/Monterrey America/Montevideo America/Montreal America/Montserrat America/Nassau America/New_York America/Nipigon America/Nome America/Noronha America/North_Dakota/Center America/North_Dakota/New_Salem America/Panama America/Pangnirtung America/Paramaribo America/Phoenix America/Port_of_Spain America/Port-au-Prince America/Porto_Acre America/Porto_Velho America/Puerto_Rico America/Rainy_River America/Rankin_Inlet America/Recife America/Regina America/Resolute America/Rio_Branco America/Rosario America/Santiago America/Santo_Domingo America/Sao_Paulo America/Scoresbysund America/Shiprock America/St_Barthelemy America/St_Johns America/St_Kitts America/St_Lucia America/St_Thomas America/St_Vincent America/Swift_Current America/Tegucigalpa America/Thule America/Thunder_Bay America/Tijuana America/Toronto America/Tortola America/Vancouver America/Virgin America/Whitehorse America/Winnipeg America/Yakutat America/Yellowknife Antarctica/Casey Antarctica/Davis Antarctica/DumontDUrville Antarctica/Mawson Antarctica/McMurdo Antarctica/Palmer Antarctica/South_Pole Antarctica/Syowa Arctic/Longyearbyen Asia/Aden Asia/Almaty Asia/Amman Asia/Anadyr Asia/Aqtau Asia/Aqtobe Asia/Ashgabat Asia/Ashkhabad Asia/Baghdad Asia/Bahrain Asia/Baku Asia/Bangkok Asia/Beirut Asia/Bishkek Asia/Brunei Asia/Calcutta Asia/Choibalsan Asia/Chongqing Asia/Chungking Asia/Colombo Asia/Dacca Asia/Damascus Asia/Dhaka Asia/Dili Asia/Dubai Asia/Dushanbe Asia/Gaza Asia/Harbin Asia/Ho_Chi_Minh Asia/Hong_Kong Asia/Hovd Asia/Irkutsk Asia/Istanbul Asia/Jakarta Asia/Jayapura Asia/Jerusalem Asia/Kabul Asia/Kamchatka Asia/Karachi Asia/Kashgar Asia/Kathmandu Asia/Katmandu Asia/Kolkata Asia/Krasnoyarsk Asia/Kuala_Lumpur Asia/Kuching Asia/Kuwait Asia/Macao Asia/Macau Asia/Magadan Asia/Makassar Asia/Manila Asia/Muscat Asia/Nicosia Asia/Novosibirsk Asia/Omsk Asia/Oral Asia/Phnom_Penh Asia/Pontianak Asia/Pyongyang Asia/Qatar Asia/Qyzylorda Asia/Rangoon Asia/Riyadh Asia/Saigon Asia/Sakhalin Asia/Samarkand Asia/Seoul Asia/Shanghai Asia/Singapore Asia/Taipei Asia/Tashkent Asia/Tbilisi Asia/Tehran Asia/Tel_Aviv Asia/Thimbu Asia/Thimphu Asia/Tokyo Asia/Ujung_Pandang Asia/Ulaanbaatar Asia/Ulan_Bator Asia/Urumqi Asia/Vientiane Asia/Vladivostok Asia/Yakutsk Asia/Yekaterinburg Asia/Yerevan Atlantic/Azores Atlantic/Bermuda Atlantic/Canary Atlantic/Cape_Verde Atlantic/Faeroe Atlantic/Faroe Atlantic/Jan_Mayen Atlantic/Madeira Atlantic/Reykjavik Atlantic/South_Georgia Atlantic/St_Helena Atlantic/Stanley Australia/ACT Australia/Adelaide Australia/Brisbane Australia/Broken_Hill Australia/Canberra Australia/Currie Australia/Darwin Australia/Eucla Australia/Hobart Australia/LHI Australia/Lindeman Australia/Lord_Howe Australia/Melbourne Australia/North Australia/NSW Australia/Perth Australia/Queensland Australia/South Australia/Sydney Australia/Tasmania Australia/Victoria Australia/West Australia/Yancowinna Brazil/Acre Brazil/DeNoronha Brazil/East Brazil/West Canada/Atlantic Canada/Central Canada/Eastern Canada/East-Saskatchewan Canada/Mountain Canada/Newfoundland Canada/Pacific Canada/Saskatchewan Canada/Yukon CET Chile/Continental Chile/EasterIsland CST CST6CDT Cuba EET Egypt Eire EST EST5EDT Etc/GMT Etc/GMT+0 Etc/GMT+1 Etc/GMT+10 Etc/GMT+11 Etc/GMT+12 Etc/GMT+2 Etc/GMT+3 Etc/GMT+4 Etc/GMT+5 Etc/GMT+6 Etc/GMT+7 Etc/GMT+8 Etc/GMT+9 Etc/GMT0 Etc/GMT-0 Etc/GMT-1 Etc/GMT-10 Etc/GMT-11 Etc/GMT-12 Etc/GMT-13 Etc/GMT-14 Etc/GMT-2 Etc/GMT-3 Etc/GMT-4 Etc/GMT-5 Etc/GMT-6 Etc/GMT-7 Etc/GMT-8 Etc/GMT-9 Etc/Greenwich Europe/Amsterdam Europe/Andorra Europe/Athens Europe/Belfast Europe/Belgrade Europe/Berlin Europe/Bratislava Europe/Brussels Europe/Bucharest Europe/Budapest Europe/Chisinau Europe/Copenhagen Europe/Dublin Europe/Gibraltar Europe/Guernsey Europe/Helsinki Europe/Isle_of_Man Europe/Istanbul Europe/Jersey Europe/Kaliningrad Europe/Kiev Europe/Lisbon Europe/Ljubljana Europe/London Europe/Luxembourg Europe/Madrid Europe/Malta Europe/Mariehamn Europe/Minsk Europe/Monaco Europe/Moscow Europe/Nicosia Europe/Oslo Europe/Paris Europe/Prague Europe/Riga Europe/Rome Europe/Samara Europe/San_Marino Europe/Sarajevo Europe/Simferopol Europe/Skopje Europe/Sofia Europe/Stockholm Europe/Tallinn Europe/Tirane Europe/Tiraspol Europe/Uzhgorod Europe/Vaduz Europe/Vatican Europe/Vienna Europe/Vilnius Europe/Volgograd Europe/Warsaw Europe/Zagreb Europe/Zaporozhye Europe/Zurich GB GB-Eire GMT GMT+0 GMT0 GMT-0 Greenwich Hongkong HST Iceland Indian/Antananarivo Indian/Chagos Indian/Christmas Indian/Cocos Indian/Comoro Indian/Kerguelen Indian/Mahe Indian/Maldives Indian/Mauritius Indian/Mayotte Indian/Reunion Iran Israel Jamaica Japan Kwajalein Libya MET Mexico/BajaNorte Mexico/BajaSur Mexico/General MST MST7MDT Navajo NZ NZ-CHAT Pacific/Apia Pacific/Auckland Pacific/Chatham Pacific/Easter Pacific/Efate Pacific/Enderbury Pacific/Fakaofo Pacific/Fiji Pacific/Funafuti Pacific/Galapagos Pacific/Gambier Pacific/Guadalcanal Pacific/Guam Pacific/Honolulu Pacific/Johnston Pacific/Kiritimati Pacific/Kosrae Pacific/Kwajalein Pacific/Majuro Pacific/Marquesas Pacific/Midway Pacific/Nauru Pacific/Niue Pacific/Norfolk Pacific/Noumea Pacific/Pago_Pago Pacific/Palau Pacific/Pitcairn Pacific/Ponape Pacific/Port_Moresby Pacific/Rarotonga Pacific/Saipan Pacific/Samoa Pacific/Tahiti Pacific/Tarawa Pacific/Tongatapu Pacific/Truk Pacific/Wake Pacific/Wallis Pacific/Yap Poland Portugal PRC PST PST8PDT ROC ROK Singapore Turkey US/Alaska US/Aleutian US/Arizona US/Central US/Eastern US/East-Indiana US/Hawaii US/Indiana-Starke US/Michigan US/Mountain US/Pacific US/Pacific-New US/Samoa UTC WET W-SU"
  TIMEZONE_CMD="cat /etc/sysconfig/clock | grep ZONE | cut -f2 -d '=' | sed 's/[\"]//g'"
else
  echo '[Warning]: Version $RELEASE is not a supported release.  Tests will be performed as if RHEL 7.6.'
  RELEASE="7.6"
  IPTABLES_RESULT="iptables: Firewall is not running."
  REQ_1_59_PACKAGES="binutils compat-db compat-libcap1 compat-libstdc++-33 compat-libstdc++-33.i686 device-mapper-multipath dos2unix elfutils-libelf elfutils-libelf-devel emacs fipscheck gcc gcc-c++ glibc glibc.i686 glibc-common glibc-devel glibc-devel.i686 hdparms initscripts iptraf kexec-tools ksh libXext libXi libXtst libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libsane-hpaio libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 make mtools nmap openmotif openssl openssl.i686 pax python-dmidecode redhat-lsb redhat-lsb-core.i686 screen sgpio strace sysstat unixODBC unixODBC-devel xinetd.x86_64 xorg-xll-server-utils xorg-x11-utils"
  ENTROPY="rngd -r /dev/urandom -o /dev/random"
  ENTROPY_EXTRAOPTIONS="/sbin/rngd -f -r /dev/urandom -o /dev/random"  
  TIMEZONE_LIST="Africa/Abidjan Africa/Accra Africa/Addis_Ababa Africa/Algiers Africa/Asmara Africa/Asmera Africa/Bamako Africa/Bangui Africa/Banjul Africa/Bissau Africa/Blantyre Africa/Brazzaville Africa/Bujumbura Africa/Cairo Africa/Casablanca Africa/Ceuta Africa/Conakry Africa/Dakar Africa/Dar_es_Salaam Africa/Djibouti Africa/Douala Africa/El_Aaiun Africa/Freetown Africa/Gaborone Africa/Harare Africa/Johannesburg Africa/Kampala Africa/Khartoum Africa/Kigali Africa/Kinshasa Africa/Lagos Africa/Libreville Africa/Lome Africa/Luanda Africa/Lubumbashi Africa/Lusaka Africa/Malabo Africa/Maputo Africa/Maseru Africa/Mbabane Africa/Mogadishu Africa/Monrovia Africa/Nairobi Africa/Ndjamena Africa/Niamey Africa/Nouakchott Africa/Ouagadougou Africa/Porto-Novo Africa/Sao_Tome Africa/Timbuktu Africa/Tripoli Africa/Tunis Africa/Windhoek America/Adak America/Anchorage America/Anguilla America/Antigua America/Araguaina America/Argentina/Buenos_Aires America/Argentina/Catamarca America/Argentina/ComodRivadavia America/Argentina/Cordoba America/Argentina/Jujuy America/Argentina/La_Rioja America/Argentina/Mendoza America/Argentina/Rio_Gallegos America/Argentina/Salta America/Argentina/San_Juan America/Argentina/San_Luis America/Argentina/Tucuman America/Argentina/Ushuaia America/Aruba America/Asuncion America/Atikokan America/Atka America/Bahia America/Barbados America/Belem America/Belize America/Blanc-Sablon America/Boa_Vista America/Bogota America/Boise America/Buenos_Aires America/Cambridge_Bay America/Campo_Grande America/Cancun America/Caracas America/Catamarca America/Cayenne America/Cayman America/Chicago America/Chihuahua America/Coral_Harbour America/Cordoba America/Costa_Rica America/Cuiaba America/Curacao America/Danmarkshavn America/Dawson America/Dawson_Creek America/Denver America/Detroit America/Dominica America/Edmonton America/Eirunepe America/El_Salvador America/Ensenada America/Fort_Wayne America/Fortaleza America/Glace_Bay America/Godthab America/Goose_Bay America/Grand_Turk America/Grenada America/Guadeloupe America/Guatemala America/Guayaquil America/Guyana America/Halifax America/Havana America/Hermosillo America/Indiana/Indianapolis America/Indiana/Knox America/Indiana/Marengo America/Indiana/Petersburg America/Indiana/Tell_City America/Indiana/Vevay America/Indiana/Vincennes America/Indiana/Winamac America/Indianapolis America/Inuvik America/Iqaluit America/Jamaica America/Jujuy America/Juneau America/Kentucky/Louisville America/Kentucky/Monticello America/Knox_IN America/La_Paz America/Lima America/Los_Angeles America/Louisville America/Maceio America/Managua America/Manaus America/Marigot America/Martinique America/Mazatlan America/Mendoza America/Menominee America/Merida America/Mexico_City America/Miquelon America/Moncton America/Monterrey America/Montevideo America/Montreal America/Montserrat America/Nassau America/New_York America/Nipigon America/Nome America/Noronha America/North_Dakota/Center America/North_Dakota/New_Salem America/Panama America/Pangnirtung America/Paramaribo America/Phoenix America/Port_of_Spain America/Port-au-Prince America/Porto_Acre America/Porto_Velho America/Puerto_Rico America/Rainy_River America/Rankin_Inlet America/Recife America/Regina America/Resolute America/Rio_Branco America/Rosario America/Santiago America/Santo_Domingo America/Sao_Paulo America/Scoresbysund America/Shiprock America/St_Barthelemy America/St_Johns America/St_Kitts America/St_Lucia America/St_Thomas America/St_Vincent America/Swift_Current America/Tegucigalpa America/Thule America/Thunder_Bay America/Tijuana America/Toronto America/Tortola America/Vancouver America/Virgin America/Whitehorse America/Winnipeg America/Yakutat America/Yellowknife Antarctica/Casey Antarctica/Davis Antarctica/DumontDUrville Antarctica/Mawson Antarctica/McMurdo Antarctica/Palmer Antarctica/South_Pole Antarctica/Syowa Arctic/Longyearbyen Asia/Aden Asia/Almaty Asia/Amman Asia/Anadyr Asia/Aqtau Asia/Aqtobe Asia/Ashgabat Asia/Ashkhabad Asia/Baghdad Asia/Bahrain Asia/Baku Asia/Bangkok Asia/Beirut Asia/Bishkek Asia/Brunei Asia/Calcutta Asia/Choibalsan Asia/Chongqing Asia/Chungking Asia/Colombo Asia/Dacca Asia/Damascus Asia/Dhaka Asia/Dili Asia/Dubai Asia/Dushanbe Asia/Gaza Asia/Harbin Asia/Ho_Chi_Minh Asia/Hong_Kong Asia/Hovd Asia/Irkutsk Asia/Istanbul Asia/Jakarta Asia/Jayapura Asia/Jerusalem Asia/Kabul Asia/Kamchatka Asia/Karachi Asia/Kashgar Asia/Kathmandu Asia/Katmandu Asia/Kolkata Asia/Krasnoyarsk Asia/Kuala_Lumpur Asia/Kuching Asia/Kuwait Asia/Macao Asia/Macau Asia/Magadan Asia/Makassar Asia/Manila Asia/Muscat Asia/Nicosia Asia/Novosibirsk Asia/Omsk Asia/Oral Asia/Phnom_Penh Asia/Pontianak Asia/Pyongyang Asia/Qatar Asia/Qyzylorda Asia/Rangoon Asia/Riyadh Asia/Saigon Asia/Sakhalin Asia/Samarkand Asia/Seoul Asia/Shanghai Asia/Singapore Asia/Taipei Asia/Tashkent Asia/Tbilisi Asia/Tehran Asia/Tel_Aviv Asia/Thimbu Asia/Thimphu Asia/Tokyo Asia/Ujung_Pandang Asia/Ulaanbaatar Asia/Ulan_Bator Asia/Urumqi Asia/Vientiane Asia/Vladivostok Asia/Yakutsk Asia/Yekaterinburg Asia/Yerevan Atlantic/Azores Atlantic/Bermuda Atlantic/Canary Atlantic/Cape_Verde Atlantic/Faeroe Atlantic/Faroe Atlantic/Jan_Mayen Atlantic/Madeira Atlantic/Reykjavik Atlantic/South_Georgia Atlantic/St_Helena Atlantic/Stanley Australia/ACT Australia/Adelaide Australia/Brisbane Australia/Broken_Hill Australia/Canberra Australia/Currie Australia/Darwin Australia/Eucla Australia/Hobart Australia/LHI Australia/Lindeman Australia/Lord_Howe Australia/Melbourne Australia/North Australia/NSW Australia/Perth Australia/Queensland Australia/South Australia/Sydney Australia/Tasmania Australia/Victoria Australia/West Australia/Yancowinna Brazil/Acre Brazil/DeNoronha Brazil/East Brazil/West Canada/Atlantic Canada/Central Canada/Eastern Canada/East-Saskatchewan Canada/Mountain Canada/Newfoundland Canada/Pacific Canada/Saskatchewan Canada/Yukon CET Chile/Continental Chile/EasterIsland CST CST6CDT Cuba EET Egypt Eire EST EST5EDT Etc/GMT Etc/GMT+0 Etc/GMT+1 Etc/GMT+10 Etc/GMT+11 Etc/GMT+12 Etc/GMT+2 Etc/GMT+3 Etc/GMT+4 Etc/GMT+5 Etc/GMT+6 Etc/GMT+7 Etc/GMT+8 Etc/GMT+9 Etc/GMT0 Etc/GMT-0 Etc/GMT-1 Etc/GMT-10 Etc/GMT-11 Etc/GMT-12 Etc/GMT-13 Etc/GMT-14 Etc/GMT-2 Etc/GMT-3 Etc/GMT-4 Etc/GMT-5 Etc/GMT-6 Etc/GMT-7 Etc/GMT-8 Etc/GMT-9 Etc/Greenwich Europe/Amsterdam Europe/Andorra Europe/Athens Europe/Belfast Europe/Belgrade Europe/Berlin Europe/Bratislava Europe/Brussels Europe/Bucharest Europe/Budapest Europe/Chisinau Europe/Copenhagen Europe/Dublin Europe/Gibraltar Europe/Guernsey Europe/Helsinki Europe/Isle_of_Man Europe/Istanbul Europe/Jersey Europe/Kaliningrad Europe/Kiev Europe/Lisbon Europe/Ljubljana Europe/London Europe/Luxembourg Europe/Madrid Europe/Malta Europe/Mariehamn Europe/Minsk Europe/Monaco Europe/Moscow Europe/Nicosia Europe/Oslo Europe/Paris Europe/Prague Europe/Riga Europe/Rome Europe/Samara Europe/San_Marino Europe/Sarajevo Europe/Simferopol Europe/Skopje Europe/Sofia Europe/Stockholm Europe/Tallinn Europe/Tirane Europe/Tiraspol Europe/Uzhgorod Europe/Vaduz Europe/Vatican Europe/Vienna Europe/Vilnius Europe/Volgograd Europe/Warsaw Europe/Zagreb Europe/Zaporozhye Europe/Zurich GB GB-Eire GMT GMT+0 GMT0 GMT-0 Greenwich Hongkong HST Iceland Indian/Antananarivo Indian/Chagos Indian/Christmas Indian/Cocos Indian/Comoro Indian/Kerguelen Indian/Mahe Indian/Maldives Indian/Mauritius Indian/Mayotte Indian/Reunion Iran Israel Jamaica Japan Kwajalein Libya MET Mexico/BajaNorte Mexico/BajaSur Mexico/General MST MST7MDT Navajo NZ NZ-CHAT Pacific/Apia Pacific/Auckland Pacific/Chatham Pacific/Easter Pacific/Efate Pacific/Enderbury Pacific/Fakaofo Pacific/Fiji Pacific/Funafuti Pacific/Galapagos Pacific/Gambier Pacific/Guadalcanal Pacific/Guam Pacific/Honolulu Pacific/Johnston Pacific/Kiritimati Pacific/Kosrae Pacific/Kwajalein Pacific/Majuro Pacific/Marquesas Pacific/Midway Pacific/Nauru Pacific/Niue Pacific/Norfolk Pacific/Noumea Pacific/Pago_Pago Pacific/Palau Pacific/Pitcairn Pacific/Ponape Pacific/Port_Moresby Pacific/Rarotonga Pacific/Saipan Pacific/Samoa Pacific/Tahiti Pacific/Tarawa Pacific/Tongatapu Pacific/Truk Pacific/Wake Pacific/Wallis Pacific/Yap Poland Portugal PRC PST PST8PDT ROC ROK Singapore Turkey US/Alaska US/Aleutian US/Arizona US/Central US/Eastern US/East-Indiana US/Hawaii US/Indiana-Starke US/Michigan US/Mountain US/Pacific US/Pacific-New US/Samoa UTC WET W-SU"
  TIMEZONE_CMD="timedatectl | grep 'Time zone' | awk '{print $3}'"
fi

print_testtype "1.x OS Checks"

1-51-checkOracleUser
1-52-checkGroupInfo
1-53-checkEnvironmentVariables
1-54-checkOraInst
1-55-checkOraTab
1-59-checkPackages
1-60-checkAntPackage
1-61-checkSysCtl
1-63-checkPamFile
1-64-checkUmask
1-65-checkLicenseSymlinks
1-66-checkRetainedPermissions
1-67-checkCreatedPermissions
1-68-checkJavaVersion
1-69-checkHomeOracleOwnership
1-70-checkSwapFileSpace

print_testtype "2.x Hardware Checks"

2-4-checkHDDCapacity
2-7-checkCPUFrequency
2-9-checkCPUCoreCount

print_testtype "3.x Virtualization Checks"

3-1-checkVirtualizationDrivers
3-5-checkRNGDOptions

print_testtype "4.x Security Checks"

4-2-checkFirewall
4-3-checkEntropyService
4-4-checkSELinux
4-5-checkIp6tables
4-6-checkFirewalld

print_testtype "5.x Network Checks"

5-1-checkNICs
5-2-checkDHCP
5-8-checkTime

if [ "$DEBUG_MODE" = true ]; then 
	print_testtype "Debug Info"
	print_debuginfo
fi

#  All done
print_data
print_data -t "\n**********************************************************************\n"
print_data -t "Verification tests completed.\n"
print_data -e "Please review ${ENV_ORIGIN_FOLDER}/${CFG_LOGFILE} for more details...\n"
print_data '********************************************************************************************' 
print_data '******************************End of Report*************************************************'


exit




