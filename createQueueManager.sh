#!/bin/bash
####################################################################################
## 
## SCRIPT: createQueueManager.sh
##
## This script will create a queue manager and apply mqsc files
##
###################################################################################
##
## Version  Date      Author      Description of change
## -------  --------  ----------  ------------------------------------------------
## 0.1      06072017  mmo275      initial version
##
###################################################################################

prog=createQueueManager

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

function openPort() {
    #
    eval `grep qmPort ${INI_FILE}`
    if [[ -z ${qmPort} ]] ; then
       Log "Invalid parametere;qmPort is missing from ${INI_FILE}"
       exit 1
    fi
    #
    Log "Opening firewalls ports"
    systemctl status firewalld  >> ${LOG_FILE} 2>${LOG_FILE}
    firewall-cmd --get-active-zones  >> ${LOG_FILE} 2>${LOG_FILE} 
    firewall-cmd --zone=public --list-ports  >> ${LOG_FILE} 2>${LOG_FILE}
    firewall-cmd --zone=public --add-port=${qmPort}/tcp --permanent  >> ${LOG_FILE} 2>${LOG_FILE}
    firewall-cmd --reload  >> ${LOG_FILE} 2>${LOG_FILE}
    firewall-cmd --zone=public --list-ports  >> ${LOG_FILE} 2>${LOG_FILE}
    #
    RC=$?
}

########################################################################
#
# Create a queue manager
#
########################################################################
function createQM() {
    #
    # Create the Group and User if it doesn't exist
    #
    eval `grep queueManagerName ${INI_FILE}`
    if [[ -z ${queueManagerName} ]] ; then
       log "Invalid parametere;queueManagerName is missing from ${INI_FILE}"
       exit 1
    fi
    #
    Log "Creating queue manager ${queueManagerName} ...."
    #
    # Create a new queue manager
    #
    su - mqm -c "crtmqm -u DEAD.LETTER.QUEUE -lc -lp 5 -ls 3 -lf 65535 ${queueManagerName} "
    RC=$?
    if [ ${RC} != 0 ]; then
        Log "Error creating queue manager ${queueManagerName} environment - RC=${RC}"
        exit 1
    fi
    #
    su - mqm -c "strmqm ${queueManagerName}" >> ${LOG_FILE} 2>${LOG_FILE}
    RC=$?
    if [ ${RC} != 0 ]; then
        Log "Error starting queue manager ${queueManagerName} - RC=${RC}"
        exit 1
    fi
    #
    #su mqm -c "dspmq"
    #
    RC=$?
}
########################################################################
# 
# Create FULL repository queue managers 
#
########################################################################
function createFULLmqscFile() {
    #
    eval `grep mqscDir ${INI_FILE}`
    if [  -z ${mqscDir} ]; then
        Log "Invalid parameter;mqscDir is missing from ${INI_FILE}"
        exit 1
    fi
    if [ ! -d /home/mqm/${mqscDir} ]; then
        Log "Folder /home/mqm/${mqscDir} does not exist ... creating"
        su - mqm -c "mkdir /home/mqm/${mqscDir}"
    fi
    #
    eval `grep queueManagerName ${INI_FILE}`
    if [[ -z ${queueManagerName} ]] ; then
       log "Invalid parametere;queueManagerName is missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep DLQ ${INI_FILE}`
    if [ -z ${DLQ} ]; then
        Log "Invalid parameter;DLQ is missing from ${INI_FILE}"
        exit 1
    fi
    eval `grep clusterName ${INI_FILE}`
    if [ -z ${clusterName} ]; then
        Log "Invalid parameter;clusterName is missing from ${INI_FILE}"
        exit 1
    fi
    eval `grep remoteQueueManagerName ${INI_FILE}`
    if [ -z ${remoteQueueManagerName} ]; then
        Log "Invalid parameter;remoteQueueManagerName is missing from ${INI_FILE}"
        exit 1
    fi
    #
    eval `grep qmHost ${INI_FILE}`
    if [ -z ${qmHost} ]; then
        Log "Invalid parameter;qmHost is missing from ${INI_FILE}"
        exit 1
    fi
    eval `grep remoteHost ${INI_FILE}`
    if [ -z ${remoteHost} ]; then
        Log "Invalid parameter;remoteHost is missing from ${INI_FILE}"
        exit 1
    fi
    eval `grep remoteqmPort ${INI_FILE}`
    if [ -z ${remoteqmPort} ]; then
        Log "Invalid parameter;remoteqmPort is missing from ${INI_FILE}"
        exit 1
    fi
    #
    if [ -f /home/mqm/${mqscDir}/${queueManagerName}.mqsc ]; then
        echo "MQ configuration filel /home/mqm/${mqscDir}/${queueManagerName}.mqsc already exists ... and will be used"
        return 2    
    fi
    #
    Log "Creating new mqsc file in /home/mqm/${mqscDir}/${queueManagerName}.mqsc"
    su mqm -c "cat << EOFMQSC > /home/mqm/${mqscDir}/${queueManagerName}.mqsc
#
# auto created by createQueueManager.sh
#
alter qmgr deadq(${DLQ})
define ql(${DLQ}) like(SYSTEM.DEAD.LETTER.QUEUE) replace
define listener(TCP.${qmPort}) trptype(TCP) port(${qmPort}) control(QMGR) replace
start listener(TCP.${qmPort})
#
alter qmgr repos(${clusterName})
define channel(TO.${queueManagerName}) chltype(CLUSRCVR) trptype(TCP) conname('${qmHost}(${qmPort})') cluster(${clusterName}) replace
define channel(TO.${remoteQueueManagerName}) chltype(CLUSSDR) trptype(TCP) conname('${remoteHost}(${remoteqmPort})') cluster(${clusterName}) replace
#
# define user as mqadmin ...
#
define channel(SYSTEM.ADMIN.SVRCONN) chltype(SVRCONN)
set chlauth(SYSTEM.ADMIN.SVRCONN) type(BLOCKUSER) userlist('nobody')
set chlauth(SYSTEM.ADMIN.SVRCONN) type(USERMAP) CLNTUSER('mmo275') usersrc(MAP) mcauser('mqm')
#

EOFMQSC"
    #
    return 0
}

