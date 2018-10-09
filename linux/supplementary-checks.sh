#!/bin/bash

#---------------------------------------------------------------------------------------------
#
#      Copyright (c) 2013-2018, Avocent, Vertiv Infrastructure Ltd.
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
# Script Name: Trellis-Prereq
# Created: 2013/05/01
# Modified: 2018/09/17
# Author: Richard Golstein [NETPWR/AVOCENT/UK], Scott Donaldson [NETPWR/AVOCENT/UK]. Ray Daugherty (NETPWR/AVOCENT/US)
# Company: Vertiv Infrastructure Ltd.
# Group: Software Delovery, Services
# Email: scott.donaldson@vertivco.com. ray.daugherty@vertivco.com
#---------------------------------------------------------------------------------------------

#
#  Global Variables
#
ENV_CURRENT_USER=`whoami`
ENV_REAL_USER=`who am i | awk '{print $1}'`
ENV_HOSTNAME=`hostname`
ENV_ORIGIN_FOLDER=`pwd`

DD_PARAM_FLUSHED="bs=8k count=100k conv=fdatasync"
DD_PARAM_CACHED="bs=8k count=100k"
DD_OUTFILE="/tmp/output.img"
# (30 Sep 2018 - (RayD) Bump to next minor version (3.3.0)
SCRIPT_VERSION="3.3.0"

CFG_OUTPUT_FOLDER="~${ENV_REAL_USER}"
CFG_OUTPUT_TMP_FOLDER="/tmp"
CFG_LOGFILE="trellis-precheck_${ENV_HOSTNAME}_`date +"%Y%m%d-%H%M"`.log"
CFG_LOGFILE_PATH="${CFG_OUTPUT_TMP_FOLDER}/${CFG_LOGFILE}"
CFG_OUTPUT_BUNDLE_FOLDER="${CFG_OUTPUT_TMP_FOLDER}/trellis_config"

true=true
false=false

#
# The following are used for terminal output
#
NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
YELLOW='\033[01;33m'
PURPLE='\033[01;35m'
CYAN='\033[01;36m'
WHITE='\033[01;37m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
#####

#
#  Save Location
#
pushd /tmp
#####

#
#  Check Running User
#
if [ "$ENV_CURRENT_USER" != "root" ]; then
    echo '[Info]: Script not launch by root user.'> `tty`
    if [ `id -u` -eq 0 ]; then
			echo '[Info]: Script elevated with sudo.'> `tty`
	else
		echo '[Error]: Script neither elevated with sudo or run by root, cannot continue.'> `tty`
		exit 1
	fi
fi
#####

#
#  Prepare Log File for Output
#
touch ${CFG_LOGFILE_PATH}
chmod 775 ${CFG_LOGFILE_PATH}
chown $ENV_REAL_USER:`id -gn ${ENV_REAL_USER}` ${CFG_LOGFILE_PATH}
######

#
#  Making a directory where all the standard config files are generated
#
if [ -d $CFG_OUTPUT_BUNDLE_FOLDER ]; then
  rm -rf $CFG_OUTPUT_BUNDLE_FOLDER/*
else
  mkdir $CFG_OUTPUT_BUNDLE_FOLDER
fi
chmod 775 $CFG_OUTPUT_BUNDLE_FOLDER
chown $ENV_REAL_USER:`id -gn ${ENV_REAL_USER}` $CFG_OUTPUT_BUNDLE_FOLDER
######

#
#  Detect whether this is a fresh install or a patch
#
if [ -e /etc/init.d/trellis ]; then 
    TRELLIS_NEW_INSTALL="false"
	TRELLIS_INSTALLED_VERSION=`cat /u01/trellis/trellis.version | grep trellis.version | cut -f2 -d"="`	
else
    TRELLIS_NEW_INSTALL="true"
fi
#####

if [ "$TRELLIS_NEW_INSTALL" == "false" ]; then
    echo "Previous installation detected"
	echo "Current Trellis Version: "$TRELLIS_INSTALLED_VERSION
    echo -n "Is the precheck for a patch installation (y/n)? "

    while read DETECTED_CHECK_TYPE_CONFIRM; do
         if [[ -z "${DETECTED_CHECK_TYPE_CONFIRM}" ]]; then
              echo -n "Is the precheck for a patch installation (y/n)? "
         else
             if [ $DETECTED_CHECK_TYPE_CONFIRM = "yes" -o $DETECTED_CHECK_TYPE_CONFIRM = "Y" -o $DETECTED_CHECK_TYPE_CONFIRM = "YES" -o $DETECTED_CHECK_TYPE_CONFIRM = "y" -o $DETECTED_CHECK_TYPE_CONFIRM = "no" -o $DETECTED_CHECK_TYPE_CONFIRM = "N" -o $DETECTED_CHECK_TYPE_CONFIRM = "NO" -o $DETECTED_CHECK_TYPE_CONFIRM = "n" ]; then
		         break
		     else
			     echo -n "Is the precheck for a patch installation (y/n)? "
			 fi
         fi
    done

	echo
    if [ $DETECTED_CHECK_TYPE_CONFIRM = "yes" -o $DETECTED_CHECK_TYPE_CONFIRM = "Y" -o $DETECTED_CHECK_TYPE_CONFIRM = "YES" -o $DETECTED_CHECK_TYPE_CONFIRM = "y" ]; then
      TRELLIS_NEW_INSTALL="No"
	  echo "Performing pre-check for patch installation..."
    else
      TRELLIS_NEW_INSTALL="Yes"
	  echo "Performing pre-check for new installation..."	  
# (30 Sep 2018 - (RayD) Update comment when indicating this a new install when traces of Trellis are found
	  echo "WARNING: Powertools should be run if this is new install on a server where Trellis already exists"
    fi	
else
    echo "Performing pre-check for new installation..."	
fi
######

#
#  Find out if the server being installed is the front or back
#
echo ""
echo -n "Is this the front or back server? (f/b): "

while read TRELLIS_HOST_PROMPT; do
     if [[ -z "${TRELLIS_HOST_PROMPT}" ]]; then
        echo -n "Is this the front or back server? (f/b): "
     else
        if [ $TRELLIS_HOST_PROMPT = "b" -o $TRELLIS_HOST_PROMPT = "back" -o $TRELLIS_HOST_PROMPT = "B" -o $TRELLIS_HOST_PROMPT = "Back" -o $TRELLIS_HOST_PROMPT = "BACK" ]; then
          TRELLIS_HOST_PROMPT=b
          break
        elif [ $TRELLIS_HOST_PROMPT = "f" -o $TRELLIS_HOST_PROMPT = "front" -o $TRELLIS_HOST_PROMPT = "F" -o $TRELLIS_HOST_PROMPT = "Front" -o $TRELLIS_HOST_PROMPT = "FRONT" ]; then
          TRELLIS_HOST_PROMPT=f
          break		  
        else
            echo -n "Is this the front or back server? (f/b): "
        fi
     fi
done

IP_COUNT=`ifconfig | grep "inet addr:" | grep -v "127.0.0.1" | wc -l`

#
#  Get the IP and hostname of the server not being installed
#
if [ $TRELLIS_HOST_PROMPT = b ]; then

  BACK_HOST=`hostname -f`
  BACK_HOST_SHORT=`hostname -s`
  if [ $IP_COUNT == 1 ]; then
    TRELLIS_BACK_IP=`ifconfig | grep "inet addr" | grep -v 127.0.0.1 | awk  -F: '{ print $2 }' | awk '{ print $1 }'`
  else
	TRELLIS_BACK_IP="0.0.0.0"
  fi
    
  THIS_HOST=$BACK_HOST
  THIS_HOST_SHORT=$BACK_HOST_SHORT
  THIS_IP=$TRELLIS_BACK_IP
  
  if [ `cat /etc/hosts | grep trellis-front -c` = 1 ]; then  
    echo "[Info]: Detecting front server..."
    DETECTED_FRONT_CHECK=`ping trellis-front -c 1 | grep "PING"`
    DETECTED_FRONT_NAME=`echo "$DETECTED_FRONT_CHECK" | awk '{ print $2 }'`
    DETECTED_TRELLIS_FRONT_IP=`echo "$DETECTED_FRONT_CHECK" | awk '{ print $3 }' | tr -d '(' | tr -d ')'`    
  fi
  if [ "$DETECTED_FRONT_CHECK" ]; then
    echo "Front server detected"
    echo -n "Is the front server: $DETECTED_FRONT_NAME ($DETECTED_TRELLIS_FRONT_IP) (y/n)? "

    while read DETECTED_CHECK_USE; do
         if [[ -z "${DETECTED_CHECK_USE}" ]]; then
              echo "Please confirm the front server details"
         else
              break
         fi
    done
    
    if [ $DETECTED_CHECK_USE = "yes" -o $DETECTED_CHECK_USE = "Y" -o $DETECTED_CHECK_USE = "YES" -o $DETECTED_CHECK_USE = "y" ]; then
      DETECTED_CHECK_USE=y
    else
      DETECTED_CHECK_USE=n      
    fi
  else
      DETECTED_CHECK_USE=n     
  fi
  
  if [ $DETECTED_CHECK_USE = "y" ]; then
    FRONT_HOST="$DETECTED_FRONT_NAME"
    TRELLIS_FRONT_IP="$DETECTED_TRELLIS_FRONT_IP"
  else
    echo -n "What is the hostname of the front server (FQDN preferred)? "
    read FRONT_HOST
    ##  Since this is the back, we can't verify ip and host for the front, as it will
    ##  not have been built yet in most cases
    echo ""
    echo "INFO: The name entered was $FRONT_HOST, if this is incorrect you will need to change the entries manually in /etc/hosts"
    echo ""
    echo -n "What is the IP address for the front server? "
    read TRELLIS_FRONT_IP
    echo ""
    echo "INFO: The ip address entered was $TRELLIS_FRONT_IP, if this is incorrect you will need to change the entries manually in /etc/hosts"  
  fi
  FRONT_HOST_SHORT=`echo "$FRONT_HOST" | awk -F. '{ print $1 }'`

else
  FRONT_HOST=`hostname -f`
  FRONT_HOST_SHORT=`hostname -s`
  
  if [ $IP_COUNT == 1 ]; then
    TRELLIS_FRONT_IP=`ifconfig | grep "inet addr" | grep -v 127.0.0.1 | awk  -F: '{ print $2 }' | awk '{ print $1 }'`
  else
	TRELLIS_FRONT_IP="0.0.0.0"
  fi

  THIS_HOST=$FRONT_HOST
  THIS_HOST_SHORT=$FRONT_HOST_SHORT
  THIS_IP=$TRELLIS_FRONT_IP  
  
  if [ `cat /etc/hosts | grep trellis-back -c` = 1 ]; then  
    echo "[Info]: Detecting back server..."
    DETECTED_BACK_CHECK=`ping trellis-back -c 1 | grep "PING"`
    DETECTED_BACK_NAME=`echo "$DETECTED_BACK_CHECK" | awk '{ print $2 }'`
    DETECTED_TRELLIS_BACK_IP=`echo "$DETECTED_BACK_CHECK" | awk '{ print $3 }' | tr -d '(' | tr -d ')'`      
  fi
  if [ "$DETECTED_BACK_CHECK" ]; then
    echo "Back server detected"
    echo -n "Is the back server: $DETECTED_BACK_NAME ($DETECTED_TRELLIS_BACK_IP) (y/n)? "
    
    while read DETECTED_CHECK_USE; do
         if [[ -z "${DETECTED_CHECK_USE}" ]]; then
              echo "Please confirm the back server details"
         else
              break
         fi
    done
    
    
    if [ $DETECTED_CHECK_USE = "yes" -o $DETECTED_CHECK_USE = "Y" -o $DETECTED_CHECK_USE = "YES" -o $DETECTED_CHECK_USE = "y" ]; then
      DETECTED_CHECK_USE=y
    else
      DETECTED_CHECK_USE=n      
    fi
  else
    DETECTED_CHECK_USE=n
  fi  

  if [ $DETECTED_CHECK_USE = y ]; then
    BACK_HOST="$DETECTED_BACK_NAME"
    TRELLIS_BACK_IP="$DETECTED_TRELLIS_BACK_IP"
  else
    echo -n "What is the hostname of the back server (FQDN preferred)? "
    read BACK_HOST
    ##  Will verify the back server since it should be built and running.    
    echo ""
    echo "INFO: The name entered was $BACK_HOST, will try to verify the server by hostname"  
    ping -c 1 $BACK_HOST
    if [ $? -eq "0" ]; then
      echo "$BACK_HOST was pinged succesfully"
    else
      echo "WARNING: $BACK_HOST was not pinged successfully. This could just mean that the DNS is not set up correctly yet, or there could be a problem with the name entered that will have to be fixed in the /etc/hosts file manually"
    fi

    echo ""
    echo -n "What is the IP address for the back server? "
    read TRELLIS_BACK_IP
    echo ""
    echo "INFO: The ip address entered was $TRELLIS_BACK_IP, will try to verify that the ip is active"
    ping -c 1 $TRELLIS_BACK_IP
    if [ $? -eq "0" ]; then
      echo "$TRELLIS_BACK_IP was pinged succesfully"
    else
      echo "WARNING: $TRELLIS_BACK_IP was not pinged successfully. This could just mean that there was a brief network blip, or the IP could have been entered wrong and will need to be fixed in the /etc/hosts file manually"
    fi    
  fi
  BACK_HOST_SHORT=`echo "$BACK_HOST" | awk -F. '{ print $1 }'`
fi
######

#
#  Added in check to make sure IP's are not the same
#
if [ "$TRELLIS_BACK_IP" = "$TRELLIS_FRONT_IP" -o "$BACK_HOST" = "$FRONT_HOST" ]; then
    echo "The IP addresses or hostnames supplied for the back and front can NOT be identical, please re-run the script"
    exit
fi

if [ "$BACK_HOST" == "$BACK_HOST_SHORT" ]; then
    BACK_HOST_BOTH="$BACK_HOST"
else
    BACK_HOST_BOTH="$BACK_HOST $BACK_HOST_SHORT"
fi

if [ "$FRONT_HOST" == "$FRONT_HOST_SHORT" ]; then
    FRONT_HOST_BOTH="$FRONT_HOST"
else
    FRONT_HOST_BOTH="$FRONT_HOST $FRONT_HOST_SHORT"
fi

cat /etc/hosts > $CFG_OUTPUT_BUNDLE_FOLDER/hosts
cat >> $CFG_OUTPUT_BUNDLE_FOLDER/hosts << EOF

#
#  Trellis FQDNs
#
$TRELLIS_FRONT_IP $FRONT_HOST_BOTH
$TRELLIS_BACK_IP $BACK_HOST_BOTH

#
# Trellis Front Aliases
#
$TRELLIS_FRONT_IP $FRONT_HOST_BOTH weblogic-admin Presentation-Operational-internal Presentation-Analytical-internal BAM-internal SOA-Operational-internal SOA-Analytical-internal MPS-proxy-internal CEP-Engine-internal OHS-Balancer-internal OSB-Server-internal Authentication-internal Authorization-internal-local Flexera-Server-internal vip-external 3rdparty-vip-external vip-internal MPS-proxy-external Search-internal Reporting-internal trellis-front trellis-platform

#
# Trellis Back Aliases
#
$TRELLIS_BACK_IP $BACK_HOST_BOTH MDS-Database-internal CDM-Database-internal TSD-Database-internal TSD-Database-external Authorization-internal-admin trellis-back
EOF

cat > $CFG_OUTPUT_BUNDLE_FOLDER/limits.conf << EOF
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft stack 10240
EOF

if [ $TRELLIS_NEW_INSTALL = "Yes" ]; then
    NODE_MANAGER_DISABLE="yes"
else
    NODE_MANAGER_DISABLE="no"
fi

cat > $CFG_OUTPUT_BUNDLE_FOLDER/nodemanager << EOF
# default: off - the Trellis installer will reset disable = yes to no at install time. 
# description: nodemanager as a service
# Running as to work around an issue where the ulimits for the user are not getting set. This process starts as root but lowers privs to oracle at runtime.
# using su - forces the ulimit via PAM
service nodemgrsvc
{
	type            = UNLISTED
	disable         = $NODE_MANAGER_DISABLE
	socket_type     = stream
	protocol        = tcp
	wait            = yes
	user            = root
	port            = 5556
	flags           = NOLIBWRAP
	log_on_success  += DURATION HOST USERID
	server          = /bin/su
	server_args		= - oracle -c /u01/trellis/startNodeManager.sh
}
EOF

cat > $CFG_OUTPUT_BUNDLE_FOLDER/sudoer.d-trellis <<FIN

### START TRELLIS PRIVILEDGE ESCALATION ###
oracle		ALL=			NOPASSWD: /etc/init.d/trellis
oracle		ALL=			NOPASSWD: /u03/root/disable_escalation.sh
oracle		ALL=			NOPASSWD: /u03/root/enable_nodemanager.sh
oracle		ALL=			NOPASSWD: /u03/root/ohs_enable_chroot.sh
oracle		ALL=			NOPASSWD: /u03/root/postinstall_env_setup.sh
oracle		ALL=			NOPASSWD: /u03/root/preinstall_env_setup.sh
oracle		ALL=			NOPASSWD: /u03/root/sli_install.bin
### END TRELLIS PRIVILEDGE ESCALATION ###
FIN

cat > $CFG_OUTPUT_BUNDLE_FOLDER/sysctl.conf <<FIN

#
#  Added/modified for Trellis installs
#
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmall = 2097152
kernel.shmmax = 536870912
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048586
kernel.random.write_wakeup_threshold = 1024
######
FIN

cat > $CFG_OUTPUT_BUNDLE_FOLDER/oraInst.loc <<FIN
inventory_loc=/u01/app/oraInventory
inst_group=oinstall
FIN

cat /etc/pam.d/login >> $CFG_OUTPUT_BUNDLE_FOLDER/pam.d-login
cat >> $CFG_OUTPUT_BUNDLE_FOLDER/pam.d-login << EOF

# Enforce resource limits for Oracle user via /etc/security/limits.conf
session     required      pam_limits.so
EOF

#
#  Output Summary
#
#No Longer Used - Multipule Nic's not showing anything, other code is using the implemented code
#CUR_NIC=`ifconfig -a | grep eth | sed -n 's_\(eth[0-9]\+\)\s*.*_\1_p'` 
#CUR_NIC_IP=`ifconfig $CUR_NIC | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`

ARCHITECTURE=`uname -m`

if [ "$ARCHITECTURE" = "x86_64" ]
then 
    CUR_OS="`cat /etc/redhat-release` [64 Bit]"
elif ["$ARCHITECTURE" = "i686" ]; then
    CUR_OS="`cat /etc/redhat-release` [32 Bit]"
else
    CUR_OS=`cat /etc/redhat-release`
fi

CUR_PROCESSOR="`cat /proc/cpuinfo | grep "model name" -c` x `cat /proc/cpuinfo | grep "model name" -m 1 | cut -f2 -d":"` (`lscpu | grep "Core(s) per socket" | cut -f2 -d":" | sed 's/^[ \t]*//;s/[ \t]*$//'` core)"
CUR_TOTAL_CORES=`nproc`
CUR_MEMORY="`bc -l <<< "scale=2; $(cat /proc/meminfo | grep MemTotal | tr -cd '[[:digit:]]') / (1024^2)"` GB"

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
CUR_TIMEZONE=`cat /etc/sysconfig/clock | grep ZONE | cut -f2 -d '=' | sed 's/[\"]//g'`
CUR_TIMESERVER=`cat /etc/ntp.conf | grep server | grep -v \# | cut -f2 -d" " | sed ':a;N;$!ba;s/\n/ /g' | sed 's/ /\n\t                  /g'`
CUR_DATE=`date`
#  

echo
echo "###############################################################################"
echo "#"
echo "#       Trellis 3.x Pre-Install Report (Version: $SCRIPT_VERSION)"
echo "#"
echo "###############################################################################"
if [ $TRELLIS_NEW_INSTALL = "No" ]; then
    echo 
    echo "Current Trellis Version:  "$TRELLIS_INSTALLED_VERSION
	echo 
fi
echo 'Server  Name:            '    $THIS_HOST_SHORT  > `tty`
echo 'Fullly Qualified Name:   '    $THIS_HOST > `tty`
echo 'IP Address:              '    $THIS_IP > `tty`
echo 'OS Version:              '    $CUR_OS > `tty`
echo 'Processor(s):            '    $CUR_PROCESSOR > `tty`
echo 'Total Core(s):           '    $CUR_TOTAL_CORES > `tty`
echo 'Memory:                  '    $CUR_MEMORY > `tty`
echo 'Server Type:             '    $CUR_VIRTUAL_SUMMARY > `tty`
echo 'Date Time:               '    $CUR_DATE > `tty`
echo 'Time Zone:               '    $CUR_TIMEZONE > `tty`
echo 'Time Server:             '    "$CUR_TIMESERVER" > `tty`
echo
echo -e $'**********************************************************************\n'  > `tty`
#####

#
#  Redirect Output to Log File by Default
#
exec > ${CFG_LOGFILE_PATH} 2>&1
#exec > ${CFG_LOGFILE_PATH}
#####

echo -e "${BOLD}Performing Verification Checks${NONE}" > `tty`
echo > `tty`
echo -e '########################################################################################\n  Trellis Linux OS Report (Version: '$SCRIPT_VERSION')\n########################################################################################'
echo 
if [ $TRELLIS_NEW_INSTALL = "Yes" ]; then
    echo -e "[INFO]\tChecks performed for new installation"
