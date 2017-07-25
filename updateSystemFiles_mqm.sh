#!/bin/bash
####################################################################################
## 
## SCRIPT: updateSystemFiles_mqm.sh
##
## This script will update the system files for MQ as detailed by IBM
##
###################################################################################
##
## Version  Date      Author      Description of change
## -------  --------  ----------  ------------------------------------------------
## 0.1      06072017  mmo275      initial version
##
###################################################################################

prog=updateSystemFiles_mqm

###################################################################################
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCR=$(basename "${BASH_SOURCE[0]}")
THIS_SCRIPT=$DIR/$SCR
LOG_DIR=/var/log/mqInstaller
LOG_FILE=${LOG_DIR}/${prog}.log.$(date +%Y%m%d_%H%M%S_%N)
#
###################################################################################
#
# Log output to a file
#
###################################################################################
function Log() {
    if [[ ! -d ${LOG_DIR} ]]; then
       echo "${LOG_DIR} is missing"
       mkdir ${LOG_DIR} 
    fi
    
    if [[ -e ${LOG_DIR} ]]; then
        echo "$(date +%Y/%m/%d_%H:%M:%S.%N) $1" >> ${LOG_FILE}
    fi

}

#########################################################################
#
# Update the sysctl file if required
#
#########################################################################
function UpdateSysctl() {
    #
    # Update the Sysctl files in /usr/lib/sysctl.d/99-override-conf ....
    # /etc/sysctl.d/99-sysctl.conf
    #
    Log "Updating System file in /usr/lib/sysctl.d/99-override.conf ...."
    if [[ -e /usr/lib/sysctl.d/99-override.conf ]]; then
        Log " /usr/lib/sysctl.d/99-override.conf file exists ... re-creating it "
        rm -f /usr/lib/sysctl.d/99-override.conf
    fi
    touch /usr/lib/sysctl.d/99-override.conf
    #
    if [[ `grep "kernel.shmmni" /usr/lib/sysctl.d/99-override.conf | wc -l` -eq 0 ]]
    then
        Log "Adding kernal.shmmni = 4096 to /usr/lib/sysctl.d/99-override.conf"
        echo "kernel.shmmni = 4096"  >> /usr/lib/sysctl.d/99-override.conf
    else
        Log "kernel.shmmni already exists in /usr/lib/sysctl.d/99-override.conf"
    fi
    #
    if [[ `grep "kernel.shmall" /usr/lib/sysctl.d/99-override.conf | wc -l` -eq 0 ]]
    then
        Log "Adding kernel.shmall = 2097152 to /usr/lib/sysctl.d/99-override.conf"
        echo "kernel.shmall = 2097152"  >> /usr/lib/sysctl.d/99-override.conf
    else
        Log "kernel.shmall already exists in /usr/lib/sysctl.d/99-override.conf"
    fi
    #
    if [[ `grep "kernel.shmmax" /usr/lib/sysctl.d/99-override.conf | wc -l` -eq 0 ]]
    then
        Log "Adding kernel.shmmax = 268435456 to /usr/lib/sysctl.d/99-override.conf"
        echo "kernel.shmmax = 268435456"  >> /usr/lib/sysctl.d/99-override.conf
    else
        Log "kernel.shmmax already exists in /usr/lib/sysctl.d/99-override.conf"
    fi
    #
    if [[ `grep "kernel.sem" /usr/lib/sysctl.d/99-override.conf | wc -l` -eq 0 ]]
    then
        Log "Adding kernel.sem = 500 256000 250 1024 to /usr/lib/sysctl.d/99-override.conf"
        echo "kernel.sem = 500 256000 250 1024"  >> /usr/lib/sysctl.d/99-override.conf
    else
        Log "kernel.sem already exists in /usr/lib/sysctl.d/99-override.conf"
    fi
    #
    if [[ `grep "net.ipv4.tcp_keepalive_time" /usr/lib/sysctl.d/99-override.conf | wc -l` -eq 0 ]]
    then
        Log "Adding net.ipv4.tcp_keepalive_time = 300 to /usr/lib/sysctl.d/99-override.conf"
        echo "net.ipv4.tcp_keepalive_time = 300"  >> /usr/lib/sysctl.d/99-override.conf
    else
        Log "net.ipv4.tcp_keepalive_time already exists in /usr/lib/sysctl.d/99-override.conf"
    fi
    #
    if [[ `grep "fs.file-max" /usr/lib/sysctl.d/99-override.conf | wc -l` -eq 0 ]]
    then
        Log "Adding fs.file-max = 524288 to /usr/lib/sysctl.d/99-override.conf"
        echo "fs.file-max = 524288"  >> /usr/lib/sysctl.d/99-override.conf
    else
        Log "fs.file-max already exists in /usr/lib/sysctl.d/99-override.conf"
    fi
    #
    # Re-Load the sysctl parameters
    #
    if ! sysctl -p >/dev/null 2>&1; then
        Log "error applying sysctl in /usr/lib/sysctl.d/99-override.conf changes"
    fi
    #
}
###########################################################################
#
# Update Limits
#
###########################################################################
function UpdateLimits() {
    #
    # delete and re-create the conf file for mqm ..
    #
    Log "UpdatingLimits in /etc/security/limits.d/99-mqm-limits.conf ..."
    if [[ -e /etc/security/limits.d/99-mqm-limits.conf ]]; then
        rm -f /etc/security/limits.d/99-mqm-limits.conf
    fi
    touch /etc/security/limits.d/99-mqm-limits.conf 
    #
cat > /etc/security/limits.d/99-mqm-limits.conf << EOF
# Default limit for number of user's processes to prevent
# accidental fork bombs.
# See rhbz #432903 for reasoning.
# Auto created by updateSystemFiles_mqm.sh

mqm        hard    nofile    10240
mqm        soft    nofile    10240
EOF
     #
}

###########################################################################
#
# Main section
#
###########################################################################
    echo "${prog} LOG_FILE=${LOG_FILE}"
    #
    # This script must run under root
    #
    if (( $EUID != 0 ))
    then
         echo "${THIS_SCRIPT} must run as root"
         Log "${THIS_SCRIPT} must run as root"
         exit 1
    fi
    #
    UpdateSysctl
    UpdateLimits
    #
    Log "MQ updateSysctl complete - please check logs in ${LOG_FILE}"
    exit 0

