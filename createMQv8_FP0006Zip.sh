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
LOG_DIR=/var/log/mqInstaller
INI_FILE=${LOG_DIR}/${prog}.ini
LOG_FILE=${LOG_DIR}/${prog}.log.$(date +%Y%m%d_%H%M%S_%N)
#
# sudo ./createMQv8_FP0006Zip.sh ./parameters/createMQv8_FP0006Zip.ini
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
    eval `grep mqSourceFile ${INI_FILE}`
    if [[ -z ${mqSourceFile} ]]; then
        Log "mqSourceFile is missing from ${INI_FILE}"
        exit 1
    fi
    if [[ ! -f ${l_mqSourceDir}/${mqSourceFile} ]]; then
        Log "${l_mqSourceDir}/${mqSourceFile} cannot be found"
        exit 1
    fi
    #
    Log "Zip MQ binary files ...."
    echo "MQ source DIR = ${l_mqSourceDir}"
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
    # allocateStorage.sh     - 27/07/2017 -- partition disk and allocate storage
    # untarMQv8.sh           - 16/07/2017 -- untar MQ files
    # untarMQv8FP0006.sh     - 16/07/2017 -- untar MQ fixpack 6
    # updateSystemFiles_mqm  - 17/07/2017 -- update system files
    # installMQv8            - 17/07/2017 -- install MQ
    # installMQv8FP0006      - 17/07/2017 -- Install MQ fixpack 6
    #
    l_shellScripts="allocateStorage.sh untarMQv8.sh untarMQv8FP0006.sh updateSystemFiles_mqm.sh"
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
    rm -rf ${DIR}/${mqOutZip}.md5 
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
    eval `grep mqSourceDir ${INI_FILE}`
    eval `grep mqFPDir ${INI_FILE}`
    #mqSourceDir=$1
    #mqFPDir=$2
    if [ -z ${mqSourceDir} ];then
        Log "MQ SourceDir is missing, using ${mqDefaultDir}"
        exit 1
    fi
    if [ -z ${mqFPDir} ]; then
        Log "MQ FixPackDir is missing and will not be added to the output zip file"
    fi
    if [ ! -d ${mqSourceDir} ]; then
        Log "Source directory ${mqSourceDir} does not exist."
        exit 1
    fi
    if [ -z ${mqFPDir} ]; then
        if [ ! -d ${mqFPDir} ]; then
            Log "Fixpack directory ${mqFPDir} does not exist."
            exit 1
        fi
    fi
    #
    zipMQBinaries ${mqSourceDir} ${mqFPDir}
    createMD5Sum 
    #
    Log "MQv8 unzip / installer complete - please check logs in ${LOG_FILE}"
    exit 0

