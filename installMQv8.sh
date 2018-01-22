#!/bin/bash
####################################################################################
## 
## SCRIPT: installMQv8.sh
##
## This script will install MQ as detailed by IBM
##
###################################################################################
##
## Version  Date      Author      Description of change
## -------  --------  ----------  ------------------------------------------------
## 0.1      06072017  xxxxxx      initial version
##
###################################################################################

prog=installMQv8

###################################################################################
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCR=$(basename "${BASH_SOURCE[0]}")
THIS_SCRIPT=$DIR/$SCR
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

###########################################################################
#
# Install MQ
#
###########################################################################
function installMQv8() {
    #
    eval `grep mqTargetDir ${INI_FILE}`
    if [[ -z ${mqTargetDir} ]] ; then
       log "Invalid parametere;mqTargetDir missing from ${INI_FILE}"
       exit 1
    fi
    mqUnzipped="${mqTargetDir}/MQServer/"    
    #
    Log "Current MQSeries installed packages"
    Log "-----------------------------------"
    rpm -qa | grep MQSeries >> ${LOG_FILE}
    if [[ ! -d ${mqUnzipped} ]]; then
        Log "${mqUnzipped} is missing - unzip MQ files using untarMQ.sh"
        exit 1 
    fi
    cd ${mqUnzipped}
    ./mqlicense.sh -accept >> ${LOG_FILE}
    #
    # Show any current install packages
    #
    Log "Current MQSeries installed packages"
    Log "-----------------------------------"
    rpm -qa | grep MQSeries >> ${LOG_FILE}
    #
    # Install the Runtime and Server
    #
    if ! rpm -ivh MQSeriesRuntime-*.rpm MQSeriesServer-*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesRuntime-* or MQSeriesServer-*"
        exit 1
    fi
    #
    # Run mqconfig to ensure all is good before continuing
    #
    Log "/opt/mqm/bin/mqcongig ..."
    su mqm -c "/opt/mqm/bin/mqconfig" >> ${LOG_FILE}
    FAILED=$(su mqm -c "/opt/mqm/bin/mqconfig" | grep FAIL | wc -l)
    if [ "$FAILED" -ne "0" ]
    then
         Log "System parameters are in error"
         exit 1
    fi
    #
    # All good, install the rest (minimum requirements)
    #
    if ! rpm -ivh MQSeriesClient-*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesClient-*"
        exit 1
    fi
    if ! rpm -ivh MQSeriesSDK-*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesClient-*"
        exit 1
    fi
    if ! rpm -ivh MQSeriesSamples-*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesClient-*"
        exit 1
    fi
    # Java / JRE must be installed before XRService
    # Java m,ust be installed before JRE
    if ! rpm -ivh MQSeriesJava-*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesJava-*"
        exit 1
    fi
    if ! rpm -ivh MQSeriesJRE-*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesClient-*"
        exit 1
    fi
    #
    if ! rpm -ivh MQSeriesXRService-*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesXRService-*"
        exit 1
    fi
    if ! rpm -ivh MQSeriesMan-*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesMan-*"
        exit 1
    fi
    if ! rpm -ivh MQSeriesGSKit-*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesGSKit-*"
        exit 1
    fi
    if ! rpm -ivh MQSeriesAMS-*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}; then
        Log "Error installing MQSeriesAMS-*"
        exit 1
    fi
    #
    # Dont bother with MQExplorer on Linux
    # rpm -ivh MQSeriesExplorer-*.rpm >> ${LOG_FILE} 2>>${LOG_FILE}
    #
    # Update the mqm profile to enable the MQ commands ...
    #
    mqmDir=/home/mqm
    pathLine=$(cat ${mqmDir}/.bash_profile | grep PATH= -n)
    if [ -z ${pathLine} ]; then
        echo "Error 'Path=' variable not found in ${mqmDir}/.bash_profile"
        exit 1
    fi
    lineNo=$(echo ${pathLine} | awk -F ":" '{print $1}')
    lineNo=$( expr ${lineNo} - 1 )
    sed -i "${lineNo}i# Auto inserted by installMQ.sh script\n. /opt/mqm/bin/setmqenv -s " ${mqmDir}/.bash_profile

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
    installMQv8
    #
    Log "MQ installation complete - please check logs in ${LOG_FILE}"
    exit 0

