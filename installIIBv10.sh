#!/bin/bash
####################################################################################
## 
## SCRIPT: installIIBv10.sh
##
## This script will install IIB as detailed by IBM
##
###################################################################################
##
## Version  Date      Author      Description of change
## -------  --------  ----------  ------------------------------------------------
## 0.1      06072017  mmo275      initial version
##
###################################################################################

prog=installIIBv10

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
# Check for MQ ... as we need MQ
#
###########################################################################
function checkForMQ() {
    #
    if ! id mqm; then
        Log "MQ user 'mqm' does not exist on this server, install MQ before installing IIB"
        exit 1
    fi
    #
    if [ ! -e /opt/mqm/bin/setmqenv ]; then
        Log "MQ does not exist on this server, install MQ before installing IIB"
        exit 1
    fi
}

###########################################################################
#
# Unzip the LinuxIIBv10.zip file
#
###########################################################################
function unzipLinuxIIBv10() {
    #
    eval `grep iibLinuxzipFile ${INI_FILE}`
    eval `grep iibSourceDir ${INI_FILE}`
    eval `grep iibTargetDir ${INI_FILE}`
    #
    if [ -z ${iibLinuxzipFile} ];then
        Log "Invalid parameters;iibLinuxzipFile is missing "
        exit 1
    fi
    if [ -z ${iibSourceDir} ];then
        Log "Invalid parameters;iibSourceDir is missing "
        exit 1
    fi
    if [ -z ${iibTargetDir} ];then
        Log "Invalid parameters;iibTargetDir is missing "
        exit 1
    fi
    #
    if [[ -d ${iibTargetDir} ]];then
        Log "Target directory ${iibTargetDir} already exists ... deleting "
        rm -rf ${iibTargetDir}
    fi
    if [[ ! -d ${iibTargetDir} ]];then
        Log "Target directory ${iibTargetDir} does not exist ..."
        Log "Target directory ${iibTargetDir} will be created ..."
        mkdir -p ${iibTargetDir}
    #    exit 1
    fi
    if [ ! -e ${iibSourceDir}/${iibLinuxzipFile} ];then
        Log "MQ zip file ${iibSourceDir}/${iibLinuxzipFile} does not exist"
        exit 1
    fi
    #
    if ! cd ${iibTargetDir}; then
        Log "Error changing directory to ${iibTargetDir}"
        exit 1
    fi
    if ! unzip ${iibSourceDir}/${iibLinuxzipFile}; then
        Log "Error unzipping file ${iibSourceDir}/${iibLinuxzipFile} into ${iibTartgetDir}"
        exit 1
    fi
}

##########################################################################
#
# Create IIB user
#
###########################################################################
function createIIBCredentials() {
    #
    iibGroup=mqbrkrs
    iibAdmin=iibadmin
    #
    eval `grep iibPasswd ${INI_FILE}`
    if [ -z ${iibPasswd} ]; then
       Log "Invalid parameter;iibPasswd missing from ${INI_FILE}"
       exit 1
    fi
    #
    eval `grep iibPasswd ${INI_FILE}`
    if [ -z ${iibPasswd} ]; then
       Log "Invalid parameter;iibPasswd missing from ${INI_FILE}"
       exit 1
    fi
    #
    if groups ${iibGroup} >/dev/null 2>&1
    then
         Log "${iibGroup} group exists"
    else
         Log "${iibGroup} group does not exist - creating ${iibGroup} group"
         if ! groupadd ${iibGroup}
         then
              Log "Failed to create group ${iibGroup}"
    #          exit 1
         fi
    fi
    #
    # Add iibadmin user if missing
    #
    if id ${iibAdmin} >/dev/null 2>&1
    then
         Log "${iibAdmin} user exists"
    else
         Log "${iibAdmin} user does not exit - creating ${iibAdmin} user"
         if ! useradd -g ${iibGroup} ${iibAdmin}
         then
              Log "Failed to create user ${iibAdmin}"
    #          exit 1
         fi
         #
         # Set the password
         #
         if ! echo ${mqPasswd} | passwd ${iibAdmin} --stdin
         then
              Log "Failed to set password for ${iibAdmin}"
              exit 1
         fi
    fi
    #
    # Add iibadmin to mqm group and
    #  ... mqm to mqbrkrs
    #
    usermod -a -G mqbrkrs mqm
    usermod -a -G mqm iibadmin
    #
}

