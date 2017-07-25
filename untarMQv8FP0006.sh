#!/bin/bash
####################################################################################
## 
## SCRIPT: untarMQv8FP0006.sh
##
## This script will un-tar the MQ fix pack 0006
##
###################################################################################
##
## Version  Date      Author      Description of change
## -------  --------  ----------  ------------------------------------------------
## 0.1      06072017  mmo275      initial version
##
###################################################################################

prog=untarMQv8FP0006

###################################################################################
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCR=$(basename "${BASH_SOURCE[0]}")
THIS_SCRIPT=$DIR/$SCR
INIFILE=$1
LOG_DIR=/var/log/mqInstaller
INI_FILE=${LOG_DIR}/${prog}.ini
LOG_FILE=${LOG_DIR}/${prog}.log.$(date +%Y%m%d_%H%M%S_%N)
#
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

#########################################################################
#
# Create a folder and un-tar the MQ fixpack binary files
#
#########################################################################
function UntarMQBinaries() {
    #
    Log "Untaring MQ fixpack binary files ...."
    #
    eval `grep mqSourceDir ${INI_FILE}`
    if [[ -z ${mqSourceDir} ]] ; then
       log "Invalid parametere;mqSourceDir missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep mqSourceFile ${INI_FILE}`
    if [[ -z ${mqSourceFile} ]] ; then
       log "Invalid parametere;mqSourceFile missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep mqTargetDir ${INI_FILE}`
    if [[ -z ${mqTargetDir} ]] ; then
       log "Invalid parametere;mqTargetDir missing from ${INI_FILE}"
       exit 1
    fi
    #
    if [[ ! -d ${mqTargetDir} ]]; then
        Log "${mqTargetDir} is missing ... creating "
        if ! su - mqm -c "mkdir -p ${mqTargetDir}"; then
            Log "Error creating ${mqTargetDir}"
            exit 1
        fi
    fi
    cd ${mqTargetDir}   
    #
    # Extract tar file
    #
    if ! tar -xvf ${mqSourceDir}/${mqSourceFile} >> ${LOG_FILE} 2>>${LOG_FILE}
       then
          Log "Error extracting tar file ${mqSourceDir}/${mqSourceFile}"
          exit 1
    fi
    chown mqm:mqm ${mqTargetDir}
    #
    #
    Log "Current MQSeries installed packages"
    Log "-----------------------------------"
    rpm -qa | grep MQSeries >> ${LOG_FILE}
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
    UntarMQBinaries
    #
    Log "MQ untarMQv8FP0006 complete - please check logs in ${LOG_FILE}"
    exit 0