else
    echo -e "[INFO]\tChecks performed for patch installation"
fi
echo
echo -e '########################################################################################\n  Installation Configuration Details\n########################################################################################'
if [ $TRELLIS_NEW_INSTALL = "No" ]; then
    echo 
    echo "Current Trellis Version:  "$TRELLIS_INSTALLED_VERSION
	echo 
fi
echo 'Server  Name:            '    $THIS_HOST_SHORT
echo 'Fullly Qualified Name:   '    $THIS_HOST
echo 'IP Address:              '    $THIS_IP
echo 'OS Version:              '    $CUR_OS
echo 'Processor(s):            '    $CUR_PROCESSOR
echo 'Total Core(s):           '    $CUR_TOTAL_CORES
echo 'Memory:                  '    $CUR_MEMORY
echo 'Server Type:             '    $CUR_VIRTUAL_SUMMARY
echo 'Date Time:               '    $CUR_DATE
echo 'Time Zone:               '    $CUR_TIMEZONE
echo 'Time Server:    	       '    "$CUR_TIMESERVER" 
echo '########################################################################################\n'
echo 
echo
echo '********************************************************************************'
echo '********************** HDD Space / Capacity Summary ****************************'
echo '********************************************************************************'
echo 'Verify that server has 300GB Space or the following:'
echo ' - /home/oracle = 20GB'
echo ' - /tmp = 10GB'
echo ' - /u01 = 100GB'
echo ' - /u02 = 100GB'
echo ' - /u03 = 30GB'
echo ' - /u05 = 30GB'
echo ' - / = 10GB'
echo
df -h
echo -e '########################################################################################\n'

###############################################################################
#       REQ 1.* OPERATING SYSTEM CHECKS
###############################################################################
echo -e '########################################################################################\n\tLinux Checks\n########################################################################################'

# (19 Sep 2018 - (RayD) Test removed to avoid conflict with Engineering Precheck, but keep the setting of the RELEASE variable
##
##  REQ 1.1 - Operating System is the correct version
##
#echo -e '########################################################################################\n\t[REQ 1.1] Operating System Support\n########################################################################################'
#echo -n "[REQ 1.1]   Checking OS release..." > `tty`
#echo "[REQ 1.1]   Checking OS release..."
#cat /etc/redhat-release
#uname -m
#echo
RELEASE=`cat /etc/redhat-release | awk '{print $7}'`
#
#if [ "$RELEASE" == 6.4 -o "$RELEASE" == 6.5 -o "$RELEASE" == 6.6 ]; then
#    echo "    ==>RH Release is $RELEASE. OK."
#    echo -e "\t\t\t\t${GREEN}Passed${NONE}" > `tty`
#elif [ "$RELEASE" == 6.7 -o "$RELEASE" == 6.8 ]; then
#    echo "    ==>RH Release is $RELEASE. OK (Approval Needed)"
#    echo -e "\t\t\t\t${GREEN}Passed [Limited]${NONE}" > `tty`	
#else
#    echo "    ==>Automatic check failed!"
#    echo -e "\t\t\t\t${RED}Failed${NONE}" > `tty`
#	echo "    WARNING: OS Release is NOT supported, this script may not be 100% reliable" > `tty`
#fi
#####

#
# Operating System Specifical Variables
#
# (9 Oct 2018 - (RayD) Add TIMEZONE_CMD to each OS for use in test 2.4
if [ "$RELEASE" == "5.9" ]; then
  IPTABLES_RESULT="Firewall is stopped."
  IP6TABLES_RESULT=""
  REQ_1_59_PACKAGES="kexec-tools fipscheck device-mapper-multipath sgpio emacs libsane-hpaio xorg-x11-utils xorg-x11-server-Xnest binutils compat-db compat-libstdc++-33 elfutils-libelf elfutils-libelf-devel gcc gcc-c++ glibc glibc-common glibc-devel libaio libaio-devel libgcc libstdc++ libstdc++-devel make openmotif screen sysstat unixODBC unixODBC-devel glibc-devel.i386 java-1.6.0-openjdk"
  ENTROPY="rngd -r /dev/urandom -t 2"
  ENTROPY_EXTRAOPTIONS="-r /dev/urandom -b"
  TIMEZONE_LIST="Africa/Abidjan Africa/Accra Africa/Addis_Ababa Africa/Algiers Africa/Asmara Africa/Asmera Africa/Bamako Africa/Bangui Africa/Banjul Africa/Bissau Africa/Blantyre Africa/Brazzaville Africa/Bujumbura Africa/Cairo Africa/Casablanca Africa/Ceuta Africa/Conakry Africa/Dakar Africa/Dar_es_Salaam Africa/Djibouti Africa/Douala Africa/El_Aaiun Africa/Freetown Africa/Gaborone Africa/Harare Africa/Johannesburg Africa/Kampala Africa/Khartoum Africa/Kigali Africa/Kinshasa Africa/Lagos Africa/Libreville Africa/Lome Africa/Luanda Africa/Lubumbashi Africa/Lusaka Africa/Malabo Africa/Maputo Africa/Maseru Africa/Mbabane Africa/Mogadishu Africa/Monrovia Africa/Nairobi Africa/Ndjamena Africa/Niamey Africa/Nouakchott Africa/Ouagadougou Africa/Porto-Novo Africa/Sao_Tome Africa/Timbuktu Africa/Tripoli Africa/Tunis Africa/Windhoek America/Adak America/Anchorage America/Anguilla America/Antigua America/Araguaina America/Argentina/Buenos_Aires America/Argentina/Catamarca America/Argentina/ComodRivadavia America/Argentina/Cordoba America/Argentina/Jujuy America/Argentina/La_Rioja America/Argentina/Mendoza America/Argentina/Rio_Gallegos America/Argentina/Salta America/Argentina/San_Juan America/Argentina/San_Luis America/Argentina/Tucuman America/Argentina/Ushuaia America/Aruba America/Asuncion America/Atikokan America/Atka America/Bahia America/Barbados America/Belem America/Belize America/Blanc-Sablon America/Boa_Vista America/Bogota America/Boise America/Buenos_Aires America/Cambridge_Bay America/Campo_Grande America/Cancun America/Caracas America/Catamarca America/Cayenne America/Cayman America/Chicago America/Chihuahua America/Coral_Harbour America/Cordoba America/Costa_Rica America/Cuiaba America/Curacao America/Danmarkshavn America/Dawson America/Dawson_Creek America/Denver America/Detroit America/Dominica America/Edmonton America/Eirunepe America/El_Salvador America/Ensenada America/Fort_Wayne America/Fortaleza America/Glace_Bay America/Godthab America/Goose_Bay America/Grand_Turk America/Grenada America/Guadeloupe America/Guatemala America/Guayaquil America/Guyana America/Halifax America/Havana America/Hermosillo America/Indiana/Indianapolis America/Indiana/Knox America/Indiana/Marengo America/Indiana/Petersburg America/Indiana/Tell_City America/Indiana/Vevay America/Indiana/Vincennes America/Indiana/Winamac America/Indianapolis America/Inuvik America/Iqaluit America/Jamaica America/Jujuy America/Juneau America/Kentucky/Louisville America/Kentucky/Monticello America/Knox_IN America/La_Paz America/Lima America/Los_Angeles America/Louisville America/Maceio America/Managua America/Manaus America/Marigot America/Martinique America/Mazatlan America/Mendoza America/Menominee America/Merida America/Mexico_City America/Miquelon America/Moncton America/Monterrey America/Montevideo America/Montreal America/Montserrat America/Nassau America/New_York America/Nipigon America/Nome America/Noronha America/North_Dakota/Center America/North_Dakota/New_Salem America/Panama America/Pangnirtung America/Paramaribo America/Phoenix America/Port_of_Spain America/Port-au-Prince America/Porto_Acre America/Porto_Velho America/Puerto_Rico America/Rainy_River America/Rankin_Inlet America/Recife America/Regina America/Resolute America/Rio_Branco America/Rosario America/Santiago America/Santo_Domingo America/Sao_Paulo America/Scoresbysund America/Shiprock America/St_Barthelemy America/St_Johns America/St_Kitts America/St_Lucia America/St_Thomas America/St_Vincent America/Swift_Current America/Tegucigalpa America/Thule America/Thunder_Bay America/Tijuana America/Toronto America/Tortola America/Vancouver America/Virgin America/Whitehorse America/Winnipeg America/Yakutat America/Yellowknife Antarctica/Casey Antarctica/Davis Antarctica/DumontDUrville Antarctica/Mawson Antarctica/McMurdo Antarctica/Palmer Antarctica/South_Pole Antarctica/Syowa Arctic/Longyearbyen Asia/Aden Asia/Almaty Asia/Amman Asia/Anadyr Asia/Aqtau Asia/Aqtobe Asia/Ashgabat Asia/Ashkhabad Asia/Baghdad Asia/Bahrain Asia/Baku Asia/Bangkok Asia/Beirut Asia/Bishkek Asia/Brunei Asia/Calcutta Asia/Choibalsan Asia/Chongqing Asia/Chungking Asia/Colombo Asia/Dacca Asia/Damascus Asia/Dhaka Asia/Dili Asia/Dubai Asia/Dushanbe Asia/Gaza Asia/Harbin Asia/Ho_Chi_Minh Asia/Hong_Kong Asia/Hovd Asia/Irkutsk Asia/Istanbul Asia/Jakarta Asia/Jayapura Asia/Jerusalem Asia/Kabul Asia/Kamchatka Asia/Karachi Asia/Kashgar Asia/Kathmandu Asia/Katmandu Asia/Kolkata Asia/Krasnoyarsk Asia/Kuala_Lumpur Asia/Kuching Asia/Kuwait Asia/Macao Asia/Macau Asia/Magadan Asia/Makassar Asia/Manila Asia/Muscat Asia/Nicosia Asia/Novosibirsk Asia/Omsk Asia/Oral Asia/Phnom_Penh Asia/Pontianak Asia/Pyongyang Asia/Qatar Asia/Qyzylorda Asia/Rangoon Asia/Riyadh Asia/Saigon Asia/Sakhalin Asia/Samarkand Asia/Seoul Asia/Shanghai Asia/Singapore Asia/Taipei Asia/Tashkent Asia/Tbilisi Asia/Tehran Asia/Tel_Aviv Asia/Thimbu Asia/Thimphu Asia/Tokyo Asia/Ujung_Pandang Asia/Ulaanbaatar Asia/Ulan_Bator Asia/Urumqi Asia/Vientiane Asia/Vladivostok Asia/Yakutsk Asia/Yekaterinburg Asia/Yerevan Atlantic/Azores Atlantic/Bermuda Atlantic/Canary Atlantic/Cape_Verde Atlantic/Faeroe Atlantic/Faroe Atlantic/Jan_Mayen Atlantic/Madeira Atlantic/Reykjavik Atlantic/South_Georgia Atlantic/St_Helena Atlantic/Stanley Australia/ACT Australia/Adelaide Australia/Brisbane Australia/Broken_Hill Australia/Canberra Australia/Currie Australia/Darwin Australia/Eucla Australia/Hobart Australia/LHI Australia/Lindeman Australia/Lord_Howe Australia/Melbourne Australia/North Australia/NSW Australia/Perth Australia/Queensland Australia/South Australia/Sydney Australia/Tasmania Australia/Victoria Australia/West Australia/Yancowinna Brazil/Acre Brazil/DeNoronha Brazil/East Brazil/West Canada/Atlantic Canada/Central Canada/Eastern Canada/East-Saskatchewan Canada/Mountain Canada/Newfoundland Canada/Pacific Canada/Saskatchewan Canada/Yukon CET Chile/Continental Chile/EasterIsland CST CST6CDT Cuba EET Egypt Eire EST EST5EDT Etc/GMT Etc/GMT+0 Etc/GMT+1 Etc/GMT+10 Etc/GMT+11 Etc/GMT+12 Etc/GMT+2 Etc/GMT+3 Etc/GMT+4 Etc/GMT+5 Etc/GMT+6 Etc/GMT+7 Etc/GMT+8 Etc/GMT+9 Etc/GMT0 Etc/GMT-0 Etc/GMT-1 Etc/GMT-10 Etc/GMT-11 Etc/GMT-12 Etc/GMT-13 Etc/GMT-14 Etc/GMT-2 Etc/GMT-3 Etc/GMT-4 Etc/GMT-5 Etc/GMT-6 Etc/GMT-7 Etc/GMT-8 Etc/GMT-9 Etc/Greenwich Europe/Amsterdam Europe/Andorra Europe/Athens Europe/Belfast Europe/Belgrade Europe/Berlin Europe/Bratislava Europe/Brussels Europe/Bucharest Europe/Budapest Europe/Chisinau Europe/Copenhagen Europe/Dublin Europe/Gibraltar Europe/Guernsey Europe/Helsinki Europe/Isle_of_Man Europe/Istanbul Europe/Jersey Europe/Kaliningrad Europe/Kiev Europe/Lisbon Europe/Ljubljana Europe/London Europe/Luxembourg Europe/Madrid Europe/Malta Europe/Mariehamn Europe/Minsk Europe/Monaco Europe/Moscow Europe/Nicosia Europe/Oslo Europe/Paris Europe/Prague Europe/Riga Europe/Rome Europe/Samara Europe/San_Marino Europe/Sarajevo Europe/Simferopol Europe/Skopje Europe/Sofia Europe/Stockholm Europe/Tallinn Europe/Tirane Europe/Tiraspol Europe/Uzhgorod Europe/Vaduz Europe/Vatican Europe/Vienna Europe/Vilnius Europe/Volgograd Europe/Warsaw Europe/Zagreb Europe/Zaporozhye Europe/Zurich GB GB-Eire GMT GMT+0 GMT0 GMT-0 Greenwich Hongkong HST Iceland Indian/Antananarivo Indian/Chagos Indian/Christmas Indian/Cocos Indian/Comoro Indian/Kerguelen Indian/Mahe Indian/Maldives Indian/Mauritius Indian/Mayotte Indian/Reunion Iran Israel Jamaica Japan Kwajalein Libya MET Mexico/BajaNorte Mexico/BajaSur Mexico/General MST MST7MDT Navajo NZ NZ-CHAT Pacific/Apia Pacific/Auckland Pacific/Chatham Pacific/Easter Pacific/Efate Pacific/Enderbury Pacific/Fakaofo Pacific/Fiji Pacific/Funafuti Pacific/Galapagos Pacific/Gambier Pacific/Guadalcanal Pacific/Guam Pacific/Honolulu Pacific/Johnston Pacific/Kiritimati Pacific/Kosrae Pacific/Kwajalein Pacific/Majuro Pacific/Marquesas Pacific/Midway Pacific/Nauru Pacific/Niue Pacific/Norfolk Pacific/Noumea Pacific/Pago_Pago Pacific/Palau Pacific/Pitcairn Pacific/Ponape Pacific/Port_Moresby Pacific/Rarotonga Pacific/Saipan Pacific/Samoa Pacific/Tahiti Pacific/Tarawa Pacific/Tongatapu Pacific/Truk Pacific/Wake Pacific/Wallis Pacific/Yap Poland Portugal PRC PST PST8PDT ROC ROK Singapore Turkey US/Alaska US/Aleutian US/Arizona US/Central US/Eastern US/East-Indiana US/Hawaii US/Indiana-Starke US/Michigan US/Mountain US/Pacific US/Pacific-New US/Samoa UTC WET W-SU"
  TIMEZONE_CMD="cat /etc/sysconfig/clock | grep ZONE | cut -f2 -d '=' | sed 's/[\"]//g'"