########################################################################
#
# Create PARTial repositoy queue manager
#
########################################################################
function createPARTmqscFile() {
    #
    eval `grep mqscDir ${INI_FILE}`
    if [  -z ${mqscDir} ]; then
        Log "Invalid parameter;mqscDir is missing from ${INI_FILE}"
        exit 1
    fi
    if [ ! -d /home/mqm/${mqscDir} ]; then
        Log "Folder /home/mqm/${mqscDir} does not exist ... creating"
        su - mqm -c "mkdir /home/mqm/${mqscDir}"
    fi
    #
    eval `grep queueManagerName ${INI_FILE}`
    if [[ -z ${queueManagerName} ]] ; then
       log "Invalid parametere;queueManagerName is missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep DLQ ${INI_FILE}`
    if [ -z ${DLQ} ]; then
        Log "Invalid parameter;DLQ is missing from ${INI_FILE}"
        exit 1
    fi
    eval `grep clusterName ${INI_FILE}`
    if [ -z ${clusterName} ]; then
        Log "Invalid parameter;clusterName is missing from ${INI_FILE}"
        exit 1
    fi
    eval `grep remoteQueueManagerName ${INI_FILE}`
    if [ -z ${remoteQueueManagerName} ]; then
        Log "Invalid parameter;remoteQueueManagerName is missing from ${INI_FILE}"
        exit 1
    fi
    #
    eval `grep qmHost ${INI_FILE}`
    if [ -z ${qmHost} ]; then
        Log "Invalid parameter;qmHost is missing from ${INI_FILE}"
        exit 1
    fi
    eval `grep remoteHost ${INI_FILE}`
    if [ -z ${remoteHost} ]; then
        Log "Invalid parameter;remoteHost is missing from ${INI_FILE}"
        exit 1
    fi
    eval `grep remoteqmPort ${INI_FILE}`
    if [ -z ${remoteqmPort} ]; then
        Log "Invalid parameter;remoteqmPort is missing from ${INI_FILE}"
        exit 1
    fi
    #
    #
    if [ -f /home/mqm/${mqscDir}/${queueManagerName}.mqsc ]; then
        echo "MQ configuration filel /home/mqm/${mqscDir}/${queueManagerName}.mqsc already exists ... and will be used"
        return 2
    fi
    #
    Log "Creating new mqsc file in /home/mqm/${mqscDir}/${queueManagerName}.mqsc"
    su mqm -c "cat << EOFMQSC > /home/mqm/${mqscDir}/${queueManagerName}.mqsc
#
# auto created by createQueueManager.sh
#
alter qmgr deadq(${DLQ})
define ql(${DLQ}) like(SYSTEM.DEAD.LETTER.QUEUE) replace
define listener(TCP.${qmPort}) trptype(TCP) port(${qmPort}) control(QMGR) replace
start listener(TCP.${qmPort})
#
define channel(TO.${queueManagerName}) chltype(CLUSRCVR) trptype(TCP) conname('${qmHost}(${qmPort})') cluster(${clusterName}) replace
define channel(TO.${remoteQueueManagerName}) chltype(CLUSSDR) trptype(TCP) conname('${remoteHost}(${remoteqmPort})') cluster(${clusterName}) replace
#
# define user as mqadmin
#
define channel(SYSTEM.ADMIN.SVRCONN) chltype(SVRCONN)
set chlauth(SYSTEM.ADMIN.SVRCONN) type(BLOCKUSER) userlist('nobody')
set chlauth(SYSTEM.ADMIN.SVRCONN) type(USERMAP) CLNTUSER('mmo275') usersrc(MAP) mcauser('mqm')
#
EOFMQSC"
    #
    return 0

}

