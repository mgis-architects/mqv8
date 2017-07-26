#!/bin/bash
####################################################################################
## 
## SCRIPT: checkForMQZipFile.sh
##
## This script will be check that the MQzip file exists 
##
###################################################################################
##
## Version  Date      Author      Description of change
## -------  --------  ----------  ------------------------------------------------
## 0.1      06072017  mmo275      initial version
##
###################################################################################

prog=checkForMQZipFile

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
# Check to see if the MQ zip file exists
#
########################################################################
function checkForZipFile() {
    #
    # Check for the zip file
    #
    eval `grep zipFile ${INI_FILE}`
    if [[ -z ${zipFile} ]] ; then
       Log "Invalid parametere;zipFile missing from ${INI_FILE}"
       exit 1
    fi
    #
    md5File="${zipFile}.md5"
    loopCount=1
    while [ ${loopCount} -le 6 ]
    do
        Log "Checking for file ${DIR}/${md5File}"
        if [ ! -e ${DIR}/${md5File} ]; then
            Log "md5 file ... ${DIR}/${md5File} does not yet exist ...."
            Log "Count ${loopCount} : sleeping for 10 seconds ..."
            sleep 10
        else
            loopCount=10
        fi
        loopCount=$(( ${loopCount}+1 ))
    done
    #
    # Loop finished, check again and action ...
    #
    if [ ! -e ${DIR}/${md5File} ]; then
        Log "File ${DIR}/${md5File} is missing ... "
        exit 1
    fi
    #
    # Check for zip file 
    #
    md5Original=$( cat ${DIR}/${md5File} | grep ${zipFile} | awk -F " " '{print $1}' )
    loopCount=1
    while [ ${loopCount} -le 6 ]
    do
        Log "Checking for file ${DIR}/${zipFile}"
        if [ ! -e ${DIR}/${zipFile} ]; then
            Log "zip file ... ${DIR}/${zipFile} does not yet exist ...."
            Log "Count ${loopCount} : sleeping for 10 seconds ..."
            sleep 10
        else
            if ! md5ForFile=$( md5sum ${DIR}/${zipFile} | awk -F " " '{print $1}' ); then
                Log "Error generating file md5 sha value"
                exit 1
            fi
            if [ ${md5Original} != ${md5ForFile} ]; then
                Log "MD5 shar values mismatch ... continuing to loop"
            else
                Log "MD5 sha values match ... continuing with install"
                loopCount=10
            fi
        fi
        loopCount=$(( ${loopCount}+1 ))
    done
    if [ ${loopCount} -le 10 ]; then
        Log "${DIR}/${zipFile} had issues being sent to server .... exiting"
        exit 1
    fi
    #
    # Loop finished, check again and action ...
    #
    if [ ! -e ${DIR}/${zipFile} ]; then
        Log "File ${DIR}/${zipFile} is missing ... "
        exit 1
    fi
    #
    RC=$?
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
    # Check for the file
    #
    checkForZipFile
    RC=$?
    #
    Log "MD5 Sha complete - please check logs in ${LOG_FILE}"
    exit ${RC}
