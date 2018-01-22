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
## 0.1      06072017  xxxxxx      initial version
##
##
## sudo /bin/bash installIIBv10.sh TSTIPD01.ini
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
# Check for MQ ... as we need it ... and check to see if the MQ installer
#  ... script is still running
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
    #
    # Check to see if the MQ installer is running
    #   if it is, wait until its finished ...
    #
    loopCount=1
    while [ ${loopCount} -le 10 ]
    do
        Log "Checking for installation file unzipMQv8_FP0006 is still running"
        MQProcess=`ps -ef | grep unzipMQv8_FP0006 | grep -v grep | wc -l`
        if [[ ${MQProcess} != 0 ]]; then
            Log "unzipMQv8_FP0006 process is still running ..."
            Log "Count ${loopCount} : sleeping for 60 seconds ..."
            sleep 60
        else
            loopCount=20
        fi
        loopCount=$(( ${loopCount}+1 ))
    done
    #
    MQProcess=`ps -ef | grep unzipMQv8_FP0006 | grep -v grep | wc -l`
    if [[ ${MQProcess} -ne 0 ]]; then
        Log "unzipMQv8_FP0006 process is still running after 10 minutes ..."
        exit 1
    fi
    #

}

###########################################################################
#
# Unzip the LinuxIIBv10.zip file
#
###########################################################################
function unzipLinuxIIBv10_v1() {
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
    if [ ! -e ${iibSourceDir}${iibLinuxzipFile} ];then
        Log "IIB zip file ${iibSourceDir}${iibLinuxzipFile} does not exist"
        exit 1
    fi
    #
    if ! cd ${iibTargetDir}; then
        Log "Error changing directory to ${iibTargetDir}"
        exit 1
    fi
    if ! unzip ${iibSourceDir}${iibLinuxzipFile}; then
        Log "Error unzipping file ${iibSourceDir}${iibLinuxzipFile} into ${iibTartgetDir}"
        exit 1
    fi
    #
    cp ${INI_FILE_PATH} ${INI_FILE}
    #

}

##########################################################################
#
# Create IIB user
#
###########################################################################
function createIIBCredentials() {
    #
    eval `grep iibGroup ${INI_FILE}`
    eval `grep iibUser ${INI_FILE}`
    eval `grep mqGroup ${INI_FILE}`
    eval `grep mqUser ${INI_FILE}`
    #
    if [ -z ${iibGroup} ];then
        Log "Invalid parameters;iibGroup is missing "
        exit 1
    fi
    if [ -z ${iibUser} ];then
        Log "Invalid parameters;iibUser is missing "
        exit 1
    fi
    if [ -z ${mqGroup} ];then
        Log "Invalid parameters;mqGroup is missing "
        exit 1
    fi
    if [ -z ${mqUser} ];then
        Log "Invalid parameters;mqUser is missing "
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
    if id ${iibUser} >/dev/null 2>&1
    then
         Log "${iibUser} user exists"
    else
         Log "${iibUser} user does not exit - creating ${iibUser} user"
         if ! useradd -g ${iibGroup} ${iibUser}
         then
              Log "Failed to create user ${iibUser}"
    #          exit 1
         fi
    fi
    #
    # Set the password
    #
    if ! echo ${iibPasswd} | passwd ${iibUser} --stdin
    then
        Log "Failed to set password for ${iibUser}"
        exit 1
    fi
    #
    # Add iibadmin to mqm group and
    #  ... mqm to mqbrkrs
    #
    usermod -a -G ${iibGroup} ${mqUser}
    usermod -a -G ${mqGroup} ${iibUser}
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
    if [[ -z ${iibLinuxzipFile} ]] ; then
       Log "Invalid parametere;iibLinuxzipFile missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep iibSourceDir ${INI_FILE}`
    if [[ -z ${iibSourceDir} ]] ; then
       Log "Invalid parametere;iibSourceDir missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep iibTargetDir ${INI_FILE}`
    if [[ -z ${iibTargetDir} ]] ; then
       Log "Invalid parametere;mqTargetDir missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep mqUser ${INI_FILE}`
    if [[ -z ${mqUser} ]] ; then
       Log "Invalid parametere;mqUserId missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep iibGroup ${INI_FILE}`
    if [[ -z ${iibGroup} ]] ; then
       Log "Invalid parametere;iibGroup missing from ${INI_FILE}"
       exit 1
    fi
    #
    iibInstallFolder="/opt/IBM/"    
    #
    Log "Creating iib installation folder"
    Log "--------------------------------"
    mkdir -p ${iibInstallFolder}
    #
    if ! chown -R ${mqUser}:${iibGroup} ${iibInstallFolder}; then
        Log "Error chaning owner for ${iibInstallFolder}"
        exit 1
    fi
    #
    cd ${iibInstallFolder}
    #
    if ! tar -xzvf ${iibTargetDir}10.0.0.9-IIB-LINUX64-DEVELOPER.tar.gz --exclude iib-10.0.0.9/tools; then
        Log "Error installing IIBv10"
        exit 1
    fi
    #
    # accept the license as globally (all users)
    #
    if ! cd ${iibInstallFolder}iib-10.0.0.9; then
        Log "Error changing to IIB folder ${iibInstallFolder}iib-10.0.0.9"
        exit 1
    fi
    if ! ./iib make registry global accept license silently; then
        Log "Error accepting license"
        exit 1
    fi
    #
    # amend the owner of the /var/mqsi folder that gets created after accepting the license
    if ! chown -R ${mqUser}:${iibGroup} /var/mqsi; then
        Log "Error updating owner for /var/mqsi"
        exit 1
    fi
    
}