elif [ "$RELEASE" == "6.3" ]; then
  IPTABLES_RESULT="iptables: Firewall is not running."
  IP6TABLES_RESULT=""
  REQ_1_59_PACKAGES="binutils compat-db compat-libcap1 compat-libstdc++-33 compat-libstdc++-33.i686 device-mapper-multipath dos2unix elfutils-libelf elfutils-libelf-devel emacs fipscheck gcc gcc-c++ glibc glibc.i686 glibc-devel glibc-devel.i686 kexec-tools ksh libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libsane-hpaio libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 libXext libXi libXtst make openmotif openssl.i686 redhat-lsb redhat-lsb.i686 screen sgpio sysstat unixODBC unixODBC-devel xinetd.x86_64 java-1.6.0-openjdk"
  ENTROPY="rngd -r /dev/urandom -o /dev/random -t 0.01"
  ENTROPY_EXTRAOPTIONS="-i -r /dev/urandom -o /dev/random -b"
  TIMEZONE_LIST="Africa/Abidjan Africa/Accra Africa/Addis_Ababa Africa/Algiers Africa/Asmara Africa/Asmera Africa/Bamako Africa/Bangui Africa/Banjul Africa/Bissau Africa/Blantyre Africa/Brazzaville Africa/Bujumbura Africa/Cairo Africa/Casablanca Africa/Ceuta Africa/Conakry Africa/Dakar Africa/Dar_es_Salaam Africa/Djibouti Africa/Douala Africa/El_Aaiun Africa/Freetown Africa/Gaborone Africa/Harare Africa/Johannesburg Africa/Kampala Africa/Khartoum Africa/Kigali Africa/Kinshasa Africa/Lagos Africa/Libreville Africa/Lome Africa/Luanda Africa/Lubumbashi Africa/Lusaka Africa/Malabo Africa/Maputo Africa/Maseru Africa/Mbabane Africa/Mogadishu Africa/Monrovia Africa/Nairobi Africa/Ndjamena Africa/Niamey Africa/Nouakchott Africa/Ouagadougou Africa/Porto-Novo Africa/Sao_Tome Africa/Timbuktu Africa/Tripoli Africa/Tunis Africa/Windhoek America/Adak America/Anchorage America/Anguilla America/Antigua America/Araguaina America/Argentina/Buenos_Aires America/Argentina/Catamarca America/Argentina/ComodRivadavia America/Argentina/Cordoba America/Argentina/Jujuy America/Argentina/La_Rioja America/Argentina/Mendoza America/Argentina/Rio_Gallegos America/Argentina/Salta America/Argentina/San_Juan America/Argentina/San_Luis America/Argentina/Tucuman America/Argentina/Ushuaia America/Aruba America/Asuncion America/Atikokan America/Atka America/Bahia America/Barbados America/Belem America/Belize America/Blanc-Sablon America/Boa_Vista America/Bogota America/Boise America/Buenos_Aires America/Cambridge_Bay America/Campo_Grande America/Cancun America/Caracas America/Catamarca America/Cayenne America/Cayman America/Chicago America/Chihuahua America/Coral_Harbour America/Cordoba America/Costa_Rica America/Cuiaba America/Curacao America/Danmarkshavn America/Dawson America/Dawson_Creek America/Denver America/Detroit America/Dominica America/Edmonton America/Eirunepe America/El_Salvador America/Ensenada America/Fort_Wayne America/Fortaleza America/Glace_Bay America/Godthab America/Goose_Bay America/Grand_Turk America/Grenada America/Guadeloupe America/Guatemala America/Guayaquil America/Guyana America/Halifax America/Havana America/Hermosillo America/Indiana/Indianapolis America/Indiana/Knox America/Indiana/Marengo America/Indiana/Petersburg America/Indiana/Tell_City America/Indiana/Vevay America/Indiana/Vincennes America/Indiana/Winamac America/Indianapolis America/Inuvik America/Iqaluit America/Jamaica America/Jujuy America/Juneau America/Kentucky/Louisville America/Kentucky/Monticello America/Knox_IN America/La_Paz America/Lima America/Los_Angeles America/Louisville America/Maceio America/Managua America/Manaus America/Marigot America/Martinique America/Mazatlan America/Mendoza America/Menominee America/Merida America/Mexico_City America/Miquelon America/Moncton America/Monterrey America/Montevideo America/Montreal America/Montserrat America/Nassau America/New_York America/Nipigon America/Nome America/Noronha America/North_Dakota/Center America/North_Dakota/New_Salem America/Panama America/Pangnirtung America/Paramaribo America/Phoenix America/Port_of_Spain America/Port-au-Prince America/Porto_Acre America/Porto_Velho America/Puerto_Rico America/Rainy_River America/Rankin_Inlet America/Recife America/Regina America/Resolute America/Rio_Branco America/Rosario America/Santiago America/Santo_Domingo America/Sao_Paulo America/Scoresbysund America/Shiprock America/St_Barthelemy America/St_Johns America/St_Kitts America/St_Lucia America/St_Thomas America/St_Vincent America/Swift_Current America/Tegucigalpa America/Thule America/Thunder_Bay America/Tijuana America/Toronto America/Tortola America/Vancouver America/Virgin America/Whitehorse America/Winnipeg America/Yakutat America/Yellowknife Antarctica/Casey Antarctica/Davis Antarctica/DumontDUrville Antarctica/Mawson Antarctica/McMurdo Antarctica/Palmer Antarctica/South_Pole Antarctica/Syowa Arctic/Longyearbyen Asia/Aden Asia/Almaty Asia/Amman Asia/Anadyr Asia/Aqtau Asia/Aqtobe Asia/Ashgabat Asia/Ashkhabad Asia/Baghdad Asia/Bahrain Asia/Baku Asia/Bangkok Asia/Beirut Asia/Bishkek Asia/Brunei Asia/Calcutta Asia/Choibalsan Asia/Chongqing Asia/Chungking Asia/Colombo Asia/Dacca Asia/Damascus Asia/Dhaka Asia/Dili Asia/Dubai Asia/Dushanbe Asia/Gaza Asia/Harbin Asia/Ho_Chi_Minh Asia/Hong_Kong Asia/Hovd Asia/Irkutsk Asia/Istanbul Asia/Jakarta Asia/Jayapura Asia/Jerusalem Asia/Kabul Asia/Kamchatka Asia/Karachi Asia/Kashgar Asia/Kathmandu Asia/Katmandu Asia/Kolkata Asia/Krasnoyarsk Asia/Kuala_Lumpur Asia/Kuching Asia/Kuwait Asia/Macao Asia/Macau Asia/Magadan Asia/Makassar Asia/Manila Asia/Muscat Asia/Nicosia Asia/Novosibirsk Asia/Omsk Asia/Oral Asia/Phnom_Penh Asia/Pontianak Asia/Pyongyang Asia/Qatar Asia/Qyzylorda Asia/Rangoon Asia/Riyadh Asia/Saigon Asia/Sakhalin Asia/Samarkand Asia/Seoul Asia/Shanghai Asia/Singapore Asia/Taipei Asia/Tashkent Asia/Tbilisi Asia/Tehran Asia/Tel_Aviv Asia/Thimbu Asia/Thimphu Asia/Tokyo Asia/Ujung_Pandang Asia/Ulaanbaatar Asia/Ulan_Bator Asia/Urumqi Asia/Vientiane Asia/Vladivostok Asia/Yakutsk Asia/Yekaterinburg Asia/Yerevan Atlantic/Azores Atlantic/Bermuda Atlantic/Canary Atlantic/Cape_Verde Atlantic/Faeroe Atlantic/Faroe Atlantic/Jan_Mayen Atlantic/Madeira Atlantic/Reykjavik Atlantic/South_Georgia Atlantic/St_Helena Atlantic/Stanley Australia/ACT Australia/Adelaide Australia/Brisbane Australia/Broken_Hill Australia/Canberra Australia/Currie Australia/Darwin Australia/Eucla Australia/Hobart Australia/LHI Australia/Lindeman Australia/Lord_Howe Australia/Melbourne Australia/North Australia/NSW Australia/Perth Australia/Queensland Australia/South Australia/Sydney Australia/Tasmania Australia/Victoria Australia/West Australia/Yancowinna Brazil/Acre Brazil/DeNoronha Brazil/East Brazil/West Canada/Atlantic Canada/Central Canada/Eastern Canada/East-Saskatchewan Canada/Mountain Canada/Newfoundland Canada/Pacific Canada/Saskatchewan Canada/Yukon CET Chile/Continental Chile/EasterIsland CST CST6CDT Cuba EET Egypt Eire EST EST5EDT Etc/GMT Etc/GMT+0 Etc/GMT+1 Etc/GMT+10 Etc/GMT+11 Etc/GMT+12 Etc/GMT+2 Etc/GMT+3 Etc/GMT+4 Etc/GMT+5 Etc/GMT+6 Etc/GMT+7 Etc/GMT+8 Etc/GMT+9 Etc/GMT0 Etc/GMT-0 Etc/GMT-1 Etc/GMT-10 Etc/GMT-11 Etc/GMT-12 Etc/GMT-13 Etc/GMT-14 Etc/GMT-2 Etc/GMT-3 Etc/GMT-4 Etc/GMT-5 Etc/GMT-6 Etc/GMT-7 Etc/GMT-8 Etc/GMT-9 Etc/Greenwich Europe/Amsterdam Europe/Andorra Europe/Athens Europe/Belfast Europe/Belgrade Europe/Berlin Europe/Bratislava Europe/Brussels Europe/Bucharest Europe/Budapest Europe/Chisinau Europe/Copenhagen Europe/Dublin Europe/Gibraltar Europe/Guernsey Europe/Helsinki Europe/Isle_of_Man Europe/Istanbul Europe/Jersey Europe/Kaliningrad Europe/Kiev Europe/Lisbon Europe/Ljubljana Europe/London Europe/Luxembourg Europe/Madrid Europe/Malta Europe/Mariehamn Europe/Minsk Europe/Monaco Europe/Moscow Europe/Nicosia Europe/Oslo Europe/Paris Europe/Prague Europe/Riga Europe/Rome Europe/Samara Europe/San_Marino Europe/Sarajevo Europe/Simferopol Europe/Skopje Europe/Sofia Europe/Stockholm Europe/Tallinn Europe/Tirane Europe/Tiraspol Europe/Uzhgorod Europe/Vaduz Europe/Vatican Europe/Vienna Europe/Vilnius Europe/Volgograd Europe/Warsaw Europe/Zagreb Europe/Zaporozhye Europe/Zurich GB GB-Eire GMT GMT+0 GMT0 GMT-0 Greenwich Hongkong HST Iceland Indian/Antananarivo Indian/Chagos Indian/Christmas Indian/Cocos Indian/Comoro Indian/Kerguelen Indian/Mahe Indian/Maldives Indian/Mauritius Indian/Mayotte Indian/Reunion Iran Israel Jamaica Japan Kwajalein Libya MET Mexico/BajaNorte Mexico/BajaSur Mexico/General MST MST7MDT Navajo NZ NZ-CHAT Pacific/Apia Pacific/Auckland Pacific/Chatham Pacific/Easter Pacific/Efate Pacific/Enderbury Pacific/Fakaofo Pacific/Fiji Pacific/Funafuti Pacific/Galapagos Pacific/Gambier Pacific/Guadalcanal Pacific/Guam Pacific/Honolulu Pacific/Johnston Pacific/Kiritimati Pacific/Kosrae Pacific/Kwajalein Pacific/Majuro Pacific/Marquesas Pacific/Midway Pacific/Nauru Pacific/Niue Pacific/Norfolk Pacific/Noumea Pacific/Pago_Pago Pacific/Palau Pacific/Pitcairn Pacific/Ponape Pacific/Port_Moresby Pacific/Rarotonga Pacific/Saipan Pacific/Samoa Pacific/Tahiti Pacific/Tarawa Pacific/Tongatapu Pacific/Truk Pacific/Wake Pacific/Wallis Pacific/Yap Poland Portugal PRC PST PST8PDT ROC ROK Singapore Turkey US/Alaska US/Aleutian US/Arizona US/Central US/Eastern US/East-Indiana US/Hawaii US/Indiana-Starke US/Michigan US/Mountain US/Pacific US/Pacific-New US/Samoa UTC WET W-SU"
  TIMEZONE_CMD="cat /etc/sysconfig/clock | grep ZONE | cut -f2 -d '=' | sed 's/[\"]//g'"
elif [ "$RELEASE" == "6.4" ]; then
  IPTABLES_RESULT="iptables: Firewall is not running."
  IP6TABLES_RESULT=""
  REQ_1_59_PACKAGES="zlib zlib.i686 binutils compat-db compat-libcap1 compat-libstdc++-33 compat-libstdc++-33.i686 device-mapper-multipath dos2unix elfutils-libelf elfutils-libelf-devel emacs fipscheck gcc gcc-c++ glibc glibc.i686 glibc-devel glibc-devel.i686 kexec-tools ksh libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libsane-hpaio libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 libXext libXi libXtst make openmotif openssl.i686 redhat-lsb redhat-lsb-core.i686 screen sgpio sysstat unixODBC unixODBC-devel xinetd.x86_64 java-1.6.0-openjdk java-1.7.0-openjdk"
  ENTROPY="rngd -r /dev/urandom -o /dev/random -t 0.01"
  ENTROPY_EXTRAOPTIONS="-i -r /dev/urandom -o /dev/random -b"  
  TIMEZONE_LIST="Africa/Abidjan Africa/Accra Africa/Addis_Ababa Africa/Algiers Africa/Asmara Africa/Asmera Africa/Bamako Africa/Bangui Africa/Banjul Africa/Bissau Africa/Blantyre Africa/Brazzaville Africa/Bujumbura Africa/Cairo Africa/Casablanca Africa/Ceuta Africa/Conakry Africa/Dakar Africa/Dar_es_Salaam Africa/Djibouti Africa/Douala Africa/El_Aaiun Africa/Freetown Africa/Gaborone Africa/Harare Africa/Johannesburg Africa/Kampala Africa/Khartoum Africa/Kigali Africa/Kinshasa Africa/Lagos Africa/Libreville Africa/Lome Africa/Luanda Africa/Lubumbashi Africa/Lusaka Africa/Malabo Africa/Maputo Africa/Maseru Africa/Mbabane Africa/Mogadishu Africa/Monrovia Africa/Nairobi Africa/Ndjamena Africa/Niamey Africa/Nouakchott Africa/Ouagadougou Africa/Porto-Novo Africa/Sao_Tome Africa/Timbuktu Africa/Tripoli Africa/Tunis Africa/Windhoek America/Adak America/Anchorage America/Anguilla America/Antigua America/Araguaina America/Argentina/Buenos_Aires America/Argentina/Catamarca America/Argentina/ComodRivadavia America/Argentina/Cordoba America/Argentina/Jujuy America/Argentina/La_Rioja America/Argentina/Mendoza America/Argentina/Rio_Gallegos America/Argentina/Salta America/Argentina/San_Juan America/Argentina/San_Luis America/Argentina/Tucuman America/Argentina/Ushuaia America/Aruba America/Asuncion America/Atikokan America/Atka America/Bahia America/Barbados America/Belem America/Belize America/Blanc-Sablon America/Boa_Vista America/Bogota America/Boise America/Buenos_Aires America/Cambridge_Bay America/Campo_Grande America/Cancun America/Caracas America/Catamarca America/Cayenne America/Cayman America/Chicago America/Chihuahua America/Coral_Harbour America/Cordoba America/Costa_Rica America/Cuiaba America/Curacao America/Danmarkshavn America/Dawson America/Dawson_Creek America/Denver America/Detroit America/Dominica America/Edmonton America/Eirunepe America/El_Salvador America/Ensenada America/Fort_Wayne America/Fortaleza America/Glace_Bay America/Godthab America/Goose_Bay America/Grand_Turk America/Grenada America/Guadeloupe America/Guatemala America/Guayaquil America/Guyana America/Halifax America/Havana America/Hermosillo America/Indiana/Indianapolis America/Indiana/Knox America/Indiana/Marengo America/Indiana/Petersburg America/Indiana/Tell_City America/Indiana/Vevay America/Indiana/Vincennes America/Indiana/Winamac America/Indianapolis America/Inuvik America/Iqaluit America/Jamaica America/Jujuy America/Juneau America/Kentucky/Louisville America/Kentucky/Monticello America/Knox_IN America/La_Paz America/Lima America/Los_Angeles America/Louisville America/Maceio America/Managua America/Manaus America/Marigot America/Martinique America/Mazatlan America/Mendoza America/Menominee America/Merida America/Mexico_City America/Miquelon America/Moncton America/Monterrey America/Montevideo America/Montreal America/Montserrat America/Nassau America/New_York America/Nipigon America/Nome America/Noronha America/North_Dakota/Center America/North_Dakota/New_Salem America/Panama America/Pangnirtung America/Paramaribo America/Phoenix America/Port_of_Spain America/Port-au-Prince America/Porto_Acre America/Porto_Velho America/Puerto_Rico America/Rainy_River America/Rankin_Inlet America/Recife America/Regina America/Resolute America/Rio_Branco America/Rosario America/Santiago America/Santo_Domingo America/Sao_Paulo America/Scoresbysund America/Shiprock America/St_Barthelemy America/St_Johns America/St_Kitts America/St_Lucia America/St_Thomas America/St_Vincent America/Swift_Current America/Tegucigalpa America/Thule America/Thunder_Bay America/Tijuana America/Toronto America/Tortola America/Vancouver America/Virgin America/Whitehorse America/Winnipeg America/Yakutat America/Yellowknife Antarctica/Casey Antarctica/Davis Antarctica/DumontDUrville Antarctica/Mawson Antarctica/McMurdo Antarctica/Palmer Antarctica/South_Pole Antarctica/Syowa Arctic/Longyearbyen Asia/Aden Asia/Almaty Asia/Amman Asia/Anadyr Asia/Aqtau Asia/Aqtobe Asia/Ashgabat Asia/Ashkhabad Asia/Baghdad Asia/Bahrain Asia/Baku Asia/Bangkok Asia/Beirut Asia/Bishkek Asia/Brunei Asia/Calcutta Asia/Choibalsan Asia/Chongqing Asia/Chungking Asia/Colombo Asia/Dacca Asia/Damascus Asia/Dhaka Asia/Dili Asia/Dubai Asia/Dushanbe Asia/Gaza Asia/Harbin Asia/Ho_Chi_Minh Asia/Hong_Kong Asia/Hovd Asia/Irkutsk Asia/Istanbul Asia/Jakarta Asia/Jayapura Asia/Jerusalem Asia/Kabul Asia/Kamchatka Asia/Karachi Asia/Kashgar Asia/Kathmandu Asia/Katmandu Asia/Kolkata Asia/Krasnoyarsk Asia/Kuala_Lumpur Asia/Kuching Asia/Kuwait Asia/Macao Asia/Macau Asia/Magadan Asia/Makassar Asia/Manila Asia/Muscat Asia/Nicosia Asia/Novosibirsk Asia/Omsk Asia/Oral Asia/Phnom_Penh Asia/Pontianak Asia/Pyongyang Asia/Qatar Asia/Qyzylorda Asia/Rangoon Asia/Riyadh Asia/Saigon Asia/Sakhalin Asia/Samarkand Asia/Seoul Asia/Shanghai Asia/Singapore Asia/Taipei Asia/Tashkent Asia/Tbilisi Asia/Tehran Asia/Tel_Aviv Asia/Thimbu Asia/Thimphu Asia/Tokyo Asia/Ujung_Pandang Asia/Ulaanbaatar Asia/Ulan_Bator Asia/Urumqi Asia/Vientiane Asia/Vladivostok Asia/Yakutsk Asia/Yekaterinburg Asia/Yerevan Atlantic/Azores Atlantic/Bermuda Atlantic/Canary Atlantic/Cape_Verde Atlantic/Faeroe Atlantic/Faroe Atlantic/Jan_Mayen Atlantic/Madeira Atlantic/Reykjavik Atlantic/South_Georgia Atlantic/St_Helena Atlantic/Stanley Australia/ACT Australia/Adelaide Australia/Brisbane Australia/Broken_Hill Australia/Canberra Australia/Currie Australia/Darwin Australia/Eucla Australia/Hobart Australia/LHI Australia/Lindeman Australia/Lord_Howe Australia/Melbourne Australia/North Australia/NSW Australia/Perth Australia/Queensland Australia/South Australia/Sydney Australia/Tasmania Australia/Victoria Australia/West Australia/Yancowinna Brazil/Acre Brazil/DeNoronha Brazil/East Brazil/West Canada/Atlantic Canada/Central Canada/Eastern Canada/East-Saskatchewan Canada/Mountain Canada/Newfoundland Canada/Pacific Canada/Saskatchewan Canada/Yukon CET Chile/Continental Chile/EasterIsland CST CST6CDT Cuba EET Egypt Eire EST EST5EDT Etc/GMT Etc/GMT+0 Etc/GMT+1 Etc/GMT+10 Etc/GMT+11 Etc/GMT+12 Etc/GMT+2 Etc/GMT+3 Etc/GMT+4 Etc/GMT+5 Etc/GMT+6 Etc/GMT+7 Etc/GMT+8 Etc/GMT+9 Etc/GMT0 Etc/GMT-0 Etc/GMT-1 Etc/GMT-10 Etc/GMT-11 Etc/GMT-12 Etc/GMT-13 Etc/GMT-14 Etc/GMT-2 Etc/GMT-3 Etc/GMT-4 Etc/GMT-5 Etc/GMT-6 Etc/GMT-7 Etc/GMT-8 Etc/GMT-9 Etc/Greenwich Europe/Amsterdam Europe/Andorra Europe/Athens Europe/Belfast Europe/Belgrade Europe/Berlin Europe/Bratislava Europe/Brussels Europe/Bucharest Europe/Budapest Europe/Chisinau Europe/Copenhagen Europe/Dublin Europe/Gibraltar Europe/Guernsey Europe/Helsinki Europe/Isle_of_Man Europe/Istanbul Europe/Jersey Europe/Kaliningrad Europe/Kiev Europe/Lisbon Europe/Ljubljana Europe/London Europe/Luxembourg Europe/Madrid Europe/Malta Europe/Mariehamn Europe/Minsk Europe/Monaco Europe/Moscow Europe/Nicosia Europe/Oslo Europe/Paris Europe/Prague Europe/Riga Europe/Rome Europe/Samara Europe/San_Marino Europe/Sarajevo Europe/Simferopol Europe/Skopje Europe/Sofia Europe/Stockholm Europe/Tallinn Europe/Tirane Europe/Tiraspol Europe/Uzhgorod Europe/Vaduz Europe/Vatican Europe/Vienna Europe/Vilnius Europe/Volgograd Europe/Warsaw Europe/Zagreb Europe/Zaporozhye Europe/Zurich GB GB-Eire GMT GMT+0 GMT0 GMT-0 Greenwich Hongkong HST Iceland Indian/Antananarivo Indian/Chagos Indian/Christmas Indian/Cocos Indian/Comoro Indian/Kerguelen Indian/Mahe Indian/Maldives Indian/Mauritius Indian/Mayotte Indian/Reunion Iran Israel Jamaica Japan Kwajalein Libya MET Mexico/BajaNorte Mexico/BajaSur Mexico/General MST MST7MDT Navajo NZ NZ-CHAT Pacific/Apia Pacific/Auckland Pacific/Chatham Pacific/Easter Pacific/Efate Pacific/Enderbury Pacific/Fakaofo Pacific/Fiji Pacific/Funafuti Pacific/Galapagos Pacific/Gambier Pacific/Guadalcanal Pacific/Guam Pacific/Honolulu Pacific/Johnston Pacific/Kiritimati Pacific/Kosrae Pacific/Kwajalein Pacific/Majuro Pacific/Marquesas Pacific/Midway Pacific/Nauru Pacific/Niue Pacific/Norfolk Pacific/Noumea Pacific/Pago_Pago Pacific/Palau Pacific/Pitcairn Pacific/Ponape Pacific/Port_Moresby Pacific/Rarotonga Pacific/Saipan Pacific/Samoa Pacific/Tahiti Pacific/Tarawa Pacific/Tongatapu Pacific/Truk Pacific/Wake Pacific/Wallis Pacific/Yap Poland Portugal PRC PST PST8PDT ROC ROK Singapore Turkey US/Alaska US/Aleutian US/Arizona US/Central US/Eastern US/East-Indiana US/Hawaii US/Indiana-Starke US/Michigan US/Mountain US/Pacific US/Pacific-New US/Samoa UTC WET W-SU"  
  TIMEZONE_CMD="cat /etc/sysconfig/clock | grep ZONE | cut -f2 -d '=' | sed 's/[\"]//g'"
