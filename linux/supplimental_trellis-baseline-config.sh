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
#      ON ANY THEORY OF LIABILITY, WHOS_NIC_NAMEER IN CONTRACT, STRICT LIABILITY, OR TORT
#      (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#      SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
#---------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------
# Script Name: supplimental_trellis_baseline-config.sh
# Description: Reconfigures a RHEL/CentOS/OEL 6.x/7.x host for Trellis(tm) Enterprise 
#              installation.
# Created: 2013/05/01
# Modified: 2020/03/23
# Authors: Michael Santangelo [FRM. NETPWR/AVOCENT/UK], Scott Donaldson [VERTIV/AVOCENT/UK]
# Contributors: Ray Daugherty [VERTIV/AVOCENT/UK], Mark Zagorski [VERTIV/AVOCENT/UK]
# Company: Vertiv Infrastructure Ltd.
# Group: Software Delovery, Services
# Email: global.services.delivery.development@vertivco.com
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
SCRIPT_VERSION="3.2.2"

CFG_OUTPUT_FOLDER="~${ENV_REAL_USER}"
CFG_OUTPUT_TMP_FOLDER="/tmp"
CFG_LOGFILE="trellis-precheck_${ENV_HOSTNAME}_`date +"%Y%m%d-%H%M"`.log"
CFG_LOGFILE_PATH="${CFG_OUTPUT_TMP_FOLDER}/${CFG_LOGFILE}"
CFG_OUTPUT_BUNDLE_FOLDER="${CFG_OUTPUT_TMP_FOLDER}/trellis_config"

BACKUP="/tmp/trellis-fix_backups"

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

##
#  Log Output
#
CFG_LOGFILE="trellis-base-line-config_${ENV_HOSTNAME}_`date +"%Y%m%d-%H%M"`.log"
CFG_LOGFILE_PATH="${CFG_OUTPUT_TMP_FOLDER}/${CFG_LOGFILE}"

exec > >(tee ${CFG_LOGFILE_PATH})

##  Find out if user wants problems found fixed automatically
echo -n "[Caution]: This script will make changes to the system, do you want to continue (y/n)?: "
read CONT
echo ""
if [ -z $CONT ]; then
  echo "Please indicate if you wish to continue"
  exit
elif [ $CONT = "y" -o $CONT = "yes" -o $CONT = "Y" -o $CONT = "YES" -o $CONT = "Yes" ]; then
  echo "System will be modified to meet Trellis requirements"
  echo ""
else
  exit
fi

function check_yum-repos() {
	##
	#  Check to be sure there is a yum repository available to install packages and such. 
	#  Will check 2 ways. First to be sure there is a repo at all, and secondly to see
	#  if the repo is available to be used
	#

	REPOLIST=`yum repolist -e 0 | egrep "^repolist: 0$" | wc -l`
	REPOCHECK=`yum repolist -e 0 -d 10 | grep "Repo-baseurl" | awk -F: '{ print $3}' > /tmp/repocheck`
	if [ $REPOLIST -eq 0 ]; then
	  echo "Yum repository exists, checking to see if it can be accessed"
	  echo ""
	  REPOCOUNT=`cat /tmp/repocheck | wc -l`
	  ERRORCOUNT=0
	  for REPOS in `cat /tmp/repocheck`; do
		REPOPATH=${REPOS}/repodata/repomd.xml
		ls $REPOPATH
		REPOERROR=$?
		if [ $REPOERROR -gt 0 ]; then
		  let ERRORCOUNT=ERRORCOUNT+1
		fi
	  done
	  if [ $ERRORCOUNT -ge $REPOCOUNT ]; then
		echo "[Error]: Yum repository/repositories not available, exiting"
		rm -f /tmp/repocheck
		return -1
	  else
		echo "[Info]: At least one yum repository is available for package installation, continuing."
	  fi
	else
	  echo "[Error]: Yum repository is not enabled on this machine, it is needed for package installations, exiting"
	  rm -f /tmp/repocheck
	  return -1
	fi
	rm -f /tmp/repocheck
	return 0
}

##  Find out if the server being installed is the front or back
echo ""
echo -n "Is this the front or back server? (f/b): "
read SIDE
if [ $SIDE = "b" -o $SIDE = "back" -o $SIDE = "B" -o $SIDE = "Back" -o $SIDE = "BACK" ]; then
  SIDE=b
elif [ $SIDE = "f" -o $SIDE = "front" -o $SIDE = "F" -o $SIDE = "Front" -o $SIDE = "FRONT" ]; then
  SIDE=f
else
  echo "Please respond with either [f]ront or [b]ack for the host server."
  exit
fi

##  Check Red Hat release version and set a number of variables based
##  on the version. Primitive way to check release version, but aside
##  from compiling a kernel -> release reference, the best way at this time.
# TODO: Replace with new version handling
echo "---CHECKING RED HAT ENTERPRISE LINUX VERSION---"
RELEASE_MAJOR=`(rpm -q --queryformat '%{RELEASE}' rpm | grep -o [[:digit:]]*\$)`

if [ -f '/etc/centos-release' ]; then
	RELEASE=`cat /etc/redhat-release | awk -F 'release ' '{print $2}' | awk -F '.' '{print($1 "." $2)}'`

	export RELEASE_DISTRO="CENTOS"
elif [ -f '/etc/redhat-release' ]; then
	RELEASE=`cat /etc/redhat-release | awk '{ print $7 }'`

	if grep -i "Oracle" /etc/redhat-release; then
		export RELEASE_DISTRO="ORACLE"
	else
		export RELEASE_DISTRO="REDHAT"
	fi
else
	echo "[Error]: Release information not found."
	export RELEASE_DISTRO="UNKNOWN"
fi
echo "[Debug]: Distribution is $RELEASE_DISTRO."


