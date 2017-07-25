#!/bin/bash
####################################################################################
## 
## SCRIPT: partitionDisk.sh
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

prog=partitionDisk

###################################################################################
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCR=$(basename "${BASH_SOURCE[0]}")
THIS_SCRIPT=$DIR/$SCR
LOG_DIR=/var/log/mqInstaller
INI_FILE=${LOG_DIR}/${prog}.ini
LOG_FILE=${LOG_DIR}/${prog}.log.$(date +%Y%m%d_%H%M%S_%N)
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

########################################################################
#
# Partition the disk ...
#
########################################################################
function createPartitions() {
    #
    # Create the Group and User if it doesn't exist
    #
    eval `grep disk ${INI_FILE}`
    if [[ -z ${disk} ]] ; then
       log "Invalid parametere;disk missing from ${INI_FILE}"
       exit 1
    fi
    #
    eval `grep partSize1 ${INI_FILE}`
    if [[ -z ${partSize1} ]] ; then
       log "Invalid parametere;partDisk1 missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep partSize2 ${INI_FILE}`
    if [[ -z ${partSize2} ]] ; then
       log "Invalid parametere;partSize2 missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep partSize3 ${INI_FILE}`
    if [[ -z ${partSize3} ]] ; then
       log "Invalid parametere;partSize3 missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep partSize4 ${INI_FILE}`
    if [[ -z ${partSize4} ]] ; then
       log "Invalid parametere;partSize4 missing from ${INI_FILE}"
       exit 1
    fi
    #
    Log "Partitioning disk /dev/${disk} ...."
    #
    # Due to how Azure allocates disks, sdc could be already mounted ... if so, try the alternative
    #
    correctDisk=`lsblk --fs | grep ${disk} | grep /mnt | wc -l`
    if [[ ${correctDisk} != 0 ]];then
        origDisk=${disk}
        disk=${alternateDisk}
        correctDisk=`lsblk --fs | grep ${disk} | grep /mnt | wc -l`
        if [[ ${correctDisk} != 0 ]];then
            Log "Disks - ${origDisk}, ${alternateDisk} are already mounted ... please rectify"
            exit 1
        fi
    fi
    #
    p=`fdisk -l /dev/${disk} | grep ${disk} | wc -l`
    if [[ ${p} != 1 ]]; then
        echo "Existing partitions exist on /dev/${disk} ... please remove ..."
        Log "Existing partitions exist on /dev/${disk} ... please remove ..."
        exit 1
    fi
    #
    fdisk /dev/${disk} << EOF >> ${LOG_FILE}
p
n
p


${partSize1}
n
p


${partSize2}
n
p


${partSize3}
n
p

${partSize4}
w
EOF
    #
    RC=$?
    #
    fdisk -l >> ${LOG_FILE} 
}
########################################################################
#
# Format partitions
#
########################################################################
function formatPartitions() {
    #
    # format partitions
    #
    Log "Formatting partitions on disk ${disk} ..."
    #
    if ! mkfs.ext4 -L qmgrs /dev/${disk}1 >> ${LOG_FILE}; then 
        Log "Error formatting /dev/${disk}1 for qmgrs"
        exit 1
    fi
    if ! mkfs.ext4 -L log /dev/${disk}2 >> ${LOG_FILE}; then
        Log "Error formatting /dev/${disk}2 for log"
        exit 1
    fi
    if ! mkfs.ext4 -L errors /dev/${disk}3 >> ${LOG_FILE}; then
        Log "Error formatting /dev/${disk}3 for errors"
        exit 1
    fi
    if ! mkfs.ext4 -L trace /dev/${disk}4 >> ${LOG_FILE}; then
        Log "Error formatting /dev/${disk}4 for trace"
        exit 1
    fi
    #
}
########################################################################
#
# createCredentials
#
########################################################################
function createCredentials() {
    #
    eval `grep mqGroup ${INI_FILE}`
    if [ -z ${mqGroup} ]; then
       log "Invalid parametere;mqGroup missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep mqUser ${INI_FILE}`
    if [ -z ${mqUserId} ]; then
       log "Invalid parametere;mqUserId missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep mqPasswd ${INI_FILE}`
    if [ -z ${mqPasswd} ]; then
       log "Invalid parametere;mqPasswd missing from ${INI_FILE}"
       exit 1
    fi
    #
    #
    if groups ${mqGroup} >/dev/null 2>&1
    then
         Log "${mqGroup} group exists"
    else
         Log "${mqGroup} group does not exist - creating ${mqGroup} group"
         if ! groupadd ${mqGroup}
         then
              Log "Failed to create group ${mqGroup}"
              exit 1
         fi
    fi
    #
    # Add mqm user is missing
    #
    if id ${mqUserId} >/dev/null 2>&1
    then
         Log "${mqUserId} user exists"
    else
         Log "${mqUserId} user does not exit - creating ${mqUserId} user"
         if ! useradd -g ${mqGroup} ${mqUserId}
         then
              Log "Failed to create user ${mqUserId}"
              exit 1
         fi
         #
         # Set the password
         #
         if ! echo ${mqPasswd} | passwd ${mqUserId} --stdin
         then
              Log "Failed to set password for ${mqUserId}"
              exit 1
         fi
    fi
    #
    #
}
########################################################################
#
# Create MQ folders 
#
########################################################################
function createMQFolders() {
    #
    # Create MQ folders
    #
    if [[ ! -e /var/mqm ]]; then
        mkdir /var/mqm >> ${LOG_FILE}
        chown ${mqUserId}:${mqGroup} /var/mqm >> ${LOG_FILE}
    fi
    if [[ ! -e /var/mqm/qmgrs ]]; then
        mkdir -p /var/mqm/qmgrs >> ${LOG_FILE}
    fi
    if [[ ! -e /var/mqm/log ]]; then
        mkdir -p /var/mqm/log >> ${LOG_FILE}
    fi
    if [[ ! -e /var/mqm/errors ]]; then
        mkdir -p /var/mqm/errors >> ${LOG_FILE}
    fi
    if [[ ! -e /var/mqm/trace ]]; then
        mkdir -p /var/mqm/trace >> ${LOG_FILE}
    fi
    #
    #
}
###########################################################################
# 
# Mount File Systems
#
###########################################################################
function mountFileSystems() {
    #
    Log "Mounting MQ file systems"
    #
    if ! mount /dev/${disk}1 /var/mqm/qmgrs/ >> ${LOG_FILE}; then 
        Log "Error mounting /dev/${disk}1 /var/mqm/qmgrs/"
        exit 1
    fi
    if ! mount /dev/${disk}2 /var/mqm/log/ >> ${LOG_FILE}; then
        Log "Error mounting /dev/${disk}2 /var/mqm/log/"
        exit 1
    fi
    if ! mount /dev/${disk}3 /var/mqm/errors/ >> ${LOG_FILE}; then
        Log "Error mounting /dev/${disk}3 /var/mqm/errors/"
        exit 1
    fi
    if ! mount /dev/${disk}4 /var/mqm/trace/ >> ${LOG_FILE}; then
        Log "Error mounting /dev/${disk}4 /var/mqm/trace/"
        exit 1
    fi
    #
    # change owner
    #
    if ! chown ${mqUserId}:${mqGroup} /var/mqm/qmgrs >> ${LOG_FILE}; then
        Log "Error changing owner for /var/mqm/qmgrs"
        exit 1
    fi
    if ! chown ${mqUserId}:${mqGroup} /var/mqm/log >> ${LOG_FILE}; then
        Log "Error changing owner for /var/mqm/log"
        exit 1
    fi 
    if ! chown ${mqUserId}:${mqGroup} /var/mqm/errors >> ${LOG_FILE}; then
        Log "Error changing owner for /var/mqm/errors"
        exit 1
    fi
    if ! chown ${mqUserId}:${mqGroup} /var/mqm/trace >> ${LOG_FILE}; then
        Log "Error changing owner for /var/mqm/trace"
        exit 1

    fi
    #
    # add UUID for each partition to /etc/fstab
    #
    l_uuid=`lsblk --fs --output LABEL,UUID | grep -v '^[[:space:]]' | grep 'qmgrs' | awk -F ' ' '{print $2}'`
    if [ -z ${l_uuid} ] || ! echo ${l_uuid} | awk '{printf "UUID=%s /var/mqm/qmgrs/ \t  ext4 \t  defaults \t  1 2\n", $1}' >> /etc/fstab; then
        Log "Error insert ${l_uuid}/missing for qmgrs into /etc/fstab"
        exit 1
    fi
    l_uuid=`lsblk --fs --output LABEL,UUID | grep -v '^[[:space:]]' | grep 'log' | awk -F ' ' '{print $2}'`
    if [ -z ${l_uuid} ] || ! echo ${l_uuid} | awk '{printf "UUID=%s /var/mqm/log/ \t  ext4 \t  defaults \t  1 2\n", $1}' >> /etc/fstab; then
        Log "Error insert ${l_uuid}/missing for log into /etc/fstab"
        exit 1
    fi
    l_uuid=`lsblk --fs --output LABEL,UUID | grep -v '^[[:space:]]' | grep 'errors' | awk -F ' ' '{print $2}'`
    if [ -z ${l_uuid} ] || ! echo ${l_uuid} | awk '{printf "UUID=%s /var/mqm/errors/ \t  ext4 \t  defaults \t  1 2\n", $1}' >> /etc/fstab; then
        Log "Error insert ${l_uuid} for errors into /etc/fstab"
        exit 1
    fi
    l_uuid=`lsblk --fs --output LABEL,UUID | grep -v '^[[:space:]]' | grep 'trace' | awk -F ' ' '{print $2}'`
    if [ -z ${l_uuid} ] || ! echo ${l_uuid} | awk '{printf "UUID=%s /var/mqm/trace/ \t  ext4 \t  defaults \t  1 2\n", $1}' >> /etc/fstab; then
        Log "Error insert ${l_uuid} for trace into /etc/fstab"
        exit 1
    fi
    #  
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
    RC=0
    #
    if (( $EUID != 0 ))
    then
         echo "${THIS_SCRIPT} must run as root"
         Log "${THIS_SCRIPT} must run as root"
         exit 1
    fi
    Log "Starting ${prog}.sh"
    INI_FILE_PATH=$1
    if [[ -z ${INI_FILE_PATH} ]]; then
        Log "${prog} called with null parameter, should be the path to the driving ini_file"
        exit 1
    fi
    if [[ ! -f ${INI_FILE_PATH} ]]; then
        Log "${prog} ini_file cannot be found"
        exit 1
    fi
    if ! mkdir -p ${LOG_DIR}; then
        Log "${prog} cant make ${LOG_DIR}"
        exit 1
    fi
    #
    cp ${INI_FILE_PATH} ${INI_FILE}
    #
    # Create Partitions
    #
    createPartitions
    RC=$?
    #
    # Format partitions
    #
    if [ ${RC} == 0 ]; then
        Log "Format Partitions ..."
    	formatPartitions
        RC=$?
    fi
    #
    # create MQM credentials
    #
    if [ ${RC} == 0 ]; then
        Log "Creating credentials ..."
        createCredentials
        RC=$?
    fi
    #
    # create MQ Folders
    # 
    if [ ${RC} == 0 ]; then
        Log "Create MQ folders ..."
        createMQFolders
        RC=$?
    fi
    #
    # Mount file systems
    #
    if [ ${RC} == 0 ]; then
        Log "Mount MQ file systems ..."
        mountFileSystems
        RC=$?
    fi
    #
    Log "Disk Partition complete - please check logs in ${LOG_FILE}"
    exit ${RC}