elif [ "$RELEASE" == "6.5" ] || [ "$RELEASE" == "6.6" ] || [ "$RELEASE" == "6.7" ] || [ "$RELEASE" == "6.8" ] || [ "$RELEASE" == "6.9" ] ; then
  IPTABLES_RESULT="iptables: Firewall is not running."
  IP6TABLES_RESULT=""
  REQ_1_59_PACKAGES="zlib zlib.i686 binutils compat-db compat-libcap1 compat-libstdc++-33 compat-libstdc++-33.i686 device-mapper-multipath dos2unix elfutils-libelf elfutils-libelf-devel emacs fipscheck gcc gcc-c++ glibc glibc.i686 glibc-devel glibc-devel.i686 kexec-tools ksh libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libsane-hpaio libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 libXext libXi libXtst make openmotif openssl openssl.i686 redhat-lsb redhat-lsb-core.i686 screen sgpio sysstat unixODBC unixODBC-devel xinetd.x86_64 java-1.6.0-openjdk java-1.7.0-openjdk"
  ENTROPY="rngd -r /dev/urandom -o /dev/random -t 0.01"
  ENTROPY_EXTRAOPTIONS=" -r /dev/urandom -o /dev/random -b"  
  TIMEZONE_LIST="Africa/Abidjan Africa/Accra Africa/Addis_Ababa Africa/Algiers Africa/Asmara Africa/Asmera Africa/Bamako Africa/Bangui Africa/Banjul Africa/Bissau Africa/Blantyre Africa/Brazzaville Africa/Bujumbura Africa/Cairo Africa/Casablanca Africa/Ceuta Africa/Conakry Africa/Dakar Africa/Dar_es_Salaam Africa/Djibouti Africa/Douala Africa/El_Aaiun Africa/Freetown Africa/Gaborone Africa/Harare Africa/Johannesburg Africa/Kampala Africa/Khartoum Africa/Kigali Africa/Kinshasa Africa/Lagos Africa/Libreville Africa/Lome Africa/Luanda Africa/Lubumbashi Africa/Lusaka Africa/Malabo Africa/Maputo Africa/Maseru Africa/Mbabane Africa/Mogadishu Africa/Monrovia Africa/Nairobi Africa/Ndjamena Africa/Niamey Africa/Nouakchott Africa/Ouagadougou Africa/Porto-Novo Africa/Sao_Tome Africa/Timbuktu Africa/Tripoli Africa/Tunis Africa/Windhoek America/Adak America/Anchorage America/Anguilla America/Antigua America/Araguaina America/Argentina/Buenos_Aires America/Argentina/Catamarca America/Argentina/ComodRivadavia America/Argentina/Cordoba America/Argentina/Jujuy America/Argentina/La_Rioja America/Argentina/Mendoza America/Argentina/Rio_Gallegos America/Argentina/Salta America/Argentina/San_Juan America/Argentina/San_Luis America/Argentina/Tucuman America/Argentina/Ushuaia America/Aruba America/Asuncion America/Atikokan America/Atka America/Bahia America/Barbados America/Belem America/Belize America/Blanc-Sablon America/Boa_Vista America/Bogota America/Boise America/Buenos_Aires America/Cambridge_Bay America/Campo_Grande America/Cancun America/Caracas America/Catamarca America/Cayenne America/Cayman America/Chicago America/Chihuahua America/Coral_Harbour America/Cordoba America/Costa_Rica America/Cuiaba America/Curacao America/Danmarkshavn America/Dawson America/Dawson_Creek America/Denver America/Detroit America/Dominica America/Edmonton America/Eirunepe America/El_Salvador America/Ensenada America/Fort_Wayne America/Fortaleza America/Glace_Bay America/Godthab America/Goose_Bay America/Grand_Turk America/Grenada America/Guadeloupe America/Guatemala America/Guayaquil America/Guyana America/Halifax America/Havana America/Hermosillo America/Indiana/Indianapolis America/Indiana/Knox America/Indiana/Marengo America/Indiana/Petersburg America/Indiana/Tell_City America/Indiana/Vevay America/Indiana/Vincennes America/Indiana/Winamac America/Indianapolis America/Inuvik America/Iqaluit America/Jamaica America/Jujuy America/Juneau America/Kentucky/Louisville America/Kentucky/Monticello America/Knox_IN America/La_Paz America/Lima America/Los_Angeles America/Louisville America/Maceio America/Managua America/Manaus America/Marigot America/Martinique America/Mazatlan America/Mendoza America/Menominee America/Merida America/Mexico_City America/Miquelon America/Moncton America/Monterrey America/Montevideo America/Montreal America/Montserrat America/Nassau America/New_York America/Nipigon America/Nome America/Noronha America/North_Dakota/Center America/North_Dakota/New_Salem America/Panama America/Pangnirtung America/Paramaribo America/Phoenix America/Port_of_Spain America/Port-au-Prince America/Porto_Acre America/Porto_Velho America/Puerto_Rico America/Rainy_River America/Rankin_Inlet America/Recife America/Regina America/Resolute America/Rio_Branco America/Rosario America/Santiago America/Santo_Domingo America/Sao_Paulo America/Scoresbysund America/Shiprock America/St_Barthelemy America/St_Johns America/St_Kitts America/St_Lucia America/St_Thomas America/St_Vincent America/Swift_Current America/Tegucigalpa America/Thule America/Thunder_Bay America/Tijuana America/Toronto America/Tortola America/Vancouver America/Virgin America/Whitehorse America/Winnipeg America/Yakutat America/Yellowknife Antarctica/Casey Antarctica/Davis Antarctica/DumontDUrville Antarctica/Mawson Antarctica/McMurdo Antarctica/Palmer Antarctica/South_Pole Antarctica/Syowa Arctic/Longyearbyen Asia/Aden Asia/Almaty Asia/Amman Asia/Anadyr Asia/Aqtau Asia/Aqtobe Asia/Ashgabat Asia/Ashkhabad Asia/Baghdad Asia/Bahrain Asia/Baku Asia/Bangkok Asia/Beirut Asia/Bishkek Asia/Brunei Asia/Calcutta Asia/Choibalsan Asia/Chongqing Asia/Chungking Asia/Colombo Asia/Dacca Asia/Damascus Asia/Dhaka Asia/Dili Asia/Dubai Asia/Dushanbe Asia/Gaza Asia/Harbin Asia/Ho_Chi_Minh Asia/Hong_Kong Asia/Hovd Asia/Irkutsk Asia/Istanbul Asia/Jakarta Asia/Jayapura Asia/Jerusalem Asia/Kabul Asia/Kamchatka Asia/Karachi Asia/Kashgar Asia/Kathmandu Asia/Katmandu Asia/Kolkata Asia/Krasnoyarsk Asia/Kuala_Lumpur Asia/Kuching Asia/Kuwait Asia/Macao Asia/Macau Asia/Magadan Asia/Makassar Asia/Manila Asia/Muscat Asia/Nicosia Asia/Novosibirsk Asia/Omsk Asia/Oral Asia/Phnom_Penh Asia/Pontianak Asia/Pyongyang Asia/Qatar Asia/Qyzylorda Asia/Rangoon Asia/Riyadh Asia/Saigon Asia/Sakhalin Asia/Samarkand Asia/Seoul Asia/Shanghai Asia/Singapore Asia/Taipei Asia/Tashkent Asia/Tbilisi Asia/Tehran Asia/Tel_Aviv Asia/Thimbu Asia/Thimphu Asia/Tokyo Asia/Ujung_Pandang Asia/Ulaanbaatar Asia/Ulan_Bator Asia/Urumqi Asia/Vientiane Asia/Vladivostok Asia/Yakutsk Asia/Yekaterinburg Asia/Yerevan Atlantic/Azores Atlantic/Bermuda Atlantic/Canary Atlantic/Cape_Verde Atlantic/Faeroe Atlantic/Faroe Atlantic/Jan_Mayen Atlantic/Madeira Atlantic/Reykjavik Atlantic/South_Georgia Atlantic/St_Helena Atlantic/Stanley Australia/ACT Australia/Adelaide Australia/Brisbane Australia/Broken_Hill Australia/Canberra Australia/Currie Australia/Darwin Australia/Eucla Australia/Hobart Australia/LHI Australia/Lindeman Australia/Lord_Howe Australia/Melbourne Australia/North Australia/NSW Australia/Perth Australia/Queensland Australia/South Australia/Sydney Australia/Tasmania Australia/Victoria Australia/West Australia/Yancowinna Brazil/Acre Brazil/DeNoronha Brazil/East Brazil/West Canada/Atlantic Canada/Central Canada/Eastern Canada/East-Saskatchewan Canada/Mountain Canada/Newfoundland Canada/Pacific Canada/Saskatchewan Canada/Yukon CET Chile/Continental Chile/EasterIsland CST CST6CDT Cuba EET Egypt Eire EST EST5EDT Etc/GMT Etc/GMT+0 Etc/GMT+1 Etc/GMT+10 Etc/GMT+11 Etc/GMT+12 Etc/GMT+2 Etc/GMT+3 Etc/GMT+4 Etc/GMT+5 Etc/GMT+6 Etc/GMT+7 Etc/GMT+8 Etc/GMT+9 Etc/GMT0 Etc/GMT-0 Etc/GMT-1 Etc/GMT-10 Etc/GMT-11 Etc/GMT-12 Etc/GMT-13 Etc/GMT-14 Etc/GMT-2 Etc/GMT-3 Etc/GMT-4 Etc/GMT-5 Etc/GMT-6 Etc/GMT-7 Etc/GMT-8 Etc/GMT-9 Etc/Greenwich Europe/Amsterdam Europe/Andorra Europe/Athens Europe/Belfast Europe/Belgrade Europe/Berlin Europe/Bratislava Europe/Brussels Europe/Bucharest Europe/Budapest Europe/Chisinau Europe/Copenhagen Europe/Dublin Europe/Gibraltar Europe/Guernsey Europe/Helsinki Europe/Isle_of_Man Europe/Istanbul Europe/Jersey Europe/Kaliningrad Europe/Kiev Europe/Lisbon Europe/Ljubljana Europe/London Europe/Luxembourg Europe/Madrid Europe/Malta Europe/Mariehamn Europe/Minsk Europe/Monaco Europe/Moscow Europe/Nicosia Europe/Oslo Europe/Paris Europe/Prague Europe/Riga Europe/Rome Europe/Samara Europe/San_Marino Europe/Sarajevo Europe/Simferopol Europe/Skopje Europe/Sofia Europe/Stockholm Europe/Tallinn Europe/Tirane Europe/Tiraspol Europe/Uzhgorod Europe/Vaduz Europe/Vatican Europe/Vienna Europe/Vilnius Europe/Volgograd Europe/Warsaw Europe/Zagreb Europe/Zaporozhye Europe/Zurich GB GB-Eire GMT GMT+0 GMT0 GMT-0 Greenwich Hongkong HST Iceland Indian/Antananarivo Indian/Chagos Indian/Christmas Indian/Cocos Indian/Comoro Indian/Kerguelen Indian/Mahe Indian/Maldives Indian/Mauritius Indian/Mayotte Indian/Reunion Iran Israel Jamaica Japan Kwajalein Libya MET Mexico/BajaNorte Mexico/BajaSur Mexico/General MST MST7MDT Navajo NZ NZ-CHAT Pacific/Apia Pacific/Auckland Pacific/Chatham Pacific/Easter Pacific/Efate Pacific/Enderbury Pacific/Fakaofo Pacific/Fiji Pacific/Funafuti Pacific/Galapagos Pacific/Gambier Pacific/Guadalcanal Pacific/Guam Pacific/Honolulu Pacific/Johnston Pacific/Kiritimati Pacific/Kosrae Pacific/Kwajalein Pacific/Majuro Pacific/Marquesas Pacific/Midway Pacific/Nauru Pacific/Niue Pacific/Norfolk Pacific/Noumea Pacific/Pago_Pago Pacific/Palau Pacific/Pitcairn Pacific/Ponape Pacific/Port_Moresby Pacific/Rarotonga Pacific/Saipan Pacific/Samoa Pacific/Tahiti Pacific/Tarawa Pacific/Tongatapu Pacific/Truk Pacific/Wake Pacific/Wallis Pacific/Yap Poland Portugal PRC PST PST8PDT ROC ROK Singapore Turkey US/Alaska US/Aleutian US/Arizona US/Central US/Eastern US/East-Indiana US/Hawaii US/Indiana-Starke US/Michigan US/Mountain US/Pacific US/Pacific-New US/Samoa UTC WET W-SU"
  TIMEZONE_CMD="cat /etc/sysconfig/clock | grep ZONE | cut -f2 -d '=' | sed 's/[\"]//g'"
# (30 Sep 2018 - (RayD) Updated the list of packages
  elif [ "$RELEASE" == "7.3" ] || [ "$RELEASE" == "7.4" ]; then
  # TODO: #STB-6
  IPTABLES_RESULT="iptables: Firewall is not running."
  # TODO: #STB-4
  IP6TABLES_RESULT="ip6tables: Firewall is not running."
  REQ_1_59_PACKAGES="zlib zlib.i686 binutils compat-db compat-libcap1 compat-libstdc++-33 compat-libstdc++-33.i686 device-mapper-multipath dos2unix elfutils-libelf elfutils-libelf-devel emacs fipscheck gcc gcc-c++ glibc glibc.i686 glibc-common glibc-devel glibc-devel.i686 hdparms initscripts iptraf kexec-tools ksh libXext libXi libXtst libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libsane-hpaio libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 make mtools nmap openmotif openssl openssl.i686 pax python-dmidecode redhat-lsb redhat-lsb-core.i686 screen sgpio strace sysstat unixODBC unixODBC-devel xinetd.x86_64 xorg-xll-server-utils xorg-x11-utils"
  ENTROPY="rngd -r /dev/urandom -o /dev/random -t 0.01"
  ENTROPY_EXTRAOPTIONS=" -r /dev/urandom -o /dev/random -b"  
  TIMEZONE_LIST="Africa/Abidjan Africa/Accra Africa/Addis_Ababa Africa/Algiers Africa/Asmara Africa/Asmera Africa/Bamako Africa/Bangui Africa/Banjul Africa/Bissau Africa/Blantyre Africa/Brazzaville Africa/Bujumbura Africa/Cairo Africa/Casablanca Africa/Ceuta Africa/Conakry Africa/Dakar Africa/Dar_es_Salaam Africa/Djibouti Africa/Douala Africa/El_Aaiun Africa/Freetown Africa/Gaborone Africa/Harare Africa/Johannesburg Africa/Kampala Africa/Khartoum Africa/Kigali Africa/Kinshasa Africa/Lagos Africa/Libreville Africa/Lome Africa/Luanda Africa/Lubumbashi Africa/Lusaka Africa/Malabo Africa/Maputo Africa/Maseru Africa/Mbabane Africa/Mogadishu Africa/Monrovia Africa/Nairobi Africa/Ndjamena Africa/Niamey Africa/Nouakchott Africa/Ouagadougou Africa/Porto-Novo Africa/Sao_Tome Africa/Timbuktu Africa/Tripoli Africa/Tunis Africa/Windhoek America/Adak America/Anchorage America/Anguilla America/Antigua America/Araguaina America/Argentina/Buenos_Aires America/Argentina/Catamarca America/Argentina/ComodRivadavia America/Argentina/Cordoba America/Argentina/Jujuy America/Argentina/La_Rioja America/Argentina/Mendoza America/Argentina/Rio_Gallegos America/Argentina/Salta America/Argentina/San_Juan America/Argentina/San_Luis America/Argentina/Tucuman America/Argentina/Ushuaia America/Aruba America/Asuncion America/Atikokan America/Atka America/Bahia America/Barbados America/Belem America/Belize America/Blanc-Sablon America/Boa_Vista America/Bogota America/Boise America/Buenos_Aires America/Cambridge_Bay America/Campo_Grande America/Cancun America/Caracas America/Catamarca America/Cayenne America/Cayman America/Chicago America/Chihuahua America/Coral_Harbour America/Cordoba America/Costa_Rica America/Cuiaba America/Curacao America/Danmarkshavn America/Dawson America/Dawson_Creek America/Denver America/Detroit America/Dominica America/Edmonton America/Eirunepe America/El_Salvador America/Ensenada America/Fort_Wayne America/Fortaleza America/Glace_Bay America/Godthab America/Goose_Bay America/Grand_Turk America/Grenada America/Guadeloupe America/Guatemala America/Guayaquil America/Guyana America/Halifax America/Havana America/Hermosillo America/Indiana/Indianapolis America/Indiana/Knox America/Indiana/Marengo America/Indiana/Petersburg America/Indiana/Tell_City America/Indiana/Vevay America/Indiana/Vincennes America/Indiana/Winamac America/Indianapolis America/Inuvik America/Iqaluit America/Jamaica America/Jujuy America/Juneau America/Kentucky/Louisville America/Kentucky/Monticello America/Knox_IN America/La_Paz America/Lima America/Los_Angeles America/Louisville America/Maceio America/Managua America/Manaus America/Marigot America/Martinique America/Mazatlan America/Mendoza America/Menominee America/Merida America/Mexico_City America/Miquelon America/Moncton America/Monterrey America/Montevideo America/Montreal America/Montserrat America/Nassau America/New_York America/Nipigon America/Nome America/Noronha America/North_Dakota/Center America/North_Dakota/New_Salem America/Panama America/Pangnirtung America/Paramaribo America/Phoenix America/Port_of_Spain America/Port-au-Prince America/Porto_Acre America/Porto_Velho America/Puerto_Rico America/Rainy_River America/Rankin_Inlet America/Recife America/Regina America/Resolute America/Rio_Branco America/Rosario America/Santiago America/Santo_Domingo America/Sao_Paulo America/Scoresbysund America/Shiprock America/St_Barthelemy America/St_Johns America/St_Kitts America/St_Lucia America/St_Thomas America/St_Vincent America/Swift_Current America/Tegucigalpa America/Thule America/Thunder_Bay America/Tijuana America/Toronto America/Tortola America/Vancouver America/Virgin America/Whitehorse America/Winnipeg America/Yakutat America/Yellowknife Antarctica/Casey Antarctica/Davis Antarctica/DumontDUrville Antarctica/Mawson Antarctica/McMurdo Antarctica/Palmer Antarctica/South_Pole Antarctica/Syowa Arctic/Longyearbyen Asia/Aden Asia/Almaty Asia/Amman Asia/Anadyr Asia/Aqtau Asia/Aqtobe Asia/Ashgabat Asia/Ashkhabad Asia/Baghdad Asia/Bahrain Asia/Baku Asia/Bangkok Asia/Beirut Asia/Bishkek Asia/Brunei Asia/Calcutta Asia/Choibalsan Asia/Chongqing Asia/Chungking Asia/Colombo Asia/Dacca Asia/Damascus Asia/Dhaka Asia/Dili Asia/Dubai Asia/Dushanbe Asia/Gaza Asia/Harbin Asia/Ho_Chi_Minh Asia/Hong_Kong Asia/Hovd Asia/Irkutsk Asia/Istanbul Asia/Jakarta Asia/Jayapura Asia/Jerusalem Asia/Kabul Asia/Kamchatka Asia/Karachi Asia/Kashgar Asia/Kathmandu Asia/Katmandu Asia/Kolkata Asia/Krasnoyarsk Asia/Kuala_Lumpur Asia/Kuching Asia/Kuwait Asia/Macao Asia/Macau Asia/Magadan Asia/Makassar Asia/Manila Asia/Muscat Asia/Nicosia Asia/Novosibirsk Asia/Omsk Asia/Oral Asia/Phnom_Penh Asia/Pontianak Asia/Pyongyang Asia/Qatar Asia/Qyzylorda Asia/Rangoon Asia/Riyadh Asia/Saigon Asia/Sakhalin Asia/Samarkand Asia/Seoul Asia/Shanghai Asia/Singapore Asia/Taipei Asia/Tashkent Asia/Tbilisi Asia/Tehran Asia/Tel_Aviv Asia/Thimbu Asia/Thimphu Asia/Tokyo Asia/Ujung_Pandang Asia/Ulaanbaatar Asia/Ulan_Bator Asia/Urumqi Asia/Vientiane Asia/Vladivostok Asia/Yakutsk Asia/Yekaterinburg Asia/Yerevan Atlantic/Azores Atlantic/Bermuda Atlantic/Canary Atlantic/Cape_Verde Atlantic/Faeroe Atlantic/Faroe Atlantic/Jan_Mayen Atlantic/Madeira Atlantic/Reykjavik Atlantic/South_Georgia Atlantic/St_Helena Atlantic/Stanley Australia/ACT Australia/Adelaide Australia/Brisbane Australia/Broken_Hill Australia/Canberra Australia/Currie Australia/Darwin Australia/Eucla Australia/Hobart Australia/LHI Australia/Lindeman Australia/Lord_Howe Australia/Melbourne Australia/North Australia/NSW Australia/Perth Australia/Queensland Australia/South Australia/Sydney Australia/Tasmania Australia/Victoria Australia/West Australia/Yancowinna Brazil/Acre Brazil/DeNoronha Brazil/East Brazil/West Canada/Atlantic Canada/Central Canada/Eastern Canada/East-Saskatchewan Canada/Mountain Canada/Newfoundland Canada/Pacific Canada/Saskatchewan Canada/Yukon CET Chile/Continental Chile/EasterIsland CST CST6CDT Cuba EET Egypt Eire EST EST5EDT Etc/GMT Etc/GMT+0 Etc/GMT+1 Etc/GMT+10 Etc/GMT+11 Etc/GMT+12 Etc/GMT+2 Etc/GMT+3 Etc/GMT+4 Etc/GMT+5 Etc/GMT+6 Etc/GMT+7 Etc/GMT+8 Etc/GMT+9 Etc/GMT0 Etc/GMT-0 Etc/GMT-1 Etc/GMT-10 Etc/GMT-11 Etc/GMT-12 Etc/GMT-13 Etc/GMT-14 Etc/GMT-2 Etc/GMT-3 Etc/GMT-4 Etc/GMT-5 Etc/GMT-6 Etc/GMT-7 Etc/GMT-8 Etc/GMT-9 Etc/Greenwich Europe/Amsterdam Europe/Andorra Europe/Athens Europe/Belfast Europe/Belgrade Europe/Berlin Europe/Bratislava Europe/Brussels Europe/Bucharest Europe/Budapest Europe/Chisinau Europe/Copenhagen Europe/Dublin Europe/Gibraltar Europe/Guernsey Europe/Helsinki Europe/Isle_of_Man Europe/Istanbul Europe/Jersey Europe/Kaliningrad Europe/Kiev Europe/Lisbon Europe/Ljubljana Europe/London Europe/Luxembourg Europe/Madrid Europe/Malta Europe/Mariehamn Europe/Minsk Europe/Monaco Europe/Moscow Europe/Nicosia Europe/Oslo Europe/Paris Europe/Prague Europe/Riga Europe/Rome Europe/Samara Europe/San_Marino Europe/Sarajevo Europe/Simferopol Europe/Skopje Europe/Sofia Europe/Stockholm Europe/Tallinn Europe/Tirane Europe/Tiraspol Europe/Uzhgorod Europe/Vaduz Europe/Vatican Europe/Vienna Europe/Vilnius Europe/Volgograd Europe/Warsaw Europe/Zagreb Europe/Zaporozhye Europe/Zurich GB GB-Eire GMT GMT+0 GMT0 GMT-0 Greenwich Hongkong HST Iceland Indian/Antananarivo Indian/Chagos Indian/Christmas Indian/Cocos Indian/Comoro Indian/Kerguelen Indian/Mahe Indian/Maldives Indian/Mauritius Indian/Mayotte Indian/Reunion Iran Israel Jamaica Japan Kwajalein Libya MET Mexico/BajaNorte Mexico/BajaSur Mexico/General MST MST7MDT Navajo NZ NZ-CHAT Pacific/Apia Pacific/Auckland Pacific/Chatham Pacific/Easter Pacific/Efate Pacific/Enderbury Pacific/Fakaofo Pacific/Fiji Pacific/Funafuti Pacific/Galapagos Pacific/Gambier Pacific/Guadalcanal Pacific/Guam Pacific/Honolulu Pacific/Johnston Pacific/Kiritimati Pacific/Kosrae Pacific/Kwajalein Pacific/Majuro Pacific/Marquesas Pacific/Midway Pacific/Nauru Pacific/Niue Pacific/Norfolk Pacific/Noumea Pacific/Pago_Pago Pacific/Palau Pacific/Pitcairn Pacific/Ponape Pacific/Port_Moresby Pacific/Rarotonga Pacific/Saipan Pacific/Samoa Pacific/Tahiti Pacific/Tarawa Pacific/Tongatapu Pacific/Truk Pacific/Wake Pacific/Wallis Pacific/Yap Poland Portugal PRC PST PST8PDT ROC ROK Singapore Turkey US/Alaska US/Aleutian US/Arizona US/Central US/Eastern US/East-Indiana US/Hawaii US/Indiana-Starke US/Michigan US/Mountain US/Pacific US/Pacific-New US/Samoa UTC WET W-SU"
  TIMEZONE_CMD="timedatectl | grep 'Time zone'"