########################################################################
#
# Apply mqsc parameters
#
########################################################################
function applyMQSCDetails() {
    #
    # format partitions
    #
    Log "Applying MQSC file /home/mqm/${mqscDir}/${queueManagerName}.mqsc  ..."
    #
    su - mqm -c "runmqsc ${queueManagerName} < /home/mqm/${mqscDir}/${queueManagerName}.mqsc" >> ${LOG_FILE}
    #
    return 0
}
###########################################################################
#
# Main section
#
###########################################################################
    echo "${prog} LOG_FILE=${LOG_FILE}"
    #
    # This script must run under mqm
    #
    RC=0
    #
    if (( $EUID != 0 ))
    then
         echo "${THIS_SCRIPT} must run as mqm"
         Log "${THIS_SCRIPT} must run as mqm"
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
    if  ! mkdir -p ${LOG_DIR}; then
        Log "${prog} cant make ${LOG_DIR}"
        exit 1
    fi
    #
    cp ${INI_FILE_PATH} ${INI_FILE}
    #
    # Open port
    #
    RC=0
    openPort
    if [ ${RC} != 0 ]; then
        Log "Error opening port ...."
        exit 1
    fi
    #
    # Create queue manager
    #
    createQM
    RC=$?
    if [ ${RC} != 0 ]; then
        Log "Error creating queue manager ...."
        exit 1
    fi
    #
    # Create MQSC
    #
    eval `grep qmType ${INI_FILE}`
    if [  -z ${qmType} ]; then
        Log "Invalid parameter;qmType is missing from ${INI_FILE}"
        exit 1
    fi
    if [ ${qmType} != "Full" ] && [ ${qmType} != "Part" ]; then
        echo "qmType must be Full or Part"
        exit 1
    fi
    #
    if [ ${qmType} == "Full" ]; then
        Log "Creating FULL repository queue manager mqsc file"
        createFULLmqscFile
    else
        Log "Creating PART repository queue manager mqsc file"
        createPARTmqscFile
    fi
    RC=$?
    if [ ${RC} != 0 ]; then
        if [ ${RC} != 2 ]; then
            Log "Error creating MQSC file ...."
            exit 1
        fi
        echo "mqsc file alreadys exist ...."
    fi
    #
    # Apply MQSC parameters
    #
    applyMQSCDetails
    RC=$?
    if [ ${RC} != 0 ]; then
        Log "Error applying MQSC details ...."
        exit 1
    fi
    #
    Log "createQueueManager complete - please check logs in ${LOG_FILE}"
    exit 0
