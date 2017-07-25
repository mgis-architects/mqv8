#!/bin/bash
####################################################################################
## 
## SCRIPT: createMQv8_FP0006Zip.sh
##
## This script will zip MQv8 / fix pack FP0006 together 
##
###################################################################################
##
## Version  Date      Author      Description of change
## -------  --------  ----------  ------------------------------------------------
## 0.1      06072017  mmo275      initial version
##
###################################################################################

prog=createMQv8_FP0006Zip

###################################################################################
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCR=$(basename "${BASH_SOURCE[0]}")
THIS_SCRIPT=$DIR/$SCR
#INIFILE=$1
LOG_DIR=/var/log/mqInstaller
LOG_FILE=${LOG_DIR}/${prog}.log.$(date +%Y%m%d_%H%M%S_%N)
#
# sudo ./createMQv8_FP0006Zip.sh /home/mmo275 /home/mmo275
#
mqDefaultDir=$(pwd)
mqSourceDir=
mqSourceFile=WS_MQ_V8.0.0.4_LINUX_ON_X86_64_IM.tar.gz
mqFPFile=8.0.0-WS-MQ-LinuxX64-FP0006.tar.gz
mqFPDir=
mqOutZip=MQv8FP0006.zip
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
# Zip files
#
#########################################################################
function zipMQBinaries() {
    #
    local l_mqSourceDir
    local l_mqFPDir
    #
    l_mqSourceDir=$1
    l_mqFPDir=$2
    #
    Log "Zip MQ binary files ...."
    #
    Log "Checking if ${l_mqSourceDir}/${mqSourceFile} exists ..." 
    if [ ! -e ${l_mqSourceDir}/${mqSourceFile} ]; then
        Log "${l_mqSourceDir}/${mqSourceFile} is missing."
        exit 1
    fi
    Log "MQ file ${l_mqSourceDir}/${mqSourceFile} exists ..." 
    #
    Log "Checking is ${l_mqFPDir}/${mqFPFile} exists ..."
    if [ ! -e ${l_mqFPDir}/${mqFPFile} ]; then
        Log "${l_mqFPDir}/${mqFPFile} is missing - fixpack file will not be added"
    else
        Log "Fix Pack ${l_MQFPDir}/${mqFPFile} will be added ..."
    fi
    #
    Log "Checking if a previous version of ${mqOutZip} exists ..."
    if [ -e ${DIR}/${mqOutZip} ]; then
       Log "${mqOutZip} exists and will be removed ..."
       rm -r ${DIR}/${mqOutZip}
       Log "${mqOutZip} deleted"
    fi
    #
    cd ${l_mqSourceDir}
    if ! zip -9 ${DIR}/${mqOutZip} ${mqSourceFile}; then
       Log "Error adding ${mqSourceFile} file to zip file ${mqOutZip}"
       exit 1
    fi
    #
    if [ ! -e ${l_mqFPDir}/${mqFPFile} ]; then
        Log "${l_mqFPDir}/${mqFPFile} file will not be added"
    else
        cd ${l_mqFPDir}
        if ! zip -9 -u ${DIR}/${mqOutZip} ${mqFPFile}; then
            Log "Error adding ${mqFPFile} file to zip file ${mqOutZip}"
        fi
    fi
    # 
    # add scripts here
    # unzipMQv8_FP0006.sh    - 15/07/2017 ** Installer script
    # partitaionDisk.sh      - 15/07/2017 -- partition disk
    # untarMQv8.sh           - 16/07/2017 -- untar MQ files
    # untarMQv8FP0006.sh     - 16/07/2017 -- untar MQ fixpack 6
    # updateSystemFiles_mqm  - 17/07/2017 -- update system files
    # installMQv8            - 17/07/2017 -- install MQ
    # installMQv8FP0006      - 17/07/2017 -- Install MQ fixpack 6
    #
    l_shellScripts="partitionDisk.sh untarMQv8.sh untarMQv8FP0006.sh updateSystemFiles_mqm.sh"
    l_shellScripts="${l_shellScripts} installMQv8.sh installMQv8FP0006.sh createQueueManager.sh" 
    cd ${mqDefaultDir}
    if ! zip -9 -u ${DIR}/${mqOutZip} ${l_shellScripts}; then
        Log "Error adding ./parameters/*.ini files to zip file ${mqOutZip}"
        exit 1
    fi
    #
    cd ${mqDefaultDir}
    if ! zip -9 -u ${DIR}/${mqOutZip} ./parameters/*.ini; then
        Log "Error adding ./parameters/*.ini files to zip file ${mqOutZip}"
        exit 1
    fi
    #
}

###########################################################################
#
# md5sum
#
###########################################################################
function createMD5Sum() {
    #
    Log "Creating md5 sum value for ${DIR}${mqOutZip}"
    cd ${mqDefaultDir}
    if [ ! -e ${mqOutZip} ]; then
       Log "${mqOutZip} does not exist ..."
       exit 1
    fi
    md5sum ${mqOutZip} >> ${mqOutZip}.md5
    #
    Log "${mqOutZip} file created"
    #
    if ! unzip -l ${DIR}/${mqOutZip}; then
       Log "Error listing files in ${DIR}/${mqOutZip}"
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
         exit -1
    fi
    #
    mqSourceDir=$1
    mqFPDir=$2
    if [ -z ${mqSourceDir} ];then
        Log "MQ SourceDir is missing, using ${mqDefaultDir}"
        mqSourceDir=${mqDefaultDir} 
    fi
    if [ -z ${mqFPDir} ]; then
        Log "MQ FixPackDir is missing, using ${mqDefaultDir}"
        mqFPDir=${mqDefaultDir}
    fi
    if [ ! -d ${mqSourceDir} ]; then
        Log "Source directory ${mqSourceDir} does not exist."
        exit -1
    fi
    if [ ! -d ${mqFPDir} ]; then
        Log "Fixpack directory ${mqFPDir} does not exist."
        exit -1
    fi
    #
    zipMQBinaries ${mqSourceDir} ${mqFPDir}
    createMD5Sum 
    #
    Log "MQv8 unzip / installer complete - please check logs in ${LOG_FILE}"
    exit 0

