#!/bin/bash
####################################################################################
## 
## SCRIPT: installMQv8Fp0006.sh
##
## This script will install MQ fixpack FP0006 as detailed by IBM
##
###################################################################################
##
## Version  Date      Author      Description of change
## -------  --------  ----------  ------------------------------------------------
## 0.1      06072017  mmo275      initial version
##
###################################################################################

prog=installMQv8FP0006

###################################################################################
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCR=$(basename "${BASH_SOURCE[0]}")
THIS_SCRIPT=$DIR/$SCR
LOG_DIR=/var/log/mqInstaller
INI_FILE=${LOG_DIR}/${prog}.ini
LOG_FILE=${LOG_DIR}/${prog}.log.$(date +%Y%m%d_%H%M%S_%N)
#
mqUnzipped=/home/mqm/MQv8FP0006_unzipped/
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

###########################################################################
#
# Install MQ FP0006
#
###########################################################################
function installMQv8FP0006() {
    #
    eval `grep mqTargetDir ${INI_FILE}`
    if [[ -z ${mqTargetDir} ]] ; then
       log "Invalid parametere;mqTargetDir missing from ${INI_FILE}"
       exit 1
    fi
    mqUnzipped="${mqTargetDir}"
    #
    Log "Current MQSeries installed packages"
    Log "-----------------------------------"
    rpm -qa | grep MQSeries >> ${LOG_FILE}
    if [[ ! -d ${mqUnzipped} ]]; then
        Log "${mqUnzipped} is missing - unzip MQ fixpack FP0006 files using untarMQFP0006.sh"
        exit 1 
    fi
    cd ${mqUnzipped}
    #
    # Show any current install packages
    #
    Log "Current MQSeries installed packages"
    Log "-----------------------------------"
    rpm -qa | grep MQSeries >> ${LOG_FILE}
    #
    # Install MQ updates for what was installed 
    #
    #
    if ! rpm -ivh MQSeriesRuntime-U8006*.rpm MQSeriesServer-U8006*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesRuntime-U8006 / MQSeriesServer-U8006"
        exit 1
    fi
    #
    # All good, install the rest (minimum requirements)
    #
    if ! rpm -ivh MQSeriesClient-U8006*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesClient-U8006"
        exit 1
    fi
    if ! rpm -ivh MQSeriesSDK-U8006*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesSDK-U8006"
        exit 1
    fi
    # Dont need sampeles in production
    if ! rpm -ivh MQSeriesSamples-U8006*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesSamples-U8006"
        exit 1
    fi
    # Java / JRE must be installed before XRService
    # Java must be installed before JRE
    if ! rpm -ivh MQSeriesJava-U8006*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesJava-U8006"
        exit 1
    fi
    if ! rpm -ivh MQSeriesJRE-U8006*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesJRE-U8006"
        exit 1
    fi
    #
    if ! rpm -ivh MQSeriesXRService-U8006*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesXRService-U8006"
        exit 1
    fi
    if ! rpm -ivh MQSeriesMan-U8006*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesMan-U8006"
        exit 1
    fi
    if ! rpm -ivh MQSeriesGSKit-U8006*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesGSKit-U8006"
        exit 1
    fi
    if ! rpm -ivh MQSeriesAMS-U8006*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesAMS-U8006"
        exit 1
    fi
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
         exit
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
    installMQv8FP0006
    #
    Log "MQ FP0006 installation complete - please check logs in ${LOG_FILE}"
    exit 0