###########################################################################
#
# Install MQ
#
###########################################################################
function installIIBv10() {
    #
    eval `grep iibLinuxzipFile ${INI_FILE}`
    eval `grep iibSourceDir ${INI_FILE}`
    eval `grep iibTargetDir ${INI_FILE}`
    echo "${iibLinuxzipFile}"
    echo "${iibSourceDir}"
    echo "${iibTargetDir}"
    #
    eval `grep iibTargetDir ${INI_FILE}`
    if [[ -z ${iibTargetDir} ]] ; then
       log "Invalid parametere;mqTargetDir missing from ${INI_FILE}"
       exit 1
    fi
    iibInstallFolder="/opt/IBM"    
    #
    echo "Creating iib installation folder"
    echo "--------------------------------"
    mkdir -p ${iibInstallFolder}
    #
    if ! chown -R mqm:mqbrkrs ${iibInstallFolder}; then
        echo "Error chaning owner for ${iibInstallFolder}"
        exit 1
    fi
    #
    cd ${iibInstallFolder}
    pwd
    ##
    if ! tar -xzvf ${iibTargetDir}10.0.0.9-IIB-LINUX64-DEVELOPER.tar.gz --exclude iib-10.0.0.9/tools; then
        echo "Error installing IIBv10"
        exit 1
    fi
    #
    # accept the license as globally (all users)
    #
    if ! cd /opt/IBM/iib-10.0.0.9; then
        echo "Error changing to IIB folder /opt/IBM/iib-10.0.0.9"
        exit 1
    fi
    if ! ./iib make registry global accept license silently; then
        echo "Error accepting license"
        exit 1
    fi
    #
    # amend the owner of the /var/mqsi folder that gets created after accepting the license
    if ! chown -R mqm:mqbrkrs /var/mqsi; then
        echo "Error updating owner for /var/mqsi"
        exit 1
    fi
    
    #
    # Run mqconfig to ensure all is good before continuing
    #
    ##Log "/opt/mqm/bin/mqcongig ..."
    ##su mqm -c "/opt/mqm/bin/mqconfig" >> ${LOG_FILE}
    ##FAILED=$(su mqm -c "/opt/mqm/bin/mqconfig" | grep FAIL | wc -l)
    ##if [ "$FAILED" -ne "0" ]
    ##then
    ##     Log "System parameters are in error"
    ##     exit 1
    ##fi

}

###########################################################################
#
# Create Broker
#
###########################################################################
function createBroker() {
    #
    #
    # Update the mqm profile to enable the MQ and commands ...
    #
    mqmDir=/home/iibadmin
    pathLine=$(cat ${mqmDir}/.bash_profile | grep PATH= -n)
    if [ -z ${pathLine} ]; then
        echo "Error 'Path=' variable not found in ${mqmDir}/.bash_profile"
        exit 1
    fi
    lineNo=$(echo ${pathLine} | awk -F ":" '{print $1}')
    lineNo=$( expr ${lineNo} - 1 )
    sed -i "${lineNo}i# Auto inserted by installIIBv10.sh script\n. /opt/mqm/bin/setmqenv -s\n. /opt/IBM/iib-10.0.0.9/server/bin/mqsiprofile " ${mqmDir}/.bash_profile
    #
    if ! su - iibadmin -c "mqsicreatebroker TSTIFD01 -q TSTQFD01"; then
        echo "Error creating broker TSTIFD01"
    #    exit 1
    fi
    #
    if ! su - iibadmin -c "cd /opt/IBM/iib-10.0.0.9/server/sample/wmq; ./iib_createqueues.sh TSTQFD01 mqbrkrs"; then
        echo "Error changing to IIB folder /opt/IBM/iib-10.0.0.9/server/sample/wmq"
        echo "Error updating message broker (TSTIFD01) queue manager (TSTQFD01) with MQ configurations"
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
    ##checkForMQ
    ##unzipLinuxIIBv10
    ##createIIBCredentials
    #
    #installIIBv10
    createBroker
    #
    Log "IIB installation complete - please check logs in ${LOG_FILE}"
    exit 0