else
  echo '[Warning]: RHEL Version not matched, tests will be against 7.4.'
  RELEASE="7.4"
  IPTABLES_RESULT="iptables: Firewall is not running."
  IP6TABLES_RESULT="ip6tables: Firewall is not running."
  REQ_1_59_PACKAGES="zlib zlib.i686 binutils compat-db compat-libcap1 compat-libstdc++-33 compat-libstdc++-33.i686 device-mapper-multipath dos2unix elfutils-libelf elfutils-libelf-devel emacs fipscheck gcc gcc-c++ glibc glibc.i686 glibc-common glibc-devel glibc-devel.i686 hdparms initscripts iptraf kexec-tools ksh libXext libXi libXtst libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libsane-hpaio libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 make mtools nmap openmotif openssl openssl.i686 pax python-dmidecode redhat-lsb redhat-lsb-core.i686 screen sgpio strace sysstat unixODBC unixODBC-devel xinetd.x86_64 xorg-xll-server-utils xorg-x11-utils"
  ENTROPY="rngd -r /dev/urandom -o /dev/random -t 0.01"
  ENTROPY_EXTRAOPTIONS="-i -r /dev/urandom -o /dev/random -b"  
  TIMEZONE_LIST="Africa/Abidjan Africa/Accra Africa/Addis_Ababa Africa/Algiers Africa/Asmara Africa/Asmera Africa/Bamako Africa/Bangui Africa/Banjul Africa/Bissau Africa/Blantyre Africa/Brazzaville Africa/Bujumbura Africa/Cairo Africa/Casablanca Africa/Ceuta Africa/Conakry Africa/Dakar Africa/Dar_es_Salaam Africa/Djibouti Africa/Douala Africa/El_Aaiun Africa/Freetown Africa/Gaborone Africa/Harare Africa/Johannesburg Africa/Kampala Africa/Khartoum Africa/Kigali Africa/Kinshasa Africa/Lagos Africa/Libreville Africa/Lome Africa/Luanda Africa/Lubumbashi Africa/Lusaka Africa/Malabo Africa/Maputo Africa/Maseru Africa/Mbabane Africa/Mogadishu Africa/Monrovia Africa/Nairobi Africa/Ndjamena Africa/Niamey Africa/Nouakchott Africa/Ouagadougou Africa/Porto-Novo Africa/Sao_Tome Africa/Timbuktu Africa/Tripoli Africa/Tunis Africa/Windhoek America/Adak America/Anchorage America/Anguilla America/Antigua America/Araguaina America/Argentina/Buenos_Aires America/Argentina/Catamarca America/Argentina/ComodRivadavia America/Argentina/Cordoba America/Argentina/Jujuy America/Argentina/La_Rioja America/Argentina/Mendoza America/Argentina/Rio_Gallegos America/Argentina/Salta America/Argentina/San_Juan America/Argentina/San_Luis America/Argentina/Tucuman America/Argentina/Ushuaia America/Aruba America/Asuncion America/Atikokan America/Atka America/Bahia America/Barbados America/Belem America/Belize America/Blanc-Sablon America/Boa_Vista America/Bogota America/Boise America/Buenos_Aires America/Cambridge_Bay America/Campo_Grande America/Cancun America/Caracas America/Catamarca America/Cayenne America/Cayman America/Chicago America/Chihuahua America/Coral_Harbour America/Cordoba America/Costa_Rica America/Cuiaba America/Curacao America/Danmarkshavn America/Dawson America/Dawson_Creek America/Denver America/Detroit America/Dominica America/Edmonton America/Eirunepe America/El_Salvador America/Ensenada America/Fort_Wayne America/Fortaleza America/Glace_Bay America/Godthab America/Goose_Bay America/Grand_Turk America/Grenada America/Guadeloupe America/Guatemala America/Guayaquil America/Guyana America/Halifax America/Havana America/Hermosillo America/Indiana/Indianapolis America/Indiana/Knox America/Indiana/Marengo America/Indiana/Petersburg America/Indiana/Tell_City America/Indiana/Vevay America/Indiana/Vincennes America/Indiana/Winamac America/Indianapolis America/Inuvik America/Iqaluit America/Jamaica America/Jujuy America/Juneau America/Kentucky/Louisville America/Kentucky/Monticello America/Knox_IN America/La_Paz America/Lima America/Los_Angeles America/Louisville America/Maceio America/Managua America/Manaus America/Marigot America/Martinique America/Mazatlan America/Mendoza America/Menominee America/Merida America/Mexico_City America/Miquelon America/Moncton America/Monterrey America/Montevideo America/Montreal America/Montserrat America/Nassau America/New_York America/Nipigon America/Nome America/Noronha America/North_Dakota/Center America/North_Dakota/New_Salem America/Panama America/Pangnirtung America/Paramaribo America/Phoenix America/Port_of_Spain America/Port-au-Prince America/Porto_Acre America/Porto_Velho America/Puerto_Rico America/Rainy_River America/Rankin_Inlet America/Recife America/Regina America/Resolute America/Rio_Branco America/Rosario America/Santiago America/Santo_Domingo America/Sao_Paulo America/Scoresbysund America/Shiprock America/St_Barthelemy America/St_Johns America/St_Kitts America/St_Lucia America/St_Thomas America/St_Vincent America/Swift_Current America/Tegucigalpa America/Thule America/Thunder_Bay America/Tijuana America/Toronto America/Tortola America/Vancouver America/Virgin America/Whitehorse America/Winnipeg America/Yakutat America/Yellowknife Antarctica/Casey Antarctica/Davis Antarctica/DumontDUrville Antarctica/Mawson Antarctica/McMurdo Antarctica/Palmer Antarctica/South_Pole Antarctica/Syowa Arctic/Longyearbyen Asia/Aden Asia/Almaty Asia/Amman Asia/Anadyr Asia/Aqtau Asia/Aqtobe Asia/Ashgabat Asia/Ashkhabad Asia/Baghdad Asia/Bahrain Asia/Baku Asia/Bangkok Asia/Beirut Asia/Bishkek Asia/Brunei Asia/Calcutta Asia/Choibalsan Asia/Chongqing Asia/Chungking Asia/Colombo Asia/Dacca Asia/Damascus Asia/Dhaka Asia/Dili Asia/Dubai Asia/Dushanbe Asia/Gaza Asia/Harbin Asia/Ho_Chi_Minh Asia/Hong_Kong Asia/Hovd Asia/Irkutsk Asia/Istanbul Asia/Jakarta Asia/Jayapura Asia/Jerusalem Asia/Kabul Asia/Kamchatka Asia/Karachi Asia/Kashgar Asia/Kathmandu Asia/Katmandu Asia/Kolkata Asia/Krasnoyarsk Asia/Kuala_Lumpur Asia/Kuching Asia/Kuwait Asia/Macao Asia/Macau Asia/Magadan Asia/Makassar Asia/Manila Asia/Muscat Asia/Nicosia Asia/Novosibirsk Asia/Omsk Asia/Oral Asia/Phnom_Penh Asia/Pontianak Asia/Pyongyang Asia/Qatar Asia/Qyzylorda Asia/Rangoon Asia/Riyadh Asia/Saigon Asia/Sakhalin Asia/Samarkand Asia/Seoul Asia/Shanghai Asia/Singapore Asia/Taipei Asia/Tashkent Asia/Tbilisi Asia/Tehran Asia/Tel_Aviv Asia/Thimbu Asia/Thimphu Asia/Tokyo Asia/Ujung_Pandang Asia/Ulaanbaatar Asia/Ulan_Bator Asia/Urumqi Asia/Vientiane Asia/Vladivostok Asia/Yakutsk Asia/Yekaterinburg Asia/Yerevan Atlantic/Azores Atlantic/Bermuda Atlantic/Canary Atlantic/Cape_Verde Atlantic/Faeroe Atlantic/Faroe Atlantic/Jan_Mayen Atlantic/Madeira Atlantic/Reykjavik Atlantic/South_Georgia Atlantic/St_Helena Atlantic/Stanley Australia/ACT Australia/Adelaide Australia/Brisbane Australia/Broken_Hill Australia/Canberra Australia/Currie Australia/Darwin Australia/Eucla Australia/Hobart Australia/LHI Australia/Lindeman Australia/Lord_Howe Australia/Melbourne Australia/North Australia/NSW Australia/Perth Australia/Queensland Australia/South Australia/Sydney Australia/Tasmania Australia/Victoria Australia/West Australia/Yancowinna Brazil/Acre Brazil/DeNoronha Brazil/East Brazil/West Canada/Atlantic Canada/Central Canada/Eastern Canada/East-Saskatchewan Canada/Mountain Canada/Newfoundland Canada/Pacific Canada/Saskatchewan Canada/Yukon CET Chile/Continental Chile/EasterIsland CST CST6CDT Cuba EET Egypt Eire EST EST5EDT Etc/GMT Etc/GMT+0 Etc/GMT+1 Etc/GMT+10 Etc/GMT+11 Etc/GMT+12 Etc/GMT+2 Etc/GMT+3 Etc/GMT+4 Etc/GMT+5 Etc/GMT+6 Etc/GMT+7 Etc/GMT+8 Etc/GMT+9 Etc/GMT0 Etc/GMT-0 Etc/GMT-1 Etc/GMT-10 Etc/GMT-11 Etc/GMT-12 Etc/GMT-13 Etc/GMT-14 Etc/GMT-2 Etc/GMT-3 Etc/GMT-4 Etc/GMT-5 Etc/GMT-6 Etc/GMT-7 Etc/GMT-8 Etc/GMT-9 Etc/Greenwich Europe/Amsterdam Europe/Andorra Europe/Athens Europe/Belfast Europe/Belgrade Europe/Berlin Europe/Bratislava Europe/Brussels Europe/Bucharest Europe/Budapest Europe/Chisinau Europe/Copenhagen Europe/Dublin Europe/Gibraltar Europe/Guernsey Europe/Helsinki Europe/Isle_of_Man Europe/Istanbul Europe/Jersey Europe/Kaliningrad Europe/Kiev Europe/Lisbon Europe/Ljubljana Europe/London Europe/Luxembourg Europe/Madrid Europe/Malta Europe/Mariehamn Europe/Minsk Europe/Monaco Europe/Moscow Europe/Nicosia Europe/Oslo Europe/Paris Europe/Prague Europe/Riga Europe/Rome Europe/Samara Europe/San_Marino Europe/Sarajevo Europe/Simferopol Europe/Skopje Europe/Sofia Europe/Stockholm Europe/Tallinn Europe/Tirane Europe/Tiraspol Europe/Uzhgorod Europe/Vaduz Europe/Vatican Europe/Vienna Europe/Vilnius Europe/Volgograd Europe/Warsaw Europe/Zagreb Europe/Zaporozhye Europe/Zurich GB GB-Eire GMT GMT+0 GMT0 GMT-0 Greenwich Hongkong HST Iceland Indian/Antananarivo Indian/Chagos Indian/Christmas Indian/Cocos Indian/Comoro Indian/Kerguelen Indian/Mahe Indian/Maldives Indian/Mauritius Indian/Mayotte Indian/Reunion Iran Israel Jamaica Japan Kwajalein Libya MET Mexico/BajaNorte Mexico/BajaSur Mexico/General MST MST7MDT Navajo NZ NZ-CHAT Pacific/Apia Pacific/Auckland Pacific/Chatham Pacific/Easter Pacific/Efate Pacific/Enderbury Pacific/Fakaofo Pacific/Fiji Pacific/Funafuti Pacific/Galapagos Pacific/Gambier Pacific/Guadalcanal Pacific/Guam Pacific/Honolulu Pacific/Johnston Pacific/Kiritimati Pacific/Kosrae Pacific/Kwajalein Pacific/Majuro Pacific/Marquesas Pacific/Midway Pacific/Nauru Pacific/Niue Pacific/Norfolk Pacific/Noumea Pacific/Pago_Pago Pacific/Palau Pacific/Pitcairn Pacific/Ponape Pacific/Port_Moresby Pacific/Rarotonga Pacific/Saipan Pacific/Samoa Pacific/Tahiti Pacific/Tarawa Pacific/Tongatapu Pacific/Truk Pacific/Wake Pacific/Wallis Pacific/Yap Poland Portugal PRC PST PST8PDT ROC ROK Singapore Turkey US/Alaska US/Aleutian US/Arizona US/Central US/Eastern US/East-Indiana US/Hawaii US/Indiana-Starke US/Michigan US/Mountain US/Pacific US/Pacific-New US/Samoa UTC WET W-SU"
  TIMEZONE_CMD="timedatectl | grep 'Time zone'"
fi
#####

# (19 Sep 2018 - (RayD) Test removed to avoid conflict with Engineering Precheck
##
##  REQ 1.2 - The “Trellis Directory Permissions” are configured correctly
##
#echo '########################################################################################\n\t[REQ 1.2] Trellis Directory Permissions\n########################################################################################'
#ls -ld /u0*
#echo -n "[REQ 1.2]   Checking permissions and ownership on /u01-5..." > `tty`
#echo "[REQ 1.2]   Checking permissions and ownership on /u01-5..."
#wrong=0
#for i in 1 2 3 5
#do
#    properties=`ls -ld /u0$i`
#    permission=`echo $properties | awk '{print $1}' | cut -f1 -d"."`
#    ownership=`echo $properties | awk '{print $3}'`
#    group_ownership=`echo $properties | awk '{print $4}'`
#
#    if [ $TRELLIS_NEW_INSTALL = "Yes" ]; then
#        EXPECTED_PERMISSION="drwxrwxr-x"
#    else
#        if [ $i == 5 ]; then
#            EXPECTED_PERMISSION="drwxrwxr-x"
#        else
#            EXPECTED_PERMISSION="drwxrwx---"
#        fi	
#    fi
#
#    if [ "$permission" != "$EXPECTED_PERMISSION" ]
#    then
#        wrong=1
#        echo "Permissions on /u0$i are wrong"
#    fi
#    if [ "$ownership" != "oracle" ]
#    then
#        wrong=1
#        echo "Ownership on /u0$i is wrong"
#    fi
#    if [ "$group_ownership" != "oinstall" ]
#    then
#        wrong=1
#        echo "Group ownership on /u0$i is wrong"
#    fi
#done
#if [ "$wrong" == 0 ]
#then
#    echo "    ==>Permissions or ownership on /u01-5 are correct. OK"
#    echo -e "\t${GREEN}Passed${NONE}" > `tty`
#else
#    echo "    ==>Automatic check failed!"
#    echo -e "\t${RED}Failed${NONE}" > `tty`
#fi
#echo '****************************************************************************'
#echo '****************************************************************************'
#####


#
#  REQ 1.51 - The “Oracle User Info” is configured correctly
#
echo '*****************************Oracle User Info***********************'
echo '******Confirm line exists: oracle:x:500:500::/home/oracle:/bin/bash*'
echo -n "[REQ 1.51]  Checking Oracle User is configured correctly..." > `tty`
echo "[REQ 1.51]  Checking Oracle User is configured correctly..." 

wrong=0

echo "Checking oracle user"
echo
cat /etc/passwd | grep oracle
echo
USER_ORACLE=`cat /etc/passwd | grep oracle | grep /home/oracle:/bin/bash | wc -l`
if [ "$USER_ORACLE" == 1 ]
then
    echo "    ==>User Oracle User Info is configured correctly in /etc/passwd. OK."
else
    wrong=1
fi

if [ "$wrong" == 0 ]
then
    echo "    ==>Group info in /etc/passwd are correct. OK"
    echo -e "\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo "If you want to do it manually you will need to run 'useradd -g oinstall -G dba ip <password> oracle' from the command line"    
    echo -e "\t${RED}Failed${NONE}" > `tty`
fi

echo '****************************************************************************'
echo '****************************************************************************'
#####

#
#  REQ 1.52 - The “Trellis Group Info” is configured correctly
#
echo '****************************Trellis Groups Info*********************'
echo '*******************Confirm line exists: dba:x:501:oracle************'
echo '********************Confirm line exists: oinstall:x:500:************'
echo -n "[REQ 1.52]  Checking Trellis Group Info in /etc/group..." > `tty`
echo "[REQ 1.52]  Checking Trellis Group Info in /etc/group..."

wrong=0

echo "Checking group info for dba"
echo
cat /etc/group | egrep "dba|oinstall"
echo
GROUP_dba=`cat /etc/group | grep dba | grep :oracle | wc -l`
if [ "$GROUP_dba" == 1 ]
then
    echo "    ==>Group dba is configured correctly in /etc/group. OK."
else
    wrong=1
    echo "If you want to do it manually you will need to run 'groupadd dba' from the command line"
fi
echo
echo "Checking group info for oinstall"
GROUP_oinstall=`cat /etc/group | grep oinstall | wc -l`
if [ "$GROUP_oinstall" == 1 ]
then
    echo "    ==>Group oinstall is configured correctly in /etc/group. OK."
else
    wrong=1
    echo "If you want to do it manually you will need to run 'groupadd oinstall' from the command line"
fi

if [ "$wrong" == 0 ]
then
    echo "    ==>Group info in /etc/group are correct. OK"
    echo -e "\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo -e "\t${RED}Failed${NONE}" > `tty`
fi

echo '****************************************************************************'
echo '****************************************************************************'
#####

#
#  REQ 1.53 - The “Trellis Environment Variables” are configured correctly
#
echo '*********************Trellis Environment Variables******************'
echo '**************The output should contain the below 3 lines***********'
echo '***********************PATH should contain /sbin/ ******************'
echo '***********************MW_HOME=/u01/fm/11.1.0.7/********************'
echo '***************ORACLE_HOME=/u01/app/oracle/product/12.1.0.2***********'
echo '***************************ORACLE_SID=orcl**************************'
echo
su - oracle -c 'echo PATH=${PATH}'
su - oracle -c 'echo MW_HOME=${MW_HOME}'
su - oracle -c 'echo ORACLE_HOME=${ORACLE_HOME}'
su - oracle -c 'echo ORACLE_SID=${ORACLE_SID}'
echo -n "[REQ 1.53]  Checking oracle user environment variables" > `tty`
echo "[REQ 1.53]  Checking oracle user environment variables" 
echo
wrong=0

echo "Checking oracle user environment variables: PATH..."
ORA_PATH=`su - oracle -c 'echo ${PATH}' | grep -c "[:|=]/sbin"`
if [ "$ORA_PATH"  == "1" ]
then
    echo "  Oracle env PATH is configured correctly. OK."
else
    wrong=1
    echo "  Oracle env PATH is NOT configured correctly"    
fi

echo "Checking oracle user environment variables: MW_HOME..."
ORA_MW_HOME=`su - oracle -c 'echo ${MW_HOME}'`
if [ "$ORA_MW_HOME"  == "/u01/fm/11.1.1.7/" ]
then
    echo "  Oracle env MW_HOME is configured correctly. OK."
else
    wrong=1
    echo "  Oracle env MW_HOME is NOT configured correctly"    
fi

echo "Checking oracle user environment variables: ORACLE_HOME..."
ORA_ORACLE_HOME=`su - oracle -c 'echo ${ORACLE_HOME}'`
# (9-27-18 RayD) Change ORACLE_HOME path from 11.2.0 to 12.1.0.2
if [ "$ORA_ORACLE_HOME"  == "/u01/app/oracle/product/12.1.0.2" ]
then
    echo "    Oracle env ORACLE_HOME is configured correctly. OK."
else
    wrong=1
    echo "  Oracle env ORACLE_HOME is NOT configured correctly"    
fi

echo "Checking oracle user environment variables: ORACLE_SID..."
ORA_ORACLE_SID=`su - oracle -c 'echo ${ORACLE_SID}'`
if [ "$ORA_ORACLE_SID"  == "orcl" ]
then
    echo "    Oracle env ORACLE_SID is configured correctly. OK."
else
    wrong=1
    echo "    Oracle env ORACLE_SID is NOT configured correctly"
fi

if [ "$wrong" == 0 ]
then
    echo "    ==>Trellis Environment Variables are correct. OK"
    echo -e "\t\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo -e "\t\t${RED}Failed${NONE}" > `tty`
fi
echo
echo '****************************************************************************'
echo '****************************************************************************'
#####


#
#  REQ 1.54 - The oraInst Content & Permissions are configured correctly
#
echo '******************/etc/oraInst.loc Content & Permissions************'
echo '*********************The output should contain 3 lines**************'
echo '********************inventory_loc=/u01/app/oraInventory*************'
echo '****************************inst_group=oinstall*********************'
echo '*****3rd line should show -rw-r--r-- permissions and root ownership*'
echo -n "[REQ 1.54]  Checking /etc/oraInst.loc..." > `tty`
echo "[REQ 1.54]  Checking /etc/oraInst.loc..." 
cat /etc/oraInst.loc
ls -ld /etc/oraInst.loc
wrong=0
DIFF_counter=`diff $CFG_OUTPUT_BUNDLE_FOLDER/oraInst.loc /etc/oraInst.loc | wc -l`
if [ "$DIFF_counter" == 0 ]
then
    echo "    ==>Content of /etc/oraInst.loc is good. OK."