##  Get the IP and hostname of the server not being installed
if [ $SIDE = b ]; then
  HOST_BACK_FQDN=`hostname`
  HOST_BACK_NAME=`hostname | awk -F. '{ print $1 }'`

  if [ $RELEASE_MAJOR = "7" ]; then
        HOST_BACK_IP=`ip addr | grep "inet " | grep -v 127.0.0.1 | awk  -F ' ' '{ print $2 }' | awk -F '/' '{print $1}'`
  elif [ $RELEASE_MAJOR = "6" ]; then
        HOST_BACK_IP=`ifconfig | grep "inet addr" | grep -v 127.0.0.1 | awk  -F: '{ print $2 }' | awk '{ print $1 }'`
  else
    HOST_BACK_IP=''
  fi

  echo ""
  echo -n "What is the hostname of the front server (FQDN preferred)?: "
  read HOST_FRONT_FQDN
  HOST_FRONT_NAME=`echo "$HOST_FRONT_FQDN" | awk -F. '{ print $1 }'`
  echo ""
  echo "INFO: The name entered was $HOST_FRONT_FQDN, will try to verify the server by hostname"
  ping -c 1 $HOST_FRONT_FQDN
  if [ $? -eq "0" ]; then
    echo "[Info]: $HOST_FRONT_FQDN was pinged succesfully"
  else
    echo "[Warning]: $HOST_FRONT_FQDN was not pinged successfully. This could just mean that the DNS is not set up correctly yet, or there could be a problem with the name entered that will have to be fixed in the /etc/hosts file manually"
  fi
  echo ""
  echo -n "What is the IP address for the front server?: "
  read HOST_FRONT_IP
  echo""
  echo "INFO: The ip address entered was $HOST_FRONT_IP, will try to verify that the ip is active"
  ping -c 1 $HOST_FRONT_IP
  if [ $? -eq "0" ]; then
    echo "[Info]: $HOST_FRONT_IP was pinged succesfully"
  else
    echo "[Warning]: $HOST_FRONT_IP was not pinged successfully. This could just mean that there was a brief network blip, or the IP could have been entered wrong and will need to be fixed in the /etc/hosts file manually"
  fi
else
  HOST_FRONT_FQDN=`hostname -f`
  HOST_FRONT_NAME=`hostname | awk -F. '{ print $1 }'`

  if [ $RELEASE_MAJOR = "7" ]; then
	HOST_FRONT_IP=`ip addr | grep "inet " | grep -v 127.0.0.1 | awk  -F ' ' '{ print $2 }' | awk -F '/' '{print $1}'`
  elif [ $RELEASE_MAJOR = "6" ]; then
	HOST_FRONT_IP=`ifconfig | grep "inet addr" | grep -v 127.0.0.1 | awk  -F: '{ print $2 }' | awk '{ print $1 }'`
  else
    HOST_FRONT_IP=''
  fi
  
  echo ""
  echo -n "What is the hostname of the back server (FQDN preferred)?: "
  read HOST_BACK_FQDN
  HOST_BACK_NAME=`echo "$HOST_BACK_FQDN" | awk -F. '{ print $1 }'`
  echo ""
  echo "INFO: The name entered was $HOST_BACK_FQDN, will try to verify the server by hostname"
  ping -c 1 $HOST_BACK_FQDN
  if [ $? -eq "0" ]; then
    echo "SUCCESS: $HOST_BACK_FQDN was pinged succesfully"
  else
    echo "WARNING: $HOST_BACK_FQDN was not pinged successfully. This could just mean that the DNS is not set up correctly yet, or there could be a problem with the name entered that will have to be fixed in the /etc/hosts file manually"
  fi
  echo ""
  echo -n "What is the IP address for the back server?: "
  read HOST_BACK_IP
  echo""
  echo "INFO: The ip address entered was $HOST_BACK_IP, will try to verify that the ip is active"
  ping -c 1 $HOST_BACK_IP
  if [ $? -eq "0" ]; then
    echo "SUCCESS: $HOST_BACK_IP was pinged succesfully"
  else
    echo "WARNING: $HOST_BACK_IP was not pinged successfully. This could just mean that there was a brief network blip, or the IP could have been entered wrong and will need to be fixed in the /etc/hosts file manually"
  fi
fi

