#!/bin/bash
####################################################################################
## 
## SCRIPT: unzipMQv8_FP0006.sh
##
## This script will unzip MQv8 zip file
##
###################################################################################
##
## Version  Date      Author      Description of change
## -------  --------  ----------  ------------------------------------------------
## 0.1      06072017  mmo275      initial version
##
###################################################################################

prog=unzipMQv8_FP0006

###################################################################################
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCR=$(basename "${BASH_SOURCE[0]}")
THIS_SCRIPT=$DIR/$SCR
INIFILE=$1
LOG_DIR=/var/log/mqInstaller
INI_FILE=${LOG_DIR}/${prog}.ini
LOG_FILE=${LOG_DIR}/${prog}.log.$(date +%Y%m%d_%H%M%S_%N)
#
# ./unzipMQv8_FP0006.sh MQv8FP0006.zip /home/mqadmin/ /home/mqadmin/ TSTQFD01

###################################################################################
#
# Log output to a file
#
###################################################################################
function Log() {
    if [[ ! -d ${LOG_DIR} ]]; then
       echo "${LOG_DIR} is missing - creating ${LOG_DIR}"
       mkdir ${LOG_DIR} 
    fi
    
    if [[ -e ${LOG_DIR} ]]; then
        echo "$(date +%Y/%m/%d_%H:%M:%S.%N) $1" >> ${LOG_FILE}
    fi

}

###########################################################################
#
# Unzip zip file
#
###########################################################################
function unzipMQv8File() {
    #
    Log "Unzipping file ${MQv8zipFile}"
    mqMQv8zipFile=$1
    mqSourceDir=$2
    mqTargetDir=$3
    QM=$4
    #
    if [ -z ${mqMQv8zipFile} ];then
        Log "Invalid parameters;mqMQv8zipFile is missing "
        exit 1
    fi 
    if [ -z ${mqSourceDir} ];then
        Log "Invalid parameters;mqSourceDir is missing "
        exit 1
    fi
    if [ -z ${mqTargetDir} ];then
        Log "Invalid parameters;mqTargetDir is missing "
        exit 1
    fi
    if [ -z ${QM} ];then
        Log "Invalid parameters;QM is missing "
        exit 1
    fi
    #
    if [[ ! -d ${mqTargetDir} ]];then
        Log "Target directory ${mqTartgetDir} does not exist, select an existing directory"
        exit 1
    fi
    if [ ! -e ${mqSourceDir}/${mqMQv8zipFile} ];then
        Log "MQ zip file ${mqSourceDir}/${mqMQv8zipFile} does not exist"
        exit 1
    fi
    #
    if ! cd ${mqTargetDir}; then
        Log "Error changing directory to ${mqTargetDir}"
        exit 1
    fi
    if ! unzip ${mqSourceDir}/${mqMQv8zipFile}; then
        Log "Error unzipping file ${mqSourceDir}/${mqMQv8zipFile} into ${mqTartgetDir}"
        exit 1
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
         exit 1
    fi
    #
    Log "Starting ${prog}.sh"
    Log "starting unzipMQvFile ...."
    ./checkForMQZipFile.sh ./parameters/checkForMQZipFile.ini
    RC=$?
    if [ ${RC} != 0 ]; then
        Log "MD5 zip file mismatch returned"
        exit 1
    fi
    ./unzipMQv8File "$@"
    RC=$?
    Log "unzipMQv8File finished ... RC=${RC}"
    if ! cd ${mqTargetDir}; then
        Log "Error changing directory to ${mqTargetDir}"
        exit 1
    fi
    #
    if [ ${RC} == 0 ]; then
        Log "starting partitionDisk ..."
        ./allocateStorage.sh ./parameters/allocateStorage.ini
        RC=$?
        Log "allocateStorage finished ... RC=${RC}"
    fi
    #
    if [ ${RC} == 0 ]; then
        Log "starting untarMQv8 ..."
        ./untarMQv8.sh ./parameters/untarMQv8.ini
        RC=$?
        Log "untarMQv8 finished ... RC=${RC}"
    fi
    #
    if [ ${RC} == 0 ]; then
        Log "starting untarMQv8FP0006 ..."
        ./untarMQv8FP0006.sh ./parameters/untarMQv8FP0006.ini
        RC=$?
        Log "untarMQv8FP0006 finished ... RC=${RC}"
    fi
    #
    if [ ${RC} == 0 ]; then
        Log "starting updateSystemFiles_mqm ..."
        ./updateSystemFiles_mqm.sh
        RC=$?
        Log "updateSystemFiles_mqm finished ... RC=${RC}"
    fi
    #
    if [ ${RC} == 0 ]; then
        Log "starting installMQv8 ..."
        ./installMQv8.sh ./parameters/untarMQv8.ini
        RC=$?
        Log "installMQv8 finished ... RC=${RC}"
    fi
    if [ ${RC} == 0 ]; then
        Log "starting installMQv8FP0006 ..."
        ./installMQv8FP0006.sh ./parameters/untarMQv8FP0006.ini
        RC=$?
        Log "installMQv8FP0006 finished ... RC=${RC}"
    fi
    #
    # Create queue manager
    #
    Log "checking for file parameters/${QM}.ini"
    if [[ ! -f parameters/${QM}.ini ]]; then
        echo "${prog} Queue Manager ini file cannot be found"
        exit 1
    fi
    if [ ${RC} == 0 ]; then
        Log "Starting createQueueManager"
        ./createQueueManager.sh ./parameters/${QM}.ini
        RC=$?
        Log "createQueueManager finsished ... RC=${RC}"
    fi
    #
    Log "unzipMQv8_FP0006 complete - please check logs in ${LOG_FILE}"
    #
    exit 0