else
    wrong=1
    echo "    ==>Automatic check for /etc/oraInst.loc failed!"
fi
properties=`ls -ld /etc/oraInst.loc`
permission=`echo $properties | awk '{print $1}' | cut -f1 -d"."`
ownership=`echo $properties | awk '{print $3}'`
if [ "$permission" != "-rw-r--r--" ]
then
    wrong=1
    echo "Permissions on /etc/oraInst.loc are wrong"
fi
if [ "$ownership" != "root" ]
then
    wrong=1
    echo "Ownership on /etc/oraInst.loc is wrong"
fi
if [ "$wrong" == 0 ]
then
    echo "    ==>Content/permissions/ownership on /etc/oraInst.loc are correct. OK"
    echo -e "\t\t\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo -e "\t\t\t${RED}Failed${NONE}" > `tty`
fi
echo '****************************************************************************'
echo '****************************************************************************'
#####

#
#  REQ 1.55 - The oratab Content & Permissions are configured correctly.
#
echo '***************************oratab Permissions***********************'
echo '***Should show -rw-rw-r-- permissions and oracle oinstall ownership*'
ls -ld /etc/oratab
echo -n "[REQ 1.55]  Checking /etc/oratab..." > `tty`
echo "[REQ 1.55]  Checking /etc/oratab..." 
wrong=0
properties=`ls -ld /etc/oratab`
permission=`echo $properties | awk '{print $1}' | cut -f1 -d"."`
ownership=`echo $properties | awk '{print $3}'`
group_ownership=`echo $properties | awk '{print $4}'`
if [ "$permission" != "-rw-rw-r--" ]
then
    wrong=1
    echo "Permissions on /etc/oratab are wrong"
fi
if [ "$ownership" != "oracle" ]
then
    wrong=1
    echo "Ownership on /etc/oratab is wrong"
fi
if [ "$group_ownership" != "oinstall" ]
then
    wrong=1
    echo "Group ownership on /etc/oratab is wrong"
fi
if [ "$wrong" == 0 ]
then
    echo "    ==>Permissions or ownership on /etc/oratab are correct. OK"
    echo -e "\t\t\t\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo -e "\t\t\t\t${RED}Failed${NONE}" > `tty`

fi
echo '****************************************************************************'
echo '****************************************************************************'
#####

# (19 Sep 2018 - (RayD) Test removed to avoid conflict with Engineering Precheck
##
##  REQ 1.56 - Confirm Network Manager Disabled
##
#echo '******************************NetworkManager Info**************************'
#echo '***********************Confirm NetworkManager service = disabled*******************'
#echo -n "[REQ 1.56]  Checking NetworkManager..." > `tty`
#echo "[REQ 1.56]  Checking NetworkManager..." 
#
###  Checking to see if NetworkManager is off. Trellis can run with it
###  but since we are now turning off X anyway, it is far easier to deal
###  with networking without it.
#echo ""
#echo "---CHECKING FOR NETWORK MANAGER---"
#NETMAN=`service NetworkManager status`
#NETMAN_STAT=$?
#if [ "$NETMAN_STAT" -eq "0" ]; then
#    echo "    ==>Automatic check failed!"
#    echo "if you want to do it manually you will need to run 'service NetworkManager stop && chkconfig NetworkManager off' on the command line" 
#    echo -e "\t\t\t\t${RED}Failed${NONE}" > `tty`
#else
#  echo "    ==>NetworkManager service is not running. OK."
#  echo -e "\t\t\t\t${GREEN}Passed${NONE}" > `tty`
#fi
######

# (19 Sep 2018 - (RayD) Test removed to avoid conflict with Engineering Precheck
##
##  REQ 1.57 - The nodemanager content and permissions are configured correctly
##
#echo '**/etc/xinetd.d/nodemanager Content, Permissions and File Integrity*'
#echo '*****Content must be manually reviewed by PS and/or Engineering*****'
#echo -n "[REQ 1.57]  Checking /etc/xinetd.d/nodemanager..." > `tty`
#echo "[REQ 1.57]  Checking /etc/xinetd.d/nodemanager..." 
#cat /etc/xinetd.d/nodemanager 
#ls -ld /etc/xinetd.d/nodemanager
#file /etc/xinetd.d/nodemanager
#echo
#
#grep -v "#" /etc/xinetd.d/nodemanager > $CFG_OUTPUT_BUNDLE_FOLDER/nodemanager.sys
#grep -v "#" $CFG_OUTPUT_BUNDLE_FOLDER/nodemanager > $CFG_OUTPUT_BUNDLE_FOLDER/nodemanager.good
#DIFF_counter=`diff -w $CFG_OUTPUT_BUNDLE_FOLDER/nodemanager.sys $CFG_OUTPUT_BUNDLE_FOLDER/nodemanager.good | wc -l`
#
#if [ "$DIFF_counter" == 0 ]
#then
#    echo "    ==>/etc/xinetd.d/nodemanager is good. OK."
#    echo -e "\t\t${GREEN}Passed${NONE}" > `tty`
#else
#    echo "    ==>Automatic check failed!"
#    echo "       You could consider replacing /etc/xinetd.d/nodemanager with $CFG_OUTPUT_BUNDLE_FOLDER/nodemanager"
#    echo -e "\t\t${RED}Failed${NONE}" > `tty`
#fi
#echo '****************************************************************************'
#echo '****************************************************************************'
#####

# (19 Sep 2018 - (RayD) Test removed to avoid conflict with Engineering Precheck
##
##  REQ 1.58 - The Sudoers Content is configured correctly
##
#echo '***************************Sudoers Content**************************'
#echo '*****Content must be manually reviewed by PS and/or Engineering*****'
#echo -n "[REQ 1.58]  Checking sudoers..." > `tty`
#echo "[REQ 1.58]  Checking sudoers..." 
#
##
## Test Specific Configuration
##
#REQ_1_58_SUDOERS_ENTRIES_NOCR=`runuser -l oracle -c 'sudo -l' | grep "(root)"`
#
#if [ -e "/etc/sudoers.d/trellis" ] && [ -s "/etc/sudoers.d/trellis" ]; then
#	REQ_1_58_SUDOERS="/etc/sudoers.d/trellis"
#else
#	REQ_1_58_SUDOERS="/etc/sudoers"
#fi
#######
#
#REQ_1_58_SUDOERS_ENTRIES=`cat ${REQ_1_58_SUDOERS} | egrep "oracle|ORACLE" | wc -l`
#if [ $REQ_1_58_SUDOERS_ENTRIES == 7 ]; then
#    #If the file only has 7 oracle entries in it, just show these
#    cat $REQ_1_58_SUDOERS | egrep "oracle|ORACLE"
#else
#    #Otherwise list out the whole file 0011(omitting comments)
#    cat $REQ_1_58_SUDOERS | egrep "Defaults|#" -v 
#fi
#file $REQ_1_58_SUDOERS
#echo
#wrong=0
#REQ_1_58_SUDOERS_ENTRIES=`runuser -l oracle -c 'sudo -l' | grep "(root)" | wc -l`
#
#if [ -z "$REQ_1_58_SUDOERS_ENTRIES_NOCR" ]; then
#    #If there was no permission to run the sudo command as oracle do a direct compare of the file
#    echo There was no permission to run the sudo command as oracle so a direct compare is performed instead
#    echo
#    grep oracle /etc/sudoers | egrep "oracle|ORACLE" > $CFG_OUTPUT_BUNDLE_FOLDER/sudoers.sys
#	grep oracle /etc/sudoers.d/trellis | egrep "oracle|ORACLE" > $CFG_OUTPUT_BUNDLE_FOLDER/sudoers.d-trellis.sys
#    grep oracle $CFG_OUTPUT_BUNDLE_FOLDER/sudoers | egrep "oracle|ORACLE" > $CFG_OUTPUT_BUNDLE_FOLDER/sudoers.good
#	grep oracle $CFG_OUTPUT_BUNDLE_FOLDER/sudoers | egrep "oracle|ORACLE" > $CFG_OUTPUT_BUNDLE_FOLDER/sudoers.d-trellis.good
#
#    DIFF_counter=`diff $CFG_OUTPUT_BUNDLE_FOLDER/sudoers.good $CFG_OUTPUT_BUNDLE_FOLDER/sudoers.sys -w | wc -l`
#    if [ "$DIFF_counter" == 0 ]
#    then
#        #All matches
#        wrong=0
#    else
#        #They did not match
#        wrong=1
#    fi
#else
#    if [ $REQ_1_58_SUDOERS_ENTRIES -ge 7 ]; then
#        echo 
#        echo "----Sudoers List----"
#		echo "$REQ_1_58_SUDOERS_ENTRIES_NOCR"	
#		echo
#	
#        #Otherwise, check the permissions individually
#        SUDOERS_CHECK_PREFIX="(root) NOPASSWD:"
#        
#        #Build Sudoers List
#        SUDOERS_LIST="/etc/init.d/trellis"
#        SUDOERS_LIST="$SUDOERS_LIST /u03/root/disable_escalation.sh"
#        SUDOERS_LIST="$SUDOERS_LIST /u03/root/enable_nodemanager.sh"
#        SUDOERS_LIST="$SUDOERS_LIST /u03/root/ohs_enable_chroot.sh"
#        SUDOERS_LIST="$SUDOERS_LIST /u03/root/postinstall_env_setup.sh"
#        SUDOERS_LIST="$SUDOERS_LIST /u03/root/preinstall_env_setup.sh"  
#        SUDOERS_LIST="$SUDOERS_LIST /u03/root/sli_install.bin"
#
#        for i in $SUDOERS_LIST
#        do
#          SUDOERS_CHECK_FILE=$i
#          echo "Checking $i sudoer entry"
#        
#          if [ `echo "$REQ_1_58_SUDOERS_ENTRIES_NOCR" | grep "$SUDOERS_CHECK_PREFIX" | grep "$SUDOERS_CHECK_FILE" | wc -l` == 1 ]
#          then
#              echo " - Permissions on $SUDOERS_CHECK_FILE are OK"
#          else
#              wrong=1
#              echo " - Permissions on $SUDOERS_CHECK_FILE are missing or incorrect"    
#          fi		
#        done
#    else
#        wrong=1
#        echo "Incorrect number of expected sudoer entries, engineering require this to be in a specific format for installation"        
#        echo "NOTE: Sudoer aliases are not currently supported, if these are to be used, it must be changed AFTER installation"        
#    fi
#fi
#
##
##  Output Test Results
##
#echo
#if [ $wrong == 0 ]
#then
#    echo "    ==>/etc/sudoers settings are correct. OK"
#    echo -e "\t\t\t\t\t${GREEN}Passed${NONE}" > `tty`
#else
#    echo "    ==>Automatic check failed!"
#    echo "       You could consider appending /etc/sudoers with the contents of $CFG_OUTPUT_BUNDLE_FOLDER/sudoers"		
#    echo -e "\t\t\t\t\t${RED}Failed${NONE}" > `tty`
#fi
#
#echo '****************************************************************************'
#echo '****************************************************************************'
#####

#
#  REQ 1.59 - All required Trellis Packages are installed
#
echo '***********************Required Trellis Packages********************'
echo -n "[REQ 1.59]  Checking installed packages..." > `tty`
echo "[REQ 1.59]  Checking installed packages..." 
TMP_ERROR_COUNT=0
CMD_RPM_SEARCH=`rpm -q $i`
REQ_1_59_PACKAGES_REQUIRE=""

for i in $REQ_1_59_PACKAGES; do    
    if [ "$CMD_RPM_SEARCH" != "package $i is not installed" ]; then
        echo -e "\tValidate package $i\t- PASS"
    else
        echo -e "\tValidate package $i\t- FAIL"
		$REQ_1_59_PACKAGES_REQUIRE="${REQ_1_59_PACKAGES_REQUIRE} ${i}"
        TMP_ERROR_COUNT=`expr $TMP_ERROR_COUNT + 1`
    fi
done

echo
if [ "$TMP_ERROR_COUNT" == 0 ]
then
    echo "    ==>All required packages are installed. OK."
    echo -e "\t\t\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo "    ==> $TMP_ERROR_COUNT required packages are not installed, please see $CFG_OUTPUT_BUNDLE_FOLDER/packages.txt for instruction to resolve."
	echo "yum install ${REQ_1_59_PACKAGES_REQUIRE}" > $CFG_OUTPUT_BUNDLE_FOLDER/packages.txt
    echo -e "\t\t\t${RED}Failed${NONE}" > `tty`
fi
echo '****************************************************************************'
echo '****************************************************************************'
####

#
#  REQ 1.60 - The ANT package is NOT installed
#
echo '***************** Checking that ANT is not installed ***************'
echo '*** ANT should not be installed as it interfere with the ***********'
echo '*** ant which is packages with the Trellis installer ***************'
echo -n "[REQ 1.60]  Checking for ANT package..." > `tty`
echo "[REQ 1.60]  Checking for ANT package..." 
CMD_RPM_SEARCH=`rpm -q apache-ant`
# (9-27-18 RayD) Changed string in test from ant to apache-ant
if [ "$CMD_RPM_SEARCH" != "package apache-ant is not installed" ]
then
    echo "    ==>Automatic check failed!"
    echo "    ==> ANT is installed."
    echo -e "\t\t\t\t${RED}Failed${NONE}" > `tty`
else
    echo "    ==>ANT is not installed. OK."
    echo -e "\t\t\t\t${GREEN}Passed${NONE}" > `tty`
fi
echo '****************************************************************************'
echo '****************************************************************************'
#####

#
#  REQ 1.61 - The “/etc/sysctl.conf” file is configured correctly
#
echo '**********/etc/sysctl.conf Content and File Integrity**************'
echo '*****Content must be manually reviewed by PS and/or Engineering*****'
cat /etc/sysctl.conf
file /etc/sysctl.conf
echo
echo '*****Automatic Checking of sysctl.conf file*****'
echo -n "[REQ 1.61]  Checking /etc/sysctl.conf..." > `tty`
echo "[REQ 1.61]  Checking /etc/sysctl.conf..." 
##  Now the ones we'll need to do some comparing with. I can't think 
##  of a more elegant way to do this at this time, so I'll just do brute
##  force compares for now.

wrong=0

# The first two parameters are static values so the entire line must be compared
SYSCTRL_PARM="kernel.sem"
SYSCTRL_PARM_value="250 32000 100 128"
SYSCTRL_PARM_current=`grep $SYSCTRL_PARM /etc/sysctl.conf | grep -v "#" | tr -d $SYSCTRL_PARM | tr -d "=" | sed 's/^[ \t]*//;s/[ \t]*$//'`
rows=`grep $SYSCTRL_PARM /etc/sysctl.conf | grep -v "#" | wc -l`

echo "Checking $SYSCTRL_PARM parameter"

if [ $rows == 0 ]; then
    echo " - WARNING: $SYSCTRL_PARM does not exist in /etc/sysctl.conf, this should have a value of $SYSCTRL_PARM_value"
    wrong=1
elif [ $rows -ge 2 ]; then 
    echo " - WARNING: $SYSCTRL_PARM is duplicated in /etc/sysctl.conf, this should have a value of $SYSCTRL_PARM_value"
    wrong=1    
elif [ "$SYSCTRL_PARM_current" == "$SYSCTRL_PARM_value" ]; then
    echo " - $SYSCTRL_PARM value OK" 
else
    echo " - WARNING: $SYSCTRL_PARM value is $SYSCTRL_PARM_current, which is different to the required value of '$SYSCTRL_PARM_value' for Trellis"
    wrong=1
fi

SYSCTRL_PARM="net.ipv4.ip_local_port_range"
# (9-27-18 RayD) Changed value from 65535 to 65500, taken from the 7.3 kickstart
SYSCTRL_PARM_value="9000 65500"
SYSCTRL_PARM_current=`grep $SYSCTRL_PARM /etc/sysctl.conf | grep -v "#" | tr -d $SYSCTRL_PARM | tr -d "=" | sed 's/^[ \t]*//;s/[ \t]*$//'`
rows=`grep $SYSCTRL_PARM /etc/sysctl.conf | grep -v "#" | wc -l`

echo "Checking $SYSCTRL_PARM parameter"

if [ $rows == 0 ]; then
    echo " - WARNING: $SYSCTRL_PARM does not exist in /etc/sysctl.conf, this should have a value of $SYSCTRL_PARM_value"
    wrong=1
elif [ $rows -ge 2 ]; then 
    echo " - WARNING: $SYSCTRL_PARM is duplicated in /etc/sysctl.conf, this should have a value of $SYSCTRL_PARM_value"
    wrong=1    
elif [ "$SYSCTRL_PARM_current" == "$SYSCTRL_PARM_value" ]; then
    echo " - $SYSCTRL_PARM value OK" 
else
    echo " - WARNING: $SYSCTRL_PARM value is $SYSCTRL_PARM_current, which is different to the required value of '$SYSCTRL_PARM_value' for Trellis"
    wrong=1
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
# (9-27-18 RayD) Remove kernel.random.write_wakeup_threshold, which is not in the 7.3 kickstart
# SYSCTRL_LIST="$SYSCTRL_LIST kernel.random.write_wakeup_threshold"

for i in $SYSCTRL_LIST
do
  SYSCTRL_PARM=$i
  SYSCTRL_PARM_MAX=`grep $SYSCTRL_PARM /etc/sysctl.conf | grep -v "#" | awk '{ print $NF }'`
  rows=`grep $SYSCTRL_PARM /etc/sysctl.conf | grep -v "#" | wc -l`    
  
  echo "Checking $i parameter"

  if [ "$SYSCTRL_PARM" = "fs.aio-max-nr" ]; then
	SYSCTRL_PARM_min=1048576
  elif [ "$SYSCTRL_PARM" = "fs.file-max" ]; then
	SYSCTRL_PARM_min=6815744
  elif [ "$SYSCTRL_PARM" = "kernel.shmall" ]; then
# (9-27-18 RayD) Changed value from 2097152 to 3774873, taken from the 7.3 kickstart
	SYSCTRL_PARM_min=3774873
  elif [ "$SYSCTRL_PARM" = "kernel.shmmax" ]; then
# (9-27-18 RayD) Changed value from 536870912 to 15461882265, taken from the 7.3 kickstart
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
# (9-27-18 RayD) Remove kernel.random.write_wakeup_threshold, which is not in the 7.3 kickstart
#  elif [ "$SYSCTRL_PARM" = "kernel.random.write_wakeup_threshold" ]; then
#	SYSCTRL_PARM_min=1024  
  fi
  
  if [ $rows == 0 ]; then
    echo " - WARNING: $SYSCTRL_PARM does not exist in /etc/sysctl.conf, this should have a min value of $SYSCTRL_PARM_min"
    wrong=1
  elif [ $rows -ge 2 ]; then 
    echo " - WARNING: $SYSCTRL_PARM is duplicated in /etc/sysctl.conf, this should have a min value of $SYSCTRL_PARM_min"
    wrong=1    
  elif [ $SYSCTRL_PARM_MAX == $SYSCTRL_PARM_min ]; then
    echo " - $SYSCTRL_PARM value OK" 
  elif [ $SYSCTRL_PARM_MAX -ge $SYSCTRL_PARM_min ]; then
    echo " - $SYSCTRL_PARM value OK" 
    echo " - INFO: $SYSCTRL_PARM value is $SYSCTRL_PARM_MAX, which is greater than the required value of $SYSCTRL_PARM_min for Trellis"    
  else
    echo " - WARNING: $SYSCTRL_PARM value is $SYSCTRL_PARM_MAX, which is less than the required value of $SYSCTRL_PARM_min for Trellis"
    wrong=1
  fi
done

echo 
if [ $wrong == 0 ]
then
    echo "    ==>sysctl.conf settings are correct. OK"
    echo -e "\t\t\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo "       You could consider appending /etc/sysctl.conf with the contents of $CFG_OUTPUT_BUNDLE_FOLDER/sysctl.conf"	
    echo -e "\t\t\t${RED}Failed${NONE}" > `tty`
fi

echo '****************************************************************************'
echo '****************************************************************************'
#####

# (19 Sep 2018 - (RayD) Test removed to avoid conflict with Engineering Precheck
##
##  REQ 1.62 - The “/etc/limits.conf” file is configured correctly
##
#echo '**********/etc/security/limits.conf Content and File Integrity******'
#echo '******Content must be manually reviewed by PS and/or Engineering****'
#echo -n "[REQ 1.62]  Checking /etc/limits.conf..." > `tty`
#echo "[REQ 1.62]  Checking /etc/limits.conf..."
#cat /etc/security/limits.conf
#file /etc/security/limits.conf
#echo
#grep oracle /etc/security/limits.conf | grep -v "#" > $CFG_OUTPUT_BUNDLE_FOLDER/limits.conf-installed
#DIFF_counter=`diff $CFG_OUTPUT_BUNDLE_FOLDER/limits.conf $CFG_OUTPUT_BUNDLE_FOLDER/limits.conf-installed | wc -l`
#if [ "$DIFF_counter" == 0 ]
#then
#    echo "    ==>/etc/security/limits.conf is good. OK."
#    echo -e "\t\t\t${GREEN}Passed${NONE}" > `tty`
#else
#    echo "    ==>Automatic check failed!"
#    echo "       Check formatting for oracle limits"
#    echo -e "\t\t\t${RED}Failed${NONE}" > `tty`
#fi
#echo '****************************************************************************'
#echo '****************************************************************************'
#####