##
#  Making a directory where all changed config files can be backed up
#  from the original state in case somOS_NIC_NAMEing goes wrong or needs to be
#  changed back.
#
if [ -d $BACKUP ]; then
  DATENOW=`date +%m%d%H%M`
  tar -cf /tmp/trellis_backups_$DATENOW $BACKUP/*
  rm -rf $BACKUP/*
  chmod 755 $BACKUP
else
  mkdir $BACKUP
  chmod 755 $BACKUP
fi


# TODO: Add dynamic loading for Trellis Release & Supported OS
declare -a RELEASE_SUPPORTED=( "7.6" "7.5" "7.4" "7.3" "6.10" "6.9" "6.8" "6.7" )
declare -a RELEASE_DISTRO_SUPPORTED=( "CENTOS" "REDHAT" "ORACLE" )

if [[ " ${RELEASE_DISTRO_SUPPORTED[@]} " =~ " ${RELEASE_DISTRO} " ]];  then
	if [ ${RELEASE_DISTRO} == "ORACLE" ]; then
		echo "[Warning]: This distribution is not officially supported for client installations. Internal use only."
	fi

	echo "[Debug]: Release $RELEASE."

	if [[ " ${RELEASE_SUPPORTED[@]} " =~ " ${RELEASE} " ]];  then
	  echo "[Info]: Operating system release $RELEASE is supported for this installation"
	else
	  echo "[Info]: Operating system release $RELEASE is not supported for this installation, exiting"
	  exit
	fi
fi

##
#  Prepare Package Lists
#
# TODO: Cleanup Package Handling
if [ $RELEASE_MAJOR = "6" ]; then
  IPTABLES_RESULT="iptables: Firewall is not running."
  OS_PACKAGES_BASE="binutils compat-db compat-libcap1 compat-libstdc++-33 compat-libstdc++-33.i686 device-mapper-multipath dos2unix elfutils-libelf elfutils-libelf-devel emacs fipscheck gcc gcc-c++ glibc glibc.i686 glibc-devel glibc-devel.i686 kexec-tools ksh libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libsane-hpaio libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 libXext libXi libXtst make openmotif openssl.i686 redhat-lsb redhat-lsb-core.i686 sgpio sysstat unixODBC unixODBC-devel xinetd.x86_64 java-1.6.0-openjdk java-1.7.0-openjdk screen"
  OS_PACKAGES_DEBUG="bpftool iptraf nmap strace tuned tuned-utils-systemtap"
  OS_PACKAGES_REMOVE="aic94xxfirmware alsafirmware bind cronieanacron dhcpd dovecot httpd ivtvfirmware iwl*firmware iwl1000firmware iwl100firmware iwl105firmware iwl2000firmware iwl3160firmware iwl3945firmware iwl3945firmware iwl5150firmware iwl6000firmware iwl6000g2afirmware iwl6050firmware iwl7260firmware netsnmpd rsh rshserver rshserver squid telnet telnetserver tftpserver vsftpd wpa_supplicant ypbind ypserv"
elif [ $RELEASE_MAJOR = "7" ]; then
  IPTABLES_RESULT="iptables: Firewall is not running."
  OS_PACKAGES_BASE="binutils cloog compat-db compat-db47 compat-libcap1 compat-libstdc++-33 compat-libstdc++-33.i686 coreutils cpp device-mapper-multipath dos2unix elfutils-libelf elfutils-libelf-devel emacs fipscheck gcc gcc-c++ glibc glibc.i686 glibc-common glibc-devel glibc-devel.i686 hdparms initscripts kexec-tools ksh libXext libXi libXtst libaio libaio.i686 libaio-devel libaio-devel.i686 libgcc libgcc.i686 libsane-hpaio libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 lsof make mpfr mtools openmotif openssl openssl.i686 pax python-dmidecode redhat-lsb redhat-lsb-core.i686 screen sgpio sysstat unixODBC unixODBC-devel xinetd.x86_64 xorg-x11-server-utilsvi  xorg-x11-utils"
  OS_PACKAGES_DEBUG="bpftool iptraf nmap pcp-pmda-bcc pcp-pmda-bonding pcp-pmda-trace strace tuned tuned-utils-systemtap"
  OS_PACKAGES_REMOVE="aic94xxfirmware alsafirmware bind cronieanacron dhcpd dovecot httpd ivtvfirmware iwl*firmware iwl1000firmware iwl100firmware iwl105firmware iwl2000firmware iwl3160firmware iwl3945firmware iwl3945firmware iwl5150firmware iwl6000firmware iwl6000g2afirmware iwl6050firmware iwl7260firmware netsnmpd rsh rshserver rshserver squid telnet telnetserver tftpserver vsftpd wpa_supplicant ypbind ypserv"
  if [ $RELEASE_DISTRO = 'ORACLE' ]; then
	$OS_PACKAGES_BASE += " kmod-oracleasm oracleasm-support oracle-database-preinstall-18c"
  elif [ $RELEASE_DISTRO = 'CENTOS' ]; then
	$OS_PACKAGES_BASE += " "
  fi
fi

  
##
#  Check to be sure selinux is disabled
#  No real reason given as to why this needs to be disabled.
#  But, for now it's the requirement.
#
# TODO: Enable SELinux as Permissive
echo ""
echo "---CHECKING FOR SELINUX TO BE DISABLED---"
OS_CONFIG_SELINUX=`getenforce`
if [ $OS_CONFIG_SELINUX = 'Disabled' ]; then
  echo "[Info]: SELinux is $OS_CONFIG_SELINUX, this meets requirement REQ 4.4."
elif [ $OS_CONFIG_SELINUX = 'Permissive' ]; then
  echo "[Warning]: SELinux Permissive is funcionally correct however may produce failures in the official Trellis Precheck Utility."
  echo "[Info]: SELinux is $OS_CONFIG_SELINUX, this meets requirement REQ 4.4."
else
  echo "[Warning]: SELinux is $OS_CONFIG_SELINUX, this does not meets requirement REQ 4.4."
  echo "[Action]: Modifying SELinux configuration..."
  cp /etc/selinux/config $BACKUP/etc_selinux_config.bak
  sed -i 's@^\(SELINUX=\).*$@\1permissive@' /etc/selinux/config
  setenforce Permissive
  echo "[Info]: SELinux configuration updated."
fi

##  
#  Verify firewall is disabled.
#
#  TODO: Handle firewalld on RHEL 7.x
echo ""
echo "---CHECKING TO BE SURE IPTABLES IS TURNED OFF---"
if [ $RELEASE_MAJOR = '7' ]; then
	echo "[Error]: Unimplemented check for CentOS/Red Hat/Oracle Linux 7.x"
else
	IPTABLES=`service iptables status`
	if [ "$IPTABLES" != "$IPTABLES_RESULT" ]; then
	  echo "[Warning]: The firewall service iptables is running, this does not meet reqirement REQ 4.2."
	  echo "[Action]: Stopping & disabling iptables service..."
	  service iptables stop
	  chkconfig iptables off
	  echo "[Info]: The firewall service iptables has been stopped and disabled to meet reqirement REQ 4.2."
	else
	  echo "[Info]: The firewall service iptables is disabled and meets requirement REQ 4.2."
	fi
fi

##
#  Checking to see if NetworkManager is off. Trellis can run with it
#  but since we are now turning off X anyway, it is far easier to deal
#  with networking without it.
#
echo ""
echo "---CHECKING FOR NETWORK MANAGER---"
if [ $RELEASE_MAJOR = '7' ]; then
	echo "[Error]: Unimplemented check for CentOS/Red Hat/Oracle Linux 7.x"
else
	NETMAN=`service NetworkManager status`
	NETMAN_STAT=$?
	if [ "$NETMAN_STAT" -eq "0" ]; then
	  echo "NetworkManager service is running"
	  service NetworkManager stop
	  chkconfig NetworkManager off
	  echo "This problem has been fixed by running 'service NetworkManager stop && chkconfig NetworkManager off'"
	else
	  echo "NetworkManager service is not running, moving on"
	fi
fi

##
#  Check DHCP configuration and number of routable IP's
#  DHCP needs to be set to either static or none
#  and there can be only 1 routable IP
#
echo ""
echo "---CHECKING DHCP CONFIG AND NIC CONFIGURATION---"

if [ $RELEASE_MAJOR = "7" ]; then
	OS_NIC_NAME=`ip link | grep -v LOOPBACK | grep -v 'link/' | awk -F ': ' '{ print $2 }'`
	OS_NIC_QTY=`ip addr | grep "inet " | grep -v 127.0.0.1 | wc -l`
else
	OS_NIC_NAME=`ifconfig | awk '{ print $1 }'| head -1`
	OS_NIC_QTY=`ifconfig | grep "inet addr:" | grep -v "127.0.0.1" | wc -l`
fi

if [ $OS_NIC_QTY -gt 1 ]; then
  echo "[Error]: There are $OS_NIC_QTY Ethernet devices on this system with routeable IP's. Need to go back and reconfigure the system to have only 1 routable device. Findings and fixes from here forward may be incorrect with more than 1 OS_NIC_NAMEernet device present"
fi

OS_NIC_PROTO=`grep "BOOTPROTO" /etc/sysconfig/network-scripts/ifcfg-$OS_NIC_NAME | awk -F= '{ print $2 }' | sed 's@"@@g'`

if [ $OS_NIC_PROTO = dhcp ]; then
  echo "[Info]: Interface $OS_NIC_NAME is set to $OS_NIC_PROTO which does not meet Trellis requirements for static or none."
  echo "[Action]: Disabling DHCPD as required..."
  cp /etc/sysconfig/network-scripts/ifcfg-$OS_NIC_NAME $BACKUP/ifcfg-$OS_NIC_NAME.bak
  # TODO: Take dynamic values and inject into configuration file.
  sed -i "s@$OS_NIC_PROTO@none@g" /etc/sysconfig/network-scripts/ifcfg-$OS_NIC_NAME
  echo "[Info]: Interface $OS_NIC_NAME configuration file /etc/sysconfig/network-scripts/ifcfg-$OS_NIC_NAME updated."
  echo "[Warning]: Since bootOS_NIC_PROTO was set to DHCP, a permanent IP, Gateway, and Netmask may need to be put in to /etc/sysconfig/network-scripts/ifcfg-$OS_NIC_NAME to assure a static IP is, indeed, in place"
else
  echo "[Info]: Interface $OS_NIC_NAME is set to $OS_NIC_PROTO which passes Trellis requirements."
fi

##
#  Check that all required packages are installed
#  Engineering has a specific set of packages that must be installed
#  on all systems in order for Trellis installs to work. It looks like
#  mostly packages required for Oracle, but there may be other reasons
#  as well
#
echo ""
echo "---CHECKING FOR REQUIRED PACKAGES---"
for PACKAGE in $OS_PACKAGES_BASE; do
  echo "Checking for package: $PACKAGE"
  CHECK=`rpm -q $PACKAGE`
  if [ "$CHECK" = "package $PACKAGE is not installed" ]; then
    echo "[Warning]: Required $PACKAGE is not installed."
	echo "[Action]: Installing required package $PACKAGE from repository..."
    # TODO: Validated installation succeeded.
	yum -y install $PACKAGE
    echo "[Info]: Required package $PACKAGE has been installed."
  else
    echo "[Info]: Required package $PACKAGE is already installed."
  fi
done

# TODO: Make debug packages conditional based on script launch flags.
echo "---CHECKING FOR TROUBLESHOOTING PACKAGES---"
for PACKAGE in $OS_PACKAGES_DEBUG; do
  echo "Checking for package: $PACKAGE"
  CHECK=`rpm -q $PACKAGE`
  if [ "$CHECK" = "package $PACKAGE is not installed" ]; then
    echo "[Warning]: Required $PACKAGE is not installed."
	echo "[Action]: Installing troubleshooting package $PACKAGE from repository..."
	# TODO: Validated installation succeeded.
    yum -y install $PACKAGE
    echo "[Info]: Optional troubleshooting package $PACKAGE has been installed."
  else
    echo "[Info]: Optional troubleshooting package $PACKAGE is already installed."
  fi
done

##
#  Make sure package ant is not installed
#
# TODO: Make packages removal conditional based on script launch flags.
echo "---CHECKING FOR TROUBLESHOOTING PACKAGES---"
for PACKAGE in $OS_PACKAGES_REMOVE; do
  echo "Checking for package: $PACKAGE"
  CHECK=`rpm -q $PACKAGE`
  if [ "$CHECK" = "package $PACKAGE is not installed" ]; then
    echo "[Warning]: Installed $PACKAGE is black listed."
	echo "[Action]: Removing $PACKAGE from system..."
	# TODO: Validate removal succeeded.
    yum -y erase $PACKAGE
    echo "[Info]: Blacklisted package $PACKAGE has been removed."
  else
    echo "[Info]: Blacklisted package $PACKAGE is not present."
  fi
done


##  
#  Verify the oracle user and groups exist
#  Open question on whOS_NIC_NAMEer the oracle user has to be uid 500
#  or if that's just a general assumption, but not a requirement.
#  For now just going to make sure oracle user exists along with
#  the dba and oinstall groups
#
echo ""
echo "---CHECKING FOR REQUIRED ORACLE USER AND GROUPS---"
AUTH_GROUP_DBA=`cat /etc/group | grep "^dba:" | wc -l`
AUTH_GROUP_OINSTALL=`cat /etc/group | grep "^oinstall:" | wc -l` 
AUTH_USER_ORACLE=`cat /etc/passwd | grep "^oracle:" | wc -l`
##  Checking for dba group
if [ $AUTH_GROUP_DBA -eq 0 ]; then
  echo "[Warning]: User group dba does not exists, this does not meet requirement REQ 1.51"
  echo "[Action]: Creating user group dba..."
  groupadd dba
  echo "[Info]: Group dba created."
else
  echo "[Info]: User group dba already exists."
fi 
## Checking for oinstall group
if [ $AUTH_GROUP_OINSTALL -eq 0 ]; then
  echo "[Warning]: User group oinstall does not exists, this does not meet requirement REQ 1.51"
  echo "[Action]: Creating user group oinstall..."
  groupadd oinstall
  echo "[Info]: Group oinstall created."
else
  echo "[Info]: User group oinstall already exists."
fi
##  Checking for oracle user
if [ $AUTH_USER_ORACLE -eq 0 ]; then
  echo "[Warning]: User account oracle does not exists, this does not meet requirement REQ 1.51"
  echo "[Action]: Creating user account oracle..."
  # TODO: Remove hard coded password.
  # TODO: Support pre-hashed password.
  useradd -g oinstall -G dba -p 39q7S4TMKPZRNfmZNsmz oracle
  echo "[Info]: User account oracle has been created."
else
  echo "[Info]: User account oracle already exists."
fi

##  Set up the oracle users .bash_profile
##  This will not work if the oracle user does not exist
echo ""
echo "---SET UP THE ORACLE .BASH_PROFILE---"
  cp ~oracle/.bash_profile $BACKUP/bash_profile.bak

  for VAR in MW_HOME ORACLE_HOME ORACLE_SID PATH HISTCONTROL HISTSIZE HISTFILE PS1 "set" "Added per Trellis"; do
    sed -i "/$VAR/d" ~oracle/.bash_profile
  done

	# TODO: Update paths for Trellis 5.x
  cat >> ~oracle/.bash_profile << EOF

## Added per Trellis install requirements
set /home/oracle/.bash_profile

MW_HOME=/u01/fm/11.1.1.7/
ORACLE_HOME=/u01/app/oracle/product/12.1.0
ORACLE_SID=orcl
export MW_HOME ORACLE_HOME ORACLE_SID

export HISTCONTROL=ignoreboth
export HISTSIZE=5000
export HISTFILE=/home/oracle/.bash_history
EOF
##  This line needs to be separate because it can't resolve the 
##  variables, they need to be put in to the .bash_profile as variables
##  to be resolved there
  echo 'export PATH=$ORACLE_HOME/bin:$PATH' >> ~oracle/.bash_profile
  echo "oracle user's .bash_profile set up correctly, moving on"

##  Set up the umask for oracle user in .bashrc
##  umask needs to be set at 000 or 002 in order to allow all of the
##  files oracle writes to have the correct permissions. If it is not
##  set, an automatic check done during the Trellis install may fail 
##  due to bad permissions
echo ""
echo "---SETTING UP THE ORACLE .BASHRC---"
  cp /home/oracle/.bashrc $BACKUP/bashrc.bak

  for VAR in 'umask'; do
    sed -i /$VAR/d ~oracle/.bashrc
  done

  cat >> ~oracle/.bashrc << EOF

## Added per Trellis install requirements
umask 0002
EOF
echo "umask set up correctly in oracle's .bashrc file, moving on"

##  Check to be sure the correct directories exist with the correct permissions
echo ""
echo "---CHECKING FOR DIRECTORIES AND PERMISSIONS---"
for DIR in /u01 /u02 /u03 /u05 /u99 /u99/OracleAgent; do
  ls $DIR
  if [ $? -eq 0 ]; then
    echo "$DIR exists, making sure permissions are correct"
	chown -h oracle:oinstall $DIR
    chown -R oracle:oinstall $DIR
    chmod -R 775 $DIR
  else
    echo "$DIR does not exist on the system"
    mkdir -p $DIR
    chown -R oracle:oinstall $DIR
    chmod -R 775 $DIR
    echo "This problem has been fixed and directory $DIR has been created with the proper owners and permissions"
  fi
done

##  Install guide says this line needs to be added to the login file
##  so we're going to get it in there
echo ""
echo "---CHECKING THE LOGIN FILE---"
LOG_CHECK=`grep "/lib64/security/pam_limits.so" /etc/pam.d/login | wc -l`
if [ $LOG_CHECK -eq 0 ]; then
  echo "The required line is not in /etc/pam.d/login, adding it"
  cp /etc/pam.d/login $BACKUP/login.bak

  cat >> /etc/pam.d/login << EOF
session    required     /lib64/security/pam_limits.so
EOF
  echo "The problem has been fixed and the line has been added to the /etc/pam.d/login file"
else
  echo "File /etc/pam.d/login has the correct line in it, moving on"
fi

##  Create the /etc/oraInst.loc file
echo ""
echo "---CHECKING FOR ORAINST.LOC FILE---"
ls /etc/oraInst.loc
if [ $? -eq 0 ]; then
  echo "/etc/oraInst.loc file already exists on this server. Setting up the oraInst.loc configuration to meet Trellis requirements"
  cp /etc/oraInst.loc $BACKUP/oraInst.bak
  cat > /etc/oraInst.loc << EOF
inventory_loc=/u01/app/oraInventory
inst_group=oinstall
EOF
  echo "This problem has been fixed and the /etc/oraInst.loc file has been modified to meet Trellis requirements"
else
  echo "/etc/oraInst.loc file does not exist on this server. Setting up the oraInst.loc configuration to meet Trellis requirements"
  cat > /etc/oraInst.loc << EOF
inventory_loc=/u01/app/oraInventory
inst_group=oinstall
EOF
  echo "This problem has been fixed and the /etc/oraInst.loc file has been modified to meet Trellis requirements"
fi  

##  Check the /etc/oratab file to be sure it exists and has
##  the right permissions
echo ""
echo "---CHECKING THE /ETC/ORATAB FILE---"
ls /etc/oratab
if [ $? -eq 0 ]; then
  echo "File /etc/oratab exists, making sure permissions are correct"
  chown oracle:oinstall /etc/oratab
  chmod 664 /etc/oratab
else
  echo "File /etc/oratab does not exist on the server. Setting up the oratab configuration to meet Trellis requirements"
  touch /etc/oratab
  chown oracle:oinstall /etc/oratab
  chmod 664 /etc/oratab
  echo "This problem has been fixed and /etc/oratab has been created with the proper owners and permissions"
fi

##  Check for the nodemanager service under /etc/xinetd.d
echo ""
echo "--CHECKING ON THE NODEMANAGER SERVICE---"
ls /etc/xinetd.d/nodemanager
if [ $? -eq 0 ]; then
  echo "File exists on this server. Setting up the nodemanager configuration to meet Trellis requirements"
  cp /etc/xinetd.d/nodemanager $BACKUP/nodemanager.bak
  cat > /etc/xinetd.d/nodemanager << EOF
# default: off
# description: nodemanager as a service
# Running as to work around an issue where the ulimits for the user are not getting set.
# using su - forces the ulimit via PAM
service nodemgrsvc
{
        type            = UNLISTED
        disable         = yes
        socket_type     = stream
        OS_NIC_PROTOcol        = tcp
        wait            = yes
        user            = root
        port            = 5556
        flags           = NOLIBWRAP
        log_on_success  += DURATION HOST USERID
        server          = /bin/su
        server_args     = - oracle -c /u01/trellis/startNodeManager.sh
}
EOF
    echo "This problem has been fixed and /etc/xinetd.d/nodemanager file has been created with the correct configuration and permissions"
else
  echo "File does not exist on the server. Setting up the nodemanager configuration to meet Trellis requirements"
  touch /etc/xinetd.d/nodemanager
  cat > /etc/xinetd.d/nodemanager << EOF
# default: off
# description: nodemanager as a service
# Running as to work around an issue where the ulimits for the user are not getting set.
# using su - forces the ulimit via PAM
service nodemgrsvc
{
        type            = UNLISTED
        disable         = yes
        socket_type     = stream
        OS_NIC_PROTOcol        = tcp
        wait            = yes
        user            = root
        port            = 5556
        flags           = NOLIBWRAP
        log_on_success  += DURATION HOST USERID
        server          = /bin/su
        server_args     = - oracle -c /u01/trellis/startNodeManager.sh
}
EOF
    echo "This problem has been fixed and /etc/xinetd.d/nodemanager file has been created with the correct configuration and permissions"
fi

##  Check for sudo permissions for the oracle user
echo ""
echo "---CHECKING ORACLE SUDO PERMISSIONS---"
echo "Adding Trellis specific oracle sudo permissions to the bottom of the /etc/sudoers file"
cp /etc/sudoers $BACKUP/sudoers.bak
sed -i /^oracle.*$/d /etc/sudoers
cat >> /etc/sudoers << EOF

## Added for Trellis configuration purposes
oracle          ALL=                    NOPASSWD: /etc/init.d/trellis
oracle          ALL=                    NOPASSWD: /u03/root/disable_escalation.sh
oracle          ALL=                    NOPASSWD: /u03/root/enable_nodemanager.sh
oracle          ALL=                    NOPASSWD: /u03/root/ohs_enable_chroot.sh
oracle          ALL=                    NOPASSWD: /u03/root/postinstall_env_setup.sh
oracle          ALL=                    NOPASSWD: /u03/root/preinstall_env_setup.sh
oracle          ALL=                    NOPASSWD: /u03/root/sli_install.bin
EOF
  echo "[Info]: This problem has been fixed and /etc/sudoers has been updated to have proper escalations for the oracle user"

##  Setting up limits in /etc/security/limits.conf
##  Need to set various hard and soft limits for oracle
echo ""
echo "---CHECKING LIMITS.CONF SETTINGS---"
echo "Adding Trellis specific oracle limits to the bottom of the /etc/security/limits.conf file"
cp /etc/security/limits.conf $BACKUP/limits.conf.bak
sed -i /^oracle/d /etc/security/limits.conf
sed -i '/# End of file/d' /etc/security/limits.conf
cat >> /etc/security/limits.conf << EOF

##  Added per Trellis requirements
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft stack 10240

# End of file
EOF
echo "This problem has been fixed and /etc/security/limits.conf has been updated to have proper limits set for the oracle user"

##  Set up oracle kernel tunings
##  Need to check for values at, or above the minimums provided by
##  engineering. This would be easier if we could just replace, but
##  if some of these values are set higher by default, engineering 
##  wants that kept.
echo ""
echo "---CHECKING FOR ORACLE KERNEL TUNING---"
echo "Adding Trellis specific oracle tunings to the bottom of the /etc/sysctl.conf file"
cp /etc/sysctl.conf $BACKUP/sysctl.conf.bak
##  First the ones we can just delete and replace for exact values
for SYSCTL in kernel.sem net.ipv4.ip_local_port_range; do
  sed -i /^$SYSCTL/d /etc/sysctl.conf
done
cat >> /etc/sysctl.conf << EOF

##  Added/modified for Trellis installs
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65535
EOF
##  Now the ones we'll need to do some comparing with. I can't think 
##  of a more elegant way to do this at this time, so I'll just do brute
##  force compares for now.
max_nr=1048576
MAX_NR=`grep "fs.aio-max-nr" /etc/sysctl.conf | awk '{ print $NF }'`
if [ -z $MAX_NR ]; then
  echo "fs.aio-max-nr does not exist in /etc/sysctl.conf, adding..."
  echo "fs.aio-max-nr = $max_nr" >> /etc/sysctl.conf
elif [ $MAX_NR -ge $max_nr ]; then
  echo "fs.aio-max-nr value is $MAX_NR, which is greater than or equal to the required value of $max_nr for Trellis, no changes are needed" 
else
  echo "fs.aio-max-nr value is $MAX_NR, which is less than the required value of $max_nr for Trellis, fixing..."
  sed -i "s@^\(fs.aio-max-nr = \).*@\1$max_nr@g" /etc/sysctl.conf
fi  
file_max=6815744
FILE_MAX=`grep "fs.file-max" /etc/sysctl.conf | awk '{ print $NF }'`
if [ -z $FILE_MAX ]; then
  echo "fs.file-max does not exist in /etc/sysctl.conf, adding..."
  echo "fs.file-max = $file_max" >> /etc/sysctl.conf
elif [ $FILE_MAX -ge $file_max ]; then
  echo "fs.file-max value is $FILE_MAX, which is greater than or equal to the required value of $file_max for Trellis, no changes are needed" 
else
  echo "fs.file-max value is $FILE_MAX, which is less than the required value of $file_max for Trellis, fixing..."
  sed -i "s@^\(fs.file-max = \).*@\1$file_max@g" /etc/sysctl.conf
fi
kernel_shmall=2097152
KERNEL_SHMALL=`grep "kernel.shmall" /etc/sysctl.conf | awk '{ print $NF }'`
if [ -z $KERNEL_SHMALL ]; then
  echo "kernel.shmall does not exist in /etc/sysctl.conf, adding..."
  echo "kernel.shmall = $kernel_shmall" >> /etc/sysctl.conf
elif [ $KERNEL_SHMALL -ge $kernel_shmall ]; then
  echo "kernel.shmall value is $KERNEL_SHMALL, which is greater than or equal to the required value of $kernel_shmall for Trellis, no changes are needed" 
else
  echo "kernel.shmall value is $KERNEL_SHMALL, which is less than the required value of $kernel_shmall for Trellis, fixing..."
  sed -i "s@^\(kernel.shmall = \).*@\1$kernel_shmall@g" /etc/sysctl.conf
fi
kernel_shmmax=536870912
KERNEL_SHMMAX=`grep "kernel.shmmax" /etc/sysctl.conf | awk '{ print $NF }'`
if [ -z $KERNEL_SHMMAX ]; then
  echo "kernel.shmmax does not exist in /etc/sysctl.conf, adding..."
  echo "kernel.shmmax = $kernel_shmmax" >> /etc/sysctl.conf
elif [ $KERNEL_SHMMAX -ge $kernel_shmmax ]; then
  echo "kernel.shmmax value is $KERNEL_SHMMAX, which is greater than or equal to the required value of $kernel_shmmax for Trellis, no changes are needed" 
else
  echo "kernel.shmmax value is $KERNEL_SHMMAX, which is less than the required value of $kernel_shmmax for Trellis, fixing..."
  sed -i "s@^\(kernel.shmmax = \).*@\1$kernel_shmmax@g" /etc/sysctl.conf
fi
kernel_shmmni=4096
KERNEL_SHMMNI=`grep "kernel.shmmni" /etc/sysctl.conf | awk '{ print $NF }'`
if [ -z $KERNEL_SHMMNI ]; then
  echo "kernel.shmmni does not exist in /etc/sysctl.conf, adding..."
  echo "kernel.shmmni = $kernel_shmmni" >> /etc/sysctl.conf
elif [ $KERNEL_SHMMNI -ge $kernel_shmmni ]; then
  echo "kernel.shmmni value is $KERNEL_SHMMNI, which is greater than or equal to the required value of $kernel_shmmni for Trellis, no changes are needed" 
else
  echo "kernel.shmmax value is $KERNEL_SHMMNI, which is less than the required value of $kernel_shmmni for Trellis, fixing..."
  sed -i "s@^\(kernel.shmmni = \).*@\1$kernel_shmmni@g" /etc/sysctl.conf
fi
rmem_default=262144
RMEM_DEFAULT=`grep "net.core.rmem_default" /etc/sysctl.conf | awk '{ print $NF }'`
if [ -z $RMEM_DEFAULT ]; then
  echo "net.core.rmem_default does not exist in /etc/sysctl.conf, adding..."
  echo "net.core.rmem_default = $rmem_default" >> /etc/sysctl.conf
elif [ $RMEM_DEFAULT -ge $rmem_default ]; then
  echo "net.core.rmem_default value is $RMEM_DEFAULT, which is greater than or equal to the required value of $rmem_default for Trellis, no changes are needed" 
else
  echo "net.core.rmem_default value is $RMEM_DEFAULT, which is less than the required value of $rmem_default for Trellis, fixing..."
  sed -i "s@^\(net.core.rmem_default = \).*@\1$rmem_default@g" /etc/sysctl.conf
fi
rmem_max=4194304
RMEM_MAX=`grep "net.core.rmem_max" /etc/sysctl.conf | awk '{ print $NF }'`
if [ -z $RMEM_MAX ]; then
  echo "net.core.rmem_max does not exist in /etc/sysctl.conf, adding..."
  echo "net.core.rmem_max = $rmem_max" >> /etc/sysctl.conf
elif [ $RMEM_MAX -ge $rmem_max ]; then
  echo "net.core.rmem_max value is $RMEM_MAX, which is greater than or equal to the required value of $rmem_max for Trellis, no changes are needed" 
else
  echo "net.core.rmem_max value is $RMEM_MAX, which is less than the required value of $rmem_max for Trellis, fixing..."
  sed -i "s@^\(net.core.rmem_max = \).*@\1$rmem_max@g" /etc/sysctl.conf
fi
wmem_default=262144
WMEM_DEFAULT=`grep "net.core.wmem_default" /etc/sysctl.conf | awk '{ print $NF }'`
if [ -z $WMEM_DEFAULT ]; then
  echo "net.core.wmem_default does not exist in /etc/sysctl.conf, adding..."
  echo "net.core.wmem_default = $wmem_default" >> /etc/sysctl.conf
elif [ $WMEM_DEFAULT -ge $wmem_default ]; then
  echo "net.core.wmem_default value is $WMEM_DEFAULT, which is greater than or equal to the required value of $wmem_default for Trellis, no changes are needed" 
else
  echo "net.core.wmem_default value is $WMEM_DEFAULT, which is less than the required value of $wmem_default for Trellis, fixing..."
  sed -i "s@^\(net.core.wmem_default = \).*@\1$wmem_default@g" /etc/sysctl.conf
fi
wmem_max=1048586
WMEM_MAX=`grep "net.core.wmem_max" /etc/sysctl.conf | awk '{ print $NF }'`
if [ -z $WMEM_MAX ]; then
  echo "net.core.wmem_max does not exist in /etc/sysctl.conf, adding..."
  echo "net.core.wmem_max = $wmem_max" >> /etc/sysctl.conf
elif [ $WMEM_MAX -ge $wmem_max ]; then
  echo "net.core.wmem_max value is $WMEM_MAX, which is greater than or equal to the required value of $wmem_max for Trellis, no changes are needed" 
else
  echo "net.core.wmem_max value is $WMEM_MAX, which is less than the required value of $wmem_max for Trellis, fixing..."
  sed -i "s@^\(net.core.wmem_max = \).*@\1$wmem_max@g" /etc/sysctl.conf
fi
wakeup_threshold=1024
WAKEUP_THRESHOLD=`grep "kernel.random.write_wakeup_threshold" /etc/sysctl.conf | awk '{ print $NF }'`
if [ -z $WAKEUP_THRESHOLD ]; then
  echo "kernel.random.write_wakeup_threshold does not exist in /etc/sysctl.conf, adding..."
  echo "kernel.random.write_wakeup_threshold = 1024" >> /etc/sysctl.conf
elif [ $WAKEUP_THRESHOLD -ge $wakeup_threshold ]; then
  echo "kernel.random.write_wakeup_threshold value is $WAKEUP_THRESHOLD, which is greater than or equal to the required value of $wakeup_threshold for Trellis, no changes are needed"
else
  echo "kernel.random.write_wakeup_threshold value is $WAKEUP_THRESHOLD, which is less than the required value of $wakeup_threshold for Trellis, fixing..."
  sed -i "s@^\(kernel.random.write_wakeup_threshold = \).*@\1$wakeup_threshold@g" /etc/sysctl.conf
fi

##  Set up the /etc/hosts file
##  Need to set up the /etc/hosts file to account for various aliases
##  that engineering has in place for the front and back server to talk
##  to one another
echo ""
echo "---SETTING UP THE HOSTS FILE---"
echo "Adding Trellis specific entries to the /etc/hosts file."
cp /etc/hosts $BACKUP/hosts.bak
for VAR in trellis-front trellis-back "Added entries for Trellis"; do
  sed -i "/$VAR/d" /etc/hosts
done
echo "Adding Trellis specific entries to the bottom of the /etc/hosts file"
cat >> /etc/hosts << EOF

##  Added entries for Trellis
$HOST_FRONT_IP 	$HOST_FRONT_FQDN $HOST_FRONT_NAME 
$HOST_BACK_IP 	$HOST_BACK_FQDN $HOST_BACK_NAME

$HOST_FRONT_IP 	weblogic-admin Presentation-Operational-internal Presentation-Analytical-internal BAM-internal SOA-Operational-internal SOA-Analytical-internal MPS-proxy-internal CEP-Engine-internal OHS-Balancer-internal OSB-Server-internal Authentication-internal Authorization-internal-local Flexera-Server-internal vip-external 3rdparty-vip-external vip-internal MPS-proxy-external Search-internal Reporting-internal trellis-front trellis-platform
$HOST_BACK_IP 	MDS-Database-internal CDM-Database-internal TSD-Database-internal TSD-Database-external Authorization-internal-admin trellis-back
EOF

##  If user asked to fix problems, will fix possible bug found with symlinks and ssl
##  Bug prevents the license server from working.
# TODO: Disabel this fix
#echo ""
#echo "---CHECKING FOR LICENSE SERVER SYMLINKS---"
#if [ $RELEASE = "5.9" ]; then
#  echo "This fix not needed for version $RELEASE, moving on"
#else
#  echo "Creating the directory /usr/lib/licenseserver and populating it with the correct symlinks before installation"
#  mkdir -p /usr/lib/licenseserver
#  ln -s /usr/lib/libcrypto.so.10 /usr/lib/licenseserver/libcrypto.so.1.0.0
#  ln -s /usr/lib/libssl.so.10 /usr/lib/licenseserver/libssl.so.1.0.0
#  echo "Directory and symlinks created"
#fi


##  rngd service needs to be turned on and configured
# TODO: Check for presence of TPM, disable if TPM is entropy source.
# TODO: Check if physical host and make fix optional.
# TODO: Add warning that this is an unsafe change.
echo ""
echo "---CHECKING ON RNGD CONFIGURATION---"
if [ $RELEASE_MAJOR = '7' ]; then
	if [ `cat /sys/devices/virtual/misc/hw_random/rng_available | wc -l` -gt 0 ]; then
		OS_CONFIG_RNG=`cat /sys/devices/virtual/misc/hw_random/rng_available`
		if [ `cat /sys/devices/virtual/misc/hw_random/rng_available | grep -i tpm | wc -l` -gt 0 ]; then
			echo "[Info]: Trusted Processing Module (TPM) provides entropy, rngtools must be disabled."
			if [ `cat /sys/devices/virtual/misc/hw_random/rng_current | grep -i tpm | wc -l` -eq 0 ]; then
				echo "[Warning]: Current entropy source is inactive, this is likely due to conflict with rngtools."
				echo "[Action]: Disabling rngtools..."
				systemctl disable rngd
				systemctl enable tcsd
				echo "[Warning]: Host must be restarted for change to take effect due to rngtools and tcsd compatability issues."
			else
				echo "[Info]: Kernel is presently using TPM, no action is required."
			fi
		else
			echo "[Info]: Non-Trusted Processing Module (TPM) hardware entropy source detected, this should be used."
			systemctl enable rngd
			systemctl disable tcsd
		fi
	fi
else
	echo "[Error]: Unimplemented."
	# TODO: Fix TPM detection.
	#sed -i '/EXTRAOPTIONS/d' /etc/sysconfig/rngd
	#echo 'EXTRAOPTIONS="-i -r /dev/urandom -o /dev/random -b"' >> /etc/sysconfig/rngd
	#chkconfig --levels 345 rngd on
	#RNGD_STAT=`service rngd status`
	#if [ $RNGD_STAT = "rngd is stopped" ]; then
	#  echo "rngd service is stopped, starting..."
	#  service rngd start
	#else
	#  echo "rngd service is running as expected"
	#fi
fi

echo""
echo "[Info]: Trellis Enterprise baseline configuraiton script has completed. Please reboot before attempting installation of Trellis Enterprise."

popd