###########################################################################
#
# Create Broker
#
###########################################################################
function createBroker() {
    #
    #
    # Update the mqm profile to enable the MQ and IIB commands ...
    #
    eval `grep brokerName ${INI_FILE}`
    if [[ -z ${brokerName} ]] ; then
       Log "Invalid parameter;brokerName missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep iibMQServer ${INI_FILE}`
    if [[ -z ${iibMQServer} ]] ; then
       Log "Invalid parameter;iibMQServer missing from ${INI_FILE}"
       exit 1
    fi
    eval `grep iibUser ${INI_FILE}`
    if [[ -z ${iibUser} ]] ; then
       Log "Invalid parameter;iibUser missing from ${INI_FILE}"
       exit 1
    fi
    #
    iibDir=/home/${iibUser}
    pathLine=$(cat ${iibDir}/.bash_profile | grep PATH= -n)
    if [ -z ${pathLine} ]; then
        Log "Error 'Path=' variable not found in ${iibDir}/.bash_profile"
        exit 1
    fi
    lineNo=$(echo ${pathLine} | awk -F ":" '{print $1}')
    lineNo=$( expr ${lineNo} - 1 )
    sed -i "${lineNo}i# Auto inserted by installIIBv10.sh script\n. /opt/mqm/bin/setmqenv -s\n. /opt/IBM/iib-10.0.0.9/server/bin/mqsiprofile " ${iibDir}/.bash_profile
    #
    if ! su - ${iibUser} -c ". /opt/IBM/iib-10.0.0.9/server/bin/mqsiprofile; mqsicreatebroker ${brokerName} -q ${iibMQServer}"; then
        Log "Error creating broker ${brokerName}"
    #    exit 1
    fi
    #
    if ! su - ${iibUser} -c " cd /opt/IBM/iib-10.0.0.9/server/sample/wmq; ./iib_createqueues.sh ${iibMQServer} ${iibGroup}"; then
        Log "Error changing to IIB folder /opt/IBM/iib-10.0.0.9/server/sample/wmq"
        Log "Error updating message broker (${brokerName}) queue manager (${iibMQServer}) with MQ configurations"
    #    exit 1
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
    iibLinuxzipFile=LinuxIIBv10.zip
    iibSourceDir=/home/mqadmin/
    iibTargetDir=/home/mqadmin/iibv10/
    INI_FILE_PATH=${iibTargetDir}parameters/$1
    if [[ -z ${INI_FILE_PATH} ]]; then
        Log "${prog} called with null parameter, should be the path to the driving ini_file"
        exit 1
    fi
    ##if [[ ! -f ${INI_FILE_PATH} ]]; then
    ##    Log "${prog} ini_file cannot be found"
    ##    exit 1
    ##fi
    ##if ! mkdir -p ${LOG_DIR}; then
    ##    Log "${prog} cant make ${LOG_DIR}"
    ##    exit 1
    ##fi
    #
    ##cp ${INI_FILE_PATH} ${INI_FILE}
    #
    checkForMQ
    unzipLinuxIIBv10_v1
    createIIBCredentials
    #
    installIIBv10
    createBroker
    #
    Log "IIB installation complete - please check logs in ${LOG_FILE}"
    exit 0