#
#  REQ 1.63 - The “/etc/pam.d/login” file is configured correctly
#
echo '**********/etc/pam.d/login Content ******'
echo -n "[REQ 1.63]  Checking /etc/pam.d/login..." > `tty`
echo "[REQ 1.63]  Checking /etc/pam.d/login..." 
cat /etc/pam.d/login
file /etc/pam.d/login
echo
echo "---CHECKING THE LOGIN FILE---"
LOG_CHECK=`grep "/lib64/security/pam_limits.so" /etc/pam.d/login | wc -l`
if [ $LOG_CHECK -eq 0 ]; then
	echo
    echo "       You could consider appending /etc/pam.d/login with the contents of $CFG_OUTPUT_BUNDLE_FOLDER/pam.d-login"
    echo "       Check /etc/pam.d/login for /lib64/security/pam_limits.so line"
    echo -e "\t\t\t${RED}Failed${NONE}" > `tty`
else
    echo "    ==>/etc/pam.d/login is good. OK."
    echo -e "\t\t\t${GREEN}Passed${NONE}" > `tty`
fi
echo '****************************************************************************'
echo '****************************************************************************'
#####

#
#  REQ 1.64 - Confirm oracle user umask is set correctly (000 or 002)
#
echo '****************************************************************************'
echo '****************************************************************************'
echo '**********Oracle User umask ******'
echo -n "[REQ 1.64]  Checking oracle user umask..." > `tty`
echo "[REQ 1.64]  Checking oracle user umask..."
cat /home/oracle/.bashrc
file /home/oracle/.bashrc
echo
UMASK_CHECK=`runuser -l oracle -c 'umask' | egrep "0002|0000" | wc -l`
if [ $UMASK_CHECK -eq 1 ]; then
    echo "    ==>oracle umask is good. OK."
    echo -e "\t\t\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo "       Umask should be set to 0000 or 0002 in the /home/oracle/.bashrc file"
	echo "       Check umask setting in /home/oracle/.bashrc file"
    echo -e "\t\t\t${RED}Failed${NONE}" > `tty`
fi
echo '****************************************************************************'
echo '****************************************************************************'
#####

#
#  REQ 1.65 - Confirm licensing server symlinks are created.
#
echo '********************Licence Server Symlinks*************************'
echo -n "[REQ 1.65]  Checking for Licence server symlinks..." > `tty`
echo "[REQ 1.65]  Checking for Licence server symlinks..."

##  If user asked to fix problems, will fix possible bug found with symlinks and ssl
##  Bug prevents the license server from working.
echo ""
echo "---CHECKING FOR LICENSE SERVER SYMLINKS---"
if [ "$RELEASE" == "5.9" ]; then
    echo "    ==>Not Applicable for Red Hat 5.9.  OK."
    echo "  N/A" > `tty`
else
# (9-27-18 RayD) Change licensing folder to /u02/licensing
    existing_symlinks=`ls -l /u02/licensing | egrep "libcrypto.so.1.0.0 -> /usr/lib/libcrypto.so.1.0.1e|libssl.so.1.0.0 -> /usr/lib/libssl.so.1.0.1e" | wc -l`

    if [ "$existing_symlinks" == 2 ]
    then
        echo "    ==>Licence Server Symlinks are good. OK."
        echo -e "\t\t${GREEN}Passed${NONE}" > `tty`        
    else
        echo "INFO: You can manually fix this by doing 'mkdir -p /usr/lib/licenseserver && ln -s /usr/lib/libcrypto.so.10 /usr/lib/licenseserver/libcrypto.so.1.0.0 && ln -s /usr/lib/libssl.so.10 /usr/lib/licenseserver/libssl.so.1.0.0' before the install. If you wait until after the install, you will have to delete the auto-generated ones first"    
        echo "    ==>Automatic check failed!"
        echo -e "\t\t${RED}Failed${NONE}" > `tty`
    fi	
fi
#####


#
#  REQ 1.66 - Confirm file permissions are retained
#
echo '*************Confirm file permissions are retained******************'
echo '****************************************************************************'
echo 
echo -n '[REQ 1.66]  Checking file permissions are retained' > `tty`
echo '[REQ 1.66]  Checking file permissions are retained' 
wrong=0
su - oracle -c 'touch /home/oracle/abc.txt'
su - oracle -c 'chmod -R 755 /home/oracle/abc.txt'
properties=`ls -l /home/oracle/abc.txt`
permission=`echo $properties | awk '{print $1}' | cut -f1 -d"."`

echo "$properties"

if [ "$permission" != "-rwxr-xr-x" ]
then
    wrong=1
else
    su - oracle -c 'cp /home/oracle/abc.txt /tmp/abc.txt'
    properties=`ls -l /tmp/abc.txt`
    permission=`echo $properties | awk '{print $1}' | cut -f1 -d"."`    

    echo "$properties"
    
    if [ "$permission" != "-rwxr-xr-x" ]
    then
        wrong=1
    fi
    su - oracle -c 'rm /tmp/abc.txt'
fi
su - oracle -c 'rm /home/oracle/abc.txt'

echo
if [ $wrong == 0 ]
then
    echo "    ==>File permissions retention is correct. OK"
    echo -e "\t\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo -e "\t\t${RED}Failed${NONE}" > `tty`
fi
echo '****************************************************************************'
echo '****************************************************************************'
#####

#
#  REQ 1.67 - Confirm /tmp permissions are correct
#
echo '***********************Confirm /tmp Permissions ****************************'
echo '****************************************************************************'
echo 
echo -n '[REQ 1.67]  Checking /tmp permissions are correct' > `tty`
echo '[REQ 1.67]  Checking /tmp permissions are correct' 
su - oracle -c "touch /tmp/testwrite.txt"
if sudo -u oracle test -f '/tmp/testwrite.txt'; then
    echo "    ==>File permissions retention is correct. OK"
    echo -e "\t\t${GREEN}Passed${NONE}" > `tty`
	su - oracle -c "rm /tmp/testwrite.txt"
else
    echo "    ==>Automatic check failed!"
    echo -e "\t\t${RED}Failed${NONE}" > `tty`
fi
#####

#
#  REQ 1.68 - Checking global Java version
#
echo '**************************Global Java Version*******************************'
echo '****************************************************************************'
echo 
echo -n '[REQ 1.68]  Checking Global Java version ' > `tty`
echo '[REQ 1.68]  Checking Global Java version'
if sudo -u oracle test -e `which java`]; then
    _java=java
	echo -e "exists" > `tty`
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    _java="$JAVA_HOME/bin/java"
	echo -e "exists" > `tty`
else
	echo -e "does not exist" > `tty`
fi

REQ_1_68_PASS=$false

if [ "$_java" ]; then
	version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d '.' -f 1,2 )
	if [ "$version" == "1.7" ] | [ "$version" == "1.6" ]; then
		REQ_1_68_PASS=$true
	else
		REQ_1_68_PASS=$false
	fi
else
	REQ_1_68_PASS=$true
fi

if [ $REQ_1_68_PASS == $true ]; then
    echo "    ==>File permissions retention is correct. OK"
    echo -e "${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo -e "${RED}Failed${NONE}" > `tty`
fi
#####

# (26 Sep 2018 - (RayD) Added test
#
#  REQ 1.69 - Confirm /home/oracle owner is correct
#
echo '**************************\home\oracle ownership****************************'
echo '****************************************************************************'
echo 
echo -n '[REQ 1.69]  Checking /home/oracle ownership' > `tty`
echo '[REQ 1.69]  Checking /home/oracle ownership'

	wrong=0
    properties=`ls -ld /home/oracle`
    ownership=`echo $properties | awk '{print $3}'`
    group_ownership=`echo $properties | awk '{print $4}'`
	echo "$properties"
	
    if [ "$ownership" != "oracle" ];
    then
        wrong=1
        echo "Ownership of %ownership on /home/oracle is wrong"
    fi
    if [ "$group_ownership" != "oinstall" ];
    then
        wrong=1
        echo "Group ownership of $group_ownership on /home/oracle is wrong"
    fi
	
	if [ $wrong == 0 ]; then
		echo "    ==>Ownership is correct. OK"
		echo -e "\t\t\t${GREEN}Passed${NONE}" > `tty`
	else
		echo "    ==>Automatic check failed!"
		echo -e "\t\t\t${RED}Failed${NONE}" > `tty`
	fi
#####


# (30 Sep 2018 - (RayD) Added test
#
#  REQ 1.70 - Confirm enough swap file space
#
echo '**************************Swap File space***********************************'
echo '****************************************************************************'
echo 
echo -n '[REQ 1.70]  Checking swap file space' > `tty`
echo '[REQ 1.70]  Checking swap file space'

	wrong=0
    swaptotal=`free -h | grep 'Swap:' | awk '{print $2}'`
    swapfree=`free -h | grep 'Swap:' | awk '{print $4}'`
	swapfreenumber=`free -h | grep 'Swap:' | awk '{print $4}' | cut -d 'G' -f 1`
	echo " There is $swapfree of free swap file space out of $swaptotal total.  You should have at least 10G free before you begin the install/upgrade."
    if [ $swapfreenumber -le 10 ];
    then
        wrong=1
        echo "Insufficient swap file space"
    fi
	
	if [ $wrong == 0 ]; then
		echo "    ==>Free swap file space is correct. OK"
		echo -e "\t\t\t\t${GREEN}Passed${NONE}" > `tty`
	else
		echo "    ==>Automatic check failed!"
		echo -e "\t\t\t\t${RED}Failed${NONE}" > `tty`
	fi
#####


###############################################################################
#       REQ 2.* HARDWARE CHECKS
###############################################################################

# (19 Sep 2018 - (RayD) Test removed to avoid conflict with Engineering Precheck
##
##  REQ 2.2 - Memory Allocation reaches minimum requirements
##
#echo
#echo '******************* Memory Info ********************'
#
#echo -n "[REQ 2.2]   Checking Allocated Memory..." > `tty`
#echo "[REQ 2.2]   Checking Allocated Memory..." 
#echo 'Verify that server has 24GB (back) or 32GB (front)'
#MEM=`free -m | grep Mem | cut -f2 -d":" | awk '{print $1}'`
#echo "Current Memory: $CUR_MEMORY"
#echo
#if [ $TRELLIS_HOST_PROMPT = b ]; then
#    if [ "$MEM" -gt 23900 ]
#    then
#        echo " - INFO: Memory on back is greater than 24GB. OK."
#    else
#        echo " - WARNING: Memory on back is less than 24GB"
#        wrong=1
#    fi
#else
#    if [ "$MEM" -gt 31900 ]
#    then
#        echo " - INFO: Memory on front is greater than 32GB. OK."
#    else
#        echo " - WARNING: Memory on front is less than 32GB"    
#        wrong=1
#    fi    
#fi
#
#echo
#if [ "$wrong" == 0 ]
#then
#    echo "    ==>Memory Allocation Sufficient. OK"
#    echo -e "\t\t\t${GREEN}Passed${NONE}" > `tty`
#else
#    echo "    Please check memory specifications"
#    echo "    ==>Automatic check failed!"
#    echo -e "\t\t\t${RED}Failed${NONE}" > `tty`
#fi

#echo '****************************************************************************'
#echo '****************************************************************************'
#####

# (19 Sep 2018 - (RayD) Test removed to avoid conflict with Engineering Precheck
##
##  REQ 2.3 - HDD I/O Throughput reaches minimum requirements
##
#echo ""
#echo '************************** Disk Performance (Flushed-Write) ****************************'
#echo -n '[REQ 2.3]   Checking disk speed access (Un-Cached)...' > `tty`
#echo '[REQ 2.3]   Checking disk speed access (Un-Cached)...' 
#echo "INFO: Speeds of 150 MB/s or greater are required for Trellis"
#
## Remove file if it exists from previous check
#rm -f ${DD_OUTFILE}
#
#PASS=1
#SUM_SPEED=0
#
#while [ $PASS -lt 6 ]; do
#  DD=`dd if=/dev/zero of=${DD_OUTFILE} ${DD_PARAM_FLUSHED} 2>&1 | grep copied`
#  echo "    Pass $PASS: $DD"
#  SPEED=`echo $DD | awk -F, '{ print $NF }' | cut -f1 -d"." | sed 's@ @@1'`
#  SIZE=`echo $SPEED | awk '{ print $2 }'`
#  if [ $SIZE = "GB/s" ]; then
#    SPEED2=$((`echo $SPEED | awk '{ print $1 }'`)*1024)
#    echo "    SUCCESS: Pass $PASS - $SPEED - well above the required threshold" 
#  elif [ $SIZE = "MB/s" ]; then
#    SPEED2=`echo $SPEED | awk '{ print $1 }'`
#    if [ $SPEED2 -ge 150 ]; then
#      echo "    SUCCESS: Pass $PASS - $SPEED - acceptable for Trellis installs" 
#    else
#      echo "    WARNING: Pass $PASS - $SPEED - too low for good performance with Trellis"
#    fi
#  else
#    SPEED2=0
#    echo "    WARNING: Pass $PASS - $SPEED - too low for good performance with Trellis"
#  fi
#  
#  SUM_SPEED=$((SUM_SPEED + SPEED2))
#  let PASS=PASS+1
#  rm -f ${DD_OUTFILE} 
#done
#echo
#
#SUM_SPEED=$((SUM_SPEED / 5))
#
#echo -e "    INFO: Average speed $SUM_SPEED MB/s"
#
#if [ $SUM_SPEED -lt 150 ]; then
#	echo "    ==>Automatic check failed!"
#	echo -e "\t\t${RED}Failed${NONE}" > `tty`
#else
#	echo "    ==>Average disk throughput. OK"
#	echo -e "\t\t${GREEN}Passed${NONE}" > `tty`
#fi
#
#echo -e "            INFO: Average speed $SUM_SPEED MB/s" > `tty`
#
#echo '****************************************************************************'
#echo 
#####

# (05 Oct 2018 - (RayD) Add separate test for upgrades
#
#  REQ 2.4 - HDD Install Destination Capacity meets required specification
#
echo '******************* Hard Disk Space ********************'
echo
echo -n "[REQ 2.4]   Checking HDD Destination Capacity..." > `tty`
echo "[REQ 2.4]   Checking HDD Destination Capacity..."

if ["$TRELLIS_NEW_INSTALL"="Yes"]; then

echo 'Verify that server has 300GB Space or the following:'
echo ' - /home/oracle = 20GB'
echo ' - /tmp = 10GB'
echo ' - /u01 = 100GB'
echo ' - /u02 = 100GB'
echo ' - /u03 = 30GB'
echo ' - /u05 = 30GB'
echo ' - / = 10GB'
echo
df -h
echo
free -m
##  Check partition sizes
##  Using df -kP to get all sizes in 1k blocks for use in size calculations.
##  The P makes the output in Posix format, so the lines don't get broken if
##  too long.
wrong=0
PARTITION_LIST_FULL="/ /home/oracle /tmp /u01 /u02 /u03 /u05"
PARTITION_LIST_SHORT="/home/oracle|/tmp|/u01|/u02|/u03|/u05"
PARTITION_SHORT_COUNT=`df | egrep -w $PARTITION_LIST_SHORT | wc -l`
echo ""
echo "---CHECKING DISK SIZES---"
#Check for root
ROOT=`df -kP | awk '{ print $6, $2 }' | grep '/' -w | awk '{ print $2 }'`
ROOT_MIN_NO_PARTITION=313629081
ROOT_REAL_NO_PARTITION=314572800
ROOT_MIN_YES_PARTITION=10391388
ROOT_REAL_YES_PARTITION=10485760
echo "Checking root partition size and determine if partitions exist..."
if [ -z $ROOT ]; then
  echo " - WARNING: Root partition does not exist"
  wrong=1
else 
  if [ $PARTITION_SHORT_COUNT -gt 0 ]; then
    PARTITION_CHECK=y
    echo " - INFO: Partitions detected"
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
      wrong=1      
	  echo " - WARNING: Root partition is" `bc -l <<< "scale=2; $ROOT / (1024^2)"`"GB which is less than the" `bc -l <<< "scale=0; $CHECK_DIR_REAL / (1024^2)"`"GB required for Trellis and no other partitions are detected"
      echo " - INFO: Please provision more space for the root partition or re-partition the Trellis server according to the Trellis installation manual"
    else
      ROOT_ABOVE_MIN_NO_PARTITION=y
      echo " - SUCCESS: Root partition is" `bc -l <<< "scale=2; $ROOT / (1024^2)"`"GB which is OK for Trellis"      
      if [ $TRELLIS_HOST_PROMPT = b ]; then
        echo " - INFO:  If site manager is to be installed, please manually check this partition for additional sizing requirements"     
      fi
      
    fi
  fi
fi
echo
echo "Checking partition sizes..."
if [ $PARTITION_CHECK = 'y' ]; then
  for i in $PARTITION_LIST_FULL
  do
      CHECK_DIR_NAME=$i
      CHECK_DIR_VALUE=`df -kP | awk '{ print $6, $2 }' | grep $CHECK_DIR_NAME -w | awk '{ print $2 }'`
      echo "Checking $i partition"
    
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
           echo " - INFO: $CHECK_DIR_NAME partition does not exist, however it should not matter as the ROOT directory is greater than" `bc -l <<< "scale=0; $ROOT_MIN_NO_PARTITION / (1024^2)"`"GB"
        else
          echo " - WARNING: $CHECK_DIR_NAME partition does not exist, this should be a minimum of" `bc -l <<< "scale=0; $CHECK_DIR_MIN / (1024^2)"`"GB required for Trellis as the ROOT directory is less than" `bc -l <<< "scale=0; $ROOT_MIN_NO_PARTITION / (1024^2)"`"GB"
          wrong=1
        fi
      else  
        if [ $CHECK_DIR_VALUE -lt $CHECK_DIR_MIN ]; then
          echo " - WARNING: $CHECK_DIR_NAME partition is" `bc -l <<< "scale=2; $CHECK_DIR_VALUE / (1024^2)"`"GB which is less than the" `bc -l <<< "scale=0; $CHECK_DIR_REAL / (1024^2)"`"GB required for Trellis, please repartition Trellis server according to the Trellis installation manual"
          wrong=1
        else
          echo " - SUCCESS: $CHECK_DIR_NAME partition is" `bc -l <<< "scale=2; $CHECK_DIR_VALUE / (1024^2)"`"GB which is OK for Trellis"
          
          if [ $TRELLIS_HOST_PROMPT = b -a $CHECK_DIR_NAME = "/u02" ]; then
            echo "INFO:  If site manager is to be installed, please manually check this partition for additional sizing requirements"     
          fi
          
        fi
      fi    
  done
else
  echo " - INFO: No partitions detected - Skipping partition checks"
fi

# this is an upgrade.  Look for 10G of free TMP space, and either 50GB free if no paritiions, or 25G in /u01 and /u02
else




fi

echo
if [ "$wrong" == 0 ]
then
    echo "    ==>HDD Destination Capacity Sufficient. OK"
    echo -e "\t\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    Please check HDD specifications"
    echo "    ==>Automatic check failed!"
    echo -e "\t\t${RED}Failed${NONE}" > `tty`
fi

echo '****************************************************************************'
echo '****************************************************************************'
#####

#
#  REQ 2.7 - CPU Nominal Core Frequency meets required specification
#  REQ 2.8 - CPU Nominal Core Frequency meets optimised specification (recommendation)
#
echo
echo '******************* CPU Info ********************'
echo
echo -n "[REQ 2.7]   Checking CPU Frequency..." > `tty`
echo "[REQ 2.7]   Checking CPU Frequency..." 
echo
echo "CPU Details"
cat /proc/cpuinfo
echo
echo '*************Confirm CPUs min 2.2 GHz***********'
CPU_FREQ="`cat /proc/cpuinfo | grep "cpu MHz" -m 1 | cut -f2 -d":" | cut -f1 -d"." | sed 's/^[ \t]*//;s/[ \t]*$//'`"
echo "CPU Frequency = $CPU_FREQ"

if [ $CPU_FREQ -gt 2200 ]; then

    if [ $CPU_FREQ -gt 2600 ]; then
        echo "    ==>CPU Frequency Optimal Frequency. OK"
        echo -e "\t\t\t\t${GREEN}Passed${NONE}" > `tty`
    else
        echo "    ==>CPU Frequency Sufficient. OK"
		echo "INFO: It is recommended that the CPU frequency is greater than 2.6GHz"
        echo -e "\t\t\t\t${GREEN}Passed${NONE}" > `tty`
    fi
else
    echo "    ==>CPU Frequency Too Low"
    echo "    ==>Automatic check failed!"
    echo -e "\t\t\t\t${RED}Failed${NONE}" > `tty`
fi

echo '****************************************************************************'
echo '****************************************************************************'
#####


#
#  REQ 2.9 - CPU core count meets required specification
#
echo
echo '******************* CPU Total Core Count ********************'
echo
echo -n "[REQ 2.9]   Checking CPU Total Core Count..." > `tty`
echo "[REQ 2.9]   Checking CPU Total Core Count..." 
echo
echo "CPU Total Core Count"
echo `nproc`
echo
TOTAL_CORES=`nproc`

echo "CPU Total Core Count = $TOTAL_CORES"
echo
if [ $TOTAL_CORES -lt 4 ]; then
    echo "    ==>Total CPU cores too low"
    echo "    ==>Automatic check failed!"
    echo -e "\t\t\t${RED}Failed${NONE}" > `tty`	
