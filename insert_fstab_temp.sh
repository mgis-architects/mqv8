#!/bin/bash
####################################################################################
## 
## SCRIPT: insert_fstab_test.sh
##
## This script will be partition disk 'sdc'
##
###################################################################################
##
## Version  Date      Author      Description of change
## -------  --------  ----------  ------------------------------------------------
## 0.1      06072017  mmo275      initial version
##
###################################################################################

prog=fstab

###################################################################################
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCR=$(basename "${BASH_SOURCE[0]}")
THIS_SCRIPT=$DIR/$SCR
INIFILE=$1
LOG_DIR=/var/log/mqInstaller
LOG_FILE=${LOG_DIR}/${prog}.log.$(date +%Y%m%d_%H%M%S_%N)
#
mqGroup=mqm
mqUserId=mqm
mqPasswd=Passw0rd!
#
disk=sdc
#
###################################################################################
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

###########################################################################
# Mount File Systems
#
###########################################################################
function mountFileSystems() {
    #
    l_uuid=`lsblk --fs --output LABEL,UUID | grep -v '^[[:space:]]' | grep 'qmgrs' | awk -F ' ' '{print $2}'`
    if ! echo ${l_uuid} | awk '{printf "UUID=%s /dev/mqm/qmgrs/ \t  ext4 \t  defaults \t  1 2\n", $1}' >> /etc/fstab; then
        Log "Error insert ${l_uuid} for qmgrs into /etc/fstab"
        exit
    fi
    l_uuid=`lsblk --fs --output LABEL,UUID | grep -v '^[[:space:]]' | grep 'log' | awk -F ' ' '{print $2}'`
    if ! echo ${l_uuid} | awk '{printf "UUID=%s /dev/mqm/log/ \t  ext4 \t  defaults \t  1 2\n", $1}' >> /etc/fstab; then
        Log "Error insert ${l_uuid} for log into /etc/fstab"
        exit
    fi
    l_uuid=`lsblk --fs --output LABEL,UUID | grep -v '^[[:space:]]' | grep 'errors' | awk -F ' ' '{print $2}'`
    if ! echo ${l_uuid} | awk '{printf "UUID=%s /dev/mqm/errors/ \t  ext4 \t  defaults \t  1 2\n", $1}' >> /etc/fstab; then
        Log "Error insert ${l_uuid} for errors into /etc/fstab"
        exit
    fi
    l_uuid=`lsblk --fs --output LABEL,UUID | grep -v '^[[:space:]]' | grep 'trace' | awk -F ' ' '{print $2}'`
    if ! echo ${l_uuid} | awk '{printf "UUID=%s /dev/mqm/trace/ \t  ext4 \t  defaults \t  1 2\n", $1}' >> /etc/fstab; then
        Log "Error insert ${l_uuid} for trace into /etc/fstab"
        exit
    fi

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
         exit
    fi
    #
    # Mount 
    #
    Log "Mount MQ file systems ..."
    mountFileSystems
    #
    Log "Disk Partition complete - please check logs in ${LOG_FILE}"