else
    echo "    ==>Total CPU cores count meets requirements. OK"
    echo -e "\t\t\t${GREEN}Passed${NONE}" > `tty`
fi

echo '****************************************************************************'
echo '****************************************************************************'
#####


###############################################################################
#       REQ 3.* VIRTUALIZATION CHECKS
###############################################################################

#
#  REQ 3.1 -  Virtualization Guest Drivers Installed
#
echo '***********************Check for VMWare Tools********************'
echo '****************************************************************************'
echo 
echo -n '[REQ 3.1]   Checking VMWare Tools are installed' > `tty`
echo '[REQ 3.1]   Checking VMWare Tools are installed'

if [ "$CUR_VIRTUAL_STATUS" == "Yes" ];
then 
    if [ -e /usr/bin/vmware-toolbox-cmd ]; then
        echo "VMWare Guest Tools version `vmware-toolbox-cmd -v` installed."
        echo "    ==>VMWare Tools Installed. OK"
        echo -e "\t\t\t${GREEN}Passed${NONE}" > `tty`		
    else
        echo "VMWare Guest Tools not detected."
        echo "    ==>Automatic check failed!"
        echo -e "\t\t\t${RED}Failed${NONE}" > `tty`		
    fi
else
    echo "    ==>Not a virtual machine. OK"
    echo -e "\t\t\t${YELLOW}N/A${NONE}" > `tty`
fi

echo '****************************************************************************'
echo '****************************************************************************'
####

#
#  [REQ 3.5] - RNGD options configured for Virtual Environment
#
##  Check entropy service is configured correctly
echo '*****************Should show EXTRAOPTIONS="'$ENTROPY_EXTRAOPTIONS'" in rngd service **************'
echo -n "[REQ 3.5]   Checking RNGD options configured..." > `tty`
echo "[REQ 3.5]   Checking RNGD options configured..." 

cat /etc/sysconfig/rngd
echo

if [ "$CUR_VIRTUAL_STATUS" == "Yes" ];
then 
    RNGD_OPTIONS=`cat /etc/sysconfig/rngd | grep "EXTRAOPTIONS" | grep -v '^#' | cut -f2 -d"="`
    if [ "$RNGD_OPTIONS" == '"'"$ENTROPY_EXTRAOPTIONS"'"' ]; then
        echo "    ==>Entropy options set correctly for virtual environment. OK."
        echo -e "\t\t\t${GREEN}Passed${NONE}" > `tty`
    else
        echo 'Please update /etc/sysconfig/rngd with the following line EXTRAOPTIONS="'$ENTROPY_EXTRAOPTIONS'"'
        echo "    ==>Automatic check failed!"
        echo -e "\t\t\t${RED}Failed${NONE}" > `tty`
    fi
else
    echo "    ==>Not a virtual machine. OK"
    echo -e "\t\t\t${YELLOW}N/A${NONE}" > `tty`
fi


###############################################################################
#       REQ 4.* SECURITY CHECKS
###############################################################################

#
#  REQ 4.2 - Firewall Is Disabled
#
echo '****************************************************************************'
echo '******************************IPTables Info**************************'
echo '***********************Confirm IPTables service = disabled*******************'
echo -n "[REQ 4.2]   Checking Firewall is disabled (iptables)..." > `tty`
echo "[REQ 4.2]   Checking Firewall is disabled (iptables)..." 

##  Check to be sure iptables is turned off
echo ""
echo "---CHECKING TO BE SURE IPTABLES IS TURNED OFF---"
IPTABLES=`service iptables status`

##  Added for RH6.5 where the status returns trailing special characters
IPTABLES=`echo $IPTABLES`

if [ `echo "$IPTABLES" | grep "$IPTABLES_RESULT" | wc -l` != 1 ]; then
	echo "    ==>Automatic check failed!"
    echo "If you want to do it manually you will need to run 'service iptables stop && chkconfig iptables off' on the command line"    

    if [ $RELEASE = "6.5" ]; then
        echo "Once complete please restart the OS for changes to be reflected in the service status"
	fi
	
    #echo "  Automatic check failed!" > `tty`
	echo -e "\t\t${RED}Failed${NONE}" > `tty`
else
  echo "    ==>iptables service is not running. OK."
  echo -e "\t\t${GREEN}Passed${NONE}" > `tty`
fi
echo '****************************************************************************'
echo '****************************************************************************'
#####

#
#  REQ 4.3 - Entropy Services Enabled AND Starting up with server
#
##  Check entropy service is started
echo '*****************Should show EXTRAOPTIONS="'$ENTROPY_EXTRAOPTIONS'" in rngd service **************'
echo -n "[REQ 4.3]   Checking RNGD service status..." > `tty`
echo "[REQ 4.3]   Checking RNGD service status..." 
echo

ENT=`cat /proc/sys/kernel/random/entropy_avail`

echo "---CHECKING ENTROPY LEVELS and service status---"
echo "INFO: Entropy at: $ENT"
echo "INFO: Current rngd service status: " `service rngd status`
echo "INFO: Current rngd startup status: " `chkconfig | grep rngd`

RNGD_STATUS_COUNT=`service rngd status | grep "is running" |  wc -l`
RNGD_STARTUP=`chkconfig | grep rngd`
RNGD_STARTUP_COUNT=`echo $RNGD_STARTUP | grep "3:on 4:on 5:on" | wc -l`

wrong=0

echo
if [ "$RNGD_STATUS_COUNT" == 1 ]
then
    echo "RNGD Service is started"
	
    ##  Check entropy levels
    ##  Since both the front and back server use Oracle and Oracle installations
    ##  entropy is an important part of the puzzle as they use it to encrypt 
    ##  various pieces as they go. 150 was the original leve we checked for, 
    ##  JJ Everett mentioned that it should be over 200 at the very least
    ##  The engineering release notes expect this to be over 1000
    ##  There is no "check" needed as this needs to be checked prior to the installation anyway as if the server is rebooted this will be reset to 0.  
    ## This script may as well generate some entropy if it is needed, just to be useful.
    if [ $ENT -le 1000 ]
    then
        echo "INFO: Entropy less than 1000.... generating more..."
        $ENTROPY
        ENT=`cat /proc/sys/kernel/random/entropy_avail`
        echo "INFO: Entropy at: $ENT"
    fi

else
    echo "RNGD Service is NOT started"
	wrong=1

	echo "Starting the entropy service..."
	$ENTROPY
    ENT=`cat /proc/sys/kernel/random/entropy_avail`
    echo "INFO: Entropy at: $ENT"
fi

if [ "$RNGD_STARTUP_COUNT" == 1 ]
then
    echo "RNGD Service is set to start correctly"
else
    echo "RNGD Service is NOT set to start correctly"
	echo "This can be set to start by using the command 'chkconfig --levels 345 rngd on'"
	wrong=1
fi

if [ "$wrong" == 0 ]
then
    echo "    ==>Entropy service was started and set to start with OS.  OK"
    echo -e "\t\t\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    Entropy service was NOT started or was NOT set to start with OS."
    echo "    ==>Automatic check failed!"
    echo -e "\t\t\t${RED}Failed${NONE}" > `tty`
fi

echo '****************************************************************************'
echo '****************************************************************************'
#####

#
#  REQ 4.4 - Confirm SELinux is disabled
#
echo '******************************SELINUX Info**************************'
echo '***********************Confirm SELINUX = disabled*******************'
echo -n "[REQ 4.4]   Checking SELINUX..." > `tty`
echo "[REQ 4.4]   Checking SELINUX..." 
cat /etc/selinux/config
echo
SELINUX=`cat /etc/selinux/config | grep "SELINUX=" | grep -v "#" | cut -f2 -d"="`
if [ "$SELINUX" == "disabled" ]
then
    echo "    ==>SELINUX is disabled. OK."
    echo -e "\t\t\t\t\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo "If you want to do it manually you will need to edit /etc/selinux/config and replace the $SELINUX in SELINUX= with disabled"    
    echo -e "\t\t\t\t\t${RED}Failed${NONE}" > `tty`
fi
echo '****************************************************************************'
#####


#
#  REQ 4.5 - IPv6 Firewall Is Disabled
#
echo '****************************************************************************'
echo '******************************IP6Tables Info**************************'
echo '***********************Confirm IP6Tables service = disabled*******************'
echo -n "[REQ 4.5]   Checking Firewall is disabled (ip6tables)..." > `tty`
echo "[REQ 4.5]   Checking Firewall is disabled (ip6tables)..." 

##  Check to be sure ip6tables is turned off
echo ""
echo "---CHECKING TO BE SURE IPTABLES IS TURNED OFF---"
IP6TABLES=`service ip6tables status`

if [ `echo "$IP6TABLES" | grep "$IP6TABLES_RESULT" | wc -l` != 1 ]; then
	echo "    ==>Automatic check failed!"
    echo "If you want to do it manually you will need to run 'service ip6tables stop && chkconfig ip6tables off' on the command line"    
	
    #echo "  Automatic check failed!" > `tty`
	echo -e "\t${RED}Failed${NONE}" > `tty`
else
  echo "    ==>ip6tables service is not running. OK."
  echo -e "\t${GREEN}Passed${NONE}" > `tty`
fi
echo '****************************************************************************'
echo '****************************************************************************'
#####


#
#  REQ 4.6 - Firewalld is disabled for 7.x
#
echo '****************************************************************************'
echo '******************************Firewalld Info********************************'
echo '*********************Confirm firewalld service = disabled*******************'
echo -n "[REQ 4.6]   Checking Firewalld is disabled (for RHEL 7.x)..." > `tty`
echo "[REQ 4.6]   Checking Firewalld is disabled (for RHEL 7.x)..." 

## Skip test if this is a 6.x OS
if ["${RELEASE:1:1}"] == "6"];
	echo "Skipping test since this is a 6.x OS"
	echo -e "\t\t${GREEN}Passed${NONE}" > `tty`
else
	##  Check to be sure firewalld is turned off
	echo "---CHECKING TO BE SURE FIREWALLD IS TURNED OFF---"
	FIREWALLD=`systemctl status firewalld.service`

	if [ `echo "$FIREWALLD" | grep "firewalld service is not enabled" | wc -l` != 1 ]; then
		echo "    ==>Automatic check failed!"
		echo "If you want to do it manually you will need to run 'systemctl mask firewalld' on the command line"    
	
		#echo "  Automatic check failed!" > `tty`
		echo -e "\t\t${RED}Failed${NONE}" > `tty`
	else
		echo "    ==>iptables service is not running. OK."
		echo -e "\t\t${GREEN}Passed${NONE}" > `tty`
	fi
fi

echo '****************************************************************************'
echo '****************************************************************************'
#####

###############################################################################
#       REQ 5.* NETWORK CHECKS
###############################################################################

#
#  REQ 5.1 - Only 1 NIC Enabled
#
echo '****************************IP config Info**************************'
echo '**********Confirm there is only 1 routable IP for this server*******'
echo -n "[REQ 5.1]   Checking IP config..." > `tty`
echo "[REQ 5.1]   Checking IP config..." 

ifconfig
echo
IP_count=`ifconfig | grep "inet addr:" | grep -v "127.0.0.1" | wc -l`
if [ "$IP_count" == 1 ]
then
    echo "    ==>Only 1 IP configured. OK."
    echo -e "\t\t\t\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo -e "\t\t\t\t${RED}Failed${NONE}" > `tty`
fi
echo '****************************************************************************'
echo '****************************************************************************'
#####

#
#  REQ 5.2 - DHCP Not Enabled
#

echo '******************************DHCP Info*****************************'
NIC="`ifconfig | grep "Link encap" | grep -v lo | awk  -F" "  '{ print $1 }'`"

echo '*****************Should show BOOTPROTO=static for NIC**************'
echo -n "[REQ 5.2]   Checking DHCP config..." > `tty`
echo "[REQ 5.2]   Checking DHCP config..."

cat /etc/sysconfig/network-scripts/ifcfg-${NIC}
echo
IP_set=`cat /etc/sysconfig/network-scripts/ifcfg-${NIC} | grep "BOOTPROTO" | cut -f2 -d"="`
if [ $IP_set == 'static' -o $IP_set == '"static"' -o $IP_set == 'none' -o $IP_set == '"none"' ]; then
    echo "    ==>IP address is static (no DHCP). OK."
    echo -e "\t\t\t\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo -e "\t\t\t\t${RED}Failed${NONE}" > `tty`
fi
echo '****************************************************************************'
echo '****************************************************************************'
#####

#
#  REQ 5.3 - Hosts resolve to correct IP
#  REQ 5.4 - Hosts present in hosts file
#
echo '******************************Hostfile Info*************************'
echo '******************For PS and/or Engineering review******************'
echo -n "[REQ 5.3]   Checking /etc/hosts..." > `tty`
echo "[REQ 5.3]   Checking /etc/hosts..."
cat /etc/hosts
file /etc/hosts
echo

##  Find out if user wants to fix host file automatically
host_ip_count=`cat /etc/hosts | egrep "$TRELLIS_FRONT_IP|$TRELLIS_BACK_IP" | wc -l`
if [ $host_ip_count == 0 ]; then
    echo -e "\nNo the front and back IP's were not found in the host file, would you like these to be automatically added? (y/n): " > `tty`
    while read FIX  > `tty`; do
         if [[ -z "${FIX}" ]]; then
              echo "Please indicate if you would like the host file updated?" > `tty`
         else
              break
         fi
    done
    if [ $FIX = "yes" -o $FIX = "Y" -o $FIX = "YES" -o $FIX = "Yes" ]; then
      FIX=y
    fi

    if [ $FIX = y ]; then
      echo "Auto-Fixing Hosts File"
      echo " - Backing up hosts file to $CFG_OUTPUT_BUNDLE_FOLDER/hosts.bak"
      cp /etc/hosts $CFG_OUTPUT_BUNDLE_FOLDER/hosts.bak
      echo " - Adding Trellis specific entries to the bottom of the /etc/hosts file"
      cat >> /etc/hosts $CFG_OUTPUT_BUNDLE_FOLDER/hosts
    fi
fi

cat /etc/hosts | egrep "$TRELLIS_FRONT_IP|$TRELLIS_BACK_IP" > $CFG_OUTPUT_BUNDLE_FOLDER/hosts.sys
cat $CFG_OUTPUT_BUNDLE_FOLDER/hosts | egrep "$TRELLIS_FRONT_IP|$TRELLIS_BACK_IP" > $CFG_OUTPUT_BUNDLE_FOLDER/hosts.good
DIFF_counter=`diff $CFG_OUTPUT_BUNDLE_FOLDER/hosts.sys $CFG_OUTPUT_BUNDLE_FOLDER/hosts.good | wc -l`
if [ "$DIFF_counter" == 0 ]
then
    echo "    ==>/etc/hosts is good. OK."
    
    if [ $host_ip_count == 0 ]; then	
        echo -e "\t\t\t\t\t\t${GREEN}Passed${NONE}" > `tty`	
    else
        echo -e "\t\t\t\t${GREEN}Passed${NONE}" > `tty`
	fi
else
    echo "    ==>Automatic check failed!"
    echo "       You could consider replacing /etc/hosts with $CFG_OUTPUT_BUNDLE_FOLDER/hosts"

    if [ $host_ip_count == 0 ]; then	
        echo -e "\t\t\t\t\t\t${RED}Failed${NONE}" > `tty`
    else
        echo -e "\t\t\t\t${RED}Failed${NONE}" > `tty`
	fi	

fi
echo '****************************************************************************'
echo '****************************************************************************'
#####


#
#  REQ 5.8 - Time Zone set to supported Time Zone
#
echo '***********************Required Time Servers********************'
echo -n "[REQ 5.8]   Checking Time Zone is supported..." > `tty`
echo "[REQ 5.8]   Checking Time Zone is supported..."

echo '****Time Server Details****'
echo 'Time Zone: '$CUR_TIMEZONE
echo 'Time Server: '$CUR_TIMESERVER
echo 


echo 
echo "Checking current zone exists within supported time zone list"
echo

# (9/18/2018 RayD) Change Timezone test to be OS dependent
TIMEZONE=`echo $TIMZONE_CMD`
ts_count=`echo $TIMEZONE_LIST | grep -ow $TIMEZONE | wc -l`

if [ "$ts_count" == 1 ]
then
    echo "    ==>Time Zone is supported. OK."
    echo -e "\t\t\t${GREEN}Passed${NONE}" > `tty`
else
    echo "    ==>Automatic check failed!"
    echo "    ==> Time zone is not one if the supported zones."
    echo -e "\t\t\t${RED}Failed${NONE}" > `tty`
fi
echo '****************************************************************************'
echo '****************************************************************************'
####

#
#  REQ 5.10 - Port Bind Validation
#
# echo '*******************************Port Bindings********************************'
# REQ_5_10_ENABLED='false'
# if [ $REQ_5_10_ENABLED == 'true' ]; then
	# REQ_5_10_PASS = 0
	# declare -a REQ_5_10_PORTS_FRONT = ("80","443","5556","5559","6010","6443","6700","6701","7001","7002","7003","7005","7011","7012","7028","7890","8001","8011","8012","8088")
	# declare -a REQ_5_10_PORTS_BACK = ("1158","1521","3938","5520","5556","5559","6701","7013","7014","7022","7023","7024","7026","7027","7031","8080","31313","36467","37869","46982")
	# CMD_NCAT_LISTENER="ncat -4t -l "
	# CMD_NCAT_CONNECT="ncat 127.0.0.1 "
	# #  ncat -4t -l <PORT>
	# # ncat 127.0.0.1 <PORT>
	
	# if [ $TRELLIS_HOST_PROMPT = f ]; then
		# for $port in "${REQ_5_10_PORTS_FRONT[@]}"; do
			# echo 
			# ${CMD_NCAT_LISTENER} ${port} &
			# sleep 1
			# LISTENER_PID=$!
			# ${CMD_NCAT_CONNECT} ${port} &
			# CONNECTOR_PID=$!
			# sleep 1
			# result=$?
			# echo "exit code: ${result}"
			# if [ "${result}" -eq "0" ] ; then
				# kill -SIGINT ${CONNECTOR_PID}
				# kill -SIGINT ${CMD_NCAT_LISTENER}
			# else
			# fi
		# done
	# else
		# for $port in "${REQ_5_10_PORTS_BACK[@]}"; do
			# ${CMD_NCAT_LISTENER} ${port} &
			# sleep 1
			# LISTENER_PID=$!
			# ${CMD_NCAT_CONNECT} ${port} &
			# CONNECTOR_PID=$!
			# sleep 1
			# result=$?
			# echo "exit code: ${result}"
			# if [ "${result}" -eq "0" ] ; then
				# kill -SIGINT ${CONNECTOR_PID}
				# kill -SIGINT ${CMD_NCAT_LISTENER}
			# else
			# fi
		# done
	# fi
	
	# echo -n "[REQ 5.10]  Checking Port Bindings..." > `tty`
	# if [ "$REQ_5_10_PASS" == 1 ]; then
		# echo -e "\t\t\t\t${GREEN}Passed${NONE}" > `tty`
	# else
		# echo -e "\t\t\t\t${RED}Failed${NONE}" > `tty`
	# fi
# fi
# echo '****************************************************************************'
# echo '****************************************************************************'
####

#
#  REQ 5.15 - IPv6 Loopback
#
# echo '*******************************IPv6 Loopback********************************'
# REQ_5_10_ENABLED='false'
# fi
# echo '****************************************************************************'
# echo '****************************************************************************'
####

###############################################################################
#       DEBUG INFORMATION
###############################################################################

echo '*****************************Process Info***********************************'
top -b -n 1
echo
echo '**********************Displaying Memory Information*************************'
/proc/meminfo 
echo
echo '***************************Displaying /etc/fstab****************************'
cat /etc/fstab
echo
echo '**************************Displaying NUMA Topology**************************'
numactl --hardware
echo
echo '************************Displaying Huge Page Support************************'
sysctl -a | grep huge
echo
echo '***********************Transparent Huge Pages Enabled***********************'
cat /sys/kernel/mm/redhat_transparent_hugepage/enabled
echo
echo '*************************Displaying System JDK/JRE**************************'
java -version
echo
echo JAVA_HOME=$JAVA_HOME
echo MW_HOME=$MW_HOME
echo
echo '****************************************************************************'
echo
#####

#
#  Correct Permissions & Move to Home Folder
#
chmod -R 775 $CFG_OUTPUT_BUNDLE_FOLDER
chown -R $ENV_REAL_USER:`id -gn ${ENV_REAL_USER}` $CFG_OUTPUT_BUNDLE_FOLDER
chmod 775 ${CFG_LOGFILE_PATH}
chown $ENV_REAL_USER:`id -gn ${ENV_REAL_USER}` ${CFG_LOGFILE_PATH}
sudo -u $ENV_REAL_USER mv -f $CFG_OUTPUT_BUNDLE_FOLDER $ENV_ORIGIN_FOLDER/
sudo -u $ENV_REAL_USER mv -f $CFG_LOGFILE_PATH $ENV_ORIGIN_FOLDER/
######

#
#  All done
#
echo
echo -e "\n**********************************************************************\n" > `tty`
echo -e "Verification tests completed.\n" > `tty`
echo -e "Please review ${ENV_ORIGIN_FOLDER}/${CFG_LOGFILE} for more details...\n" > `tty`
echo '********************************************************************************************' 
echo '******************************End of Report*************************************************'

#
#  Return to start folder
#
popd
#####

##### E O F #####