# MQ v8

## Clone the Repo
`git clone https://github.com/mgis-architects/mqv8`

## Install IBM MQv8

Select the latest version...

Production version must be used for ALL environments higher than development.

IBM MQ must be downloaded from IBMs Passport Advantage web-site;
https://www-01.ibm.com/software/passportadvantage/pao_customer.html

Development version of MQv8 can be installed and used, without license from;
http://www14.software.ibm.com/cgi-bin/weblap/lap.pl?popup=Y&li_formnum=L-APIG-9BUHAE&accepted_url=http://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqadv/mqadv_dev80_linux_x86-64.tar.gz

## Read about the provider

e.g. Read https://www.ibm.com/support/knowledgecenter/en/SSFKSJ_8.0.0/com.ibm.mq.helphome.v80.doc/WelcomePagev8r0.htm

## Set environment variables
### For Azure:
`export TF_VAR_tenantid=YourAzureTenantId`

`export TF_VAR_appid=YourAzureADApplicationId`

`export TF_VAR_apppassword=YourAzureADApplicationKey`

`export TF_VAR_subscriptionid=YourAzureSubscriptionId`

### Build Zip file

Download the MQv8 Linux binaries from IBM web-site and transfer the file to a folder in Linux - e.g. /home/user
Download the MQv8 Linux fix-pack from IBM web-site and transfer the file to a folder on the Linux server - e.g. /home/user

### Before running createMQv8_FP0006Zip.sh - update ini files
#### createMQv8_FP0006Zip.ini
update ./parameters/createMQv8_FP0006Zip.ini

set `mqSourceDir` to the folder containing the MQ binaries
set `mqFPDir` to the folder containing the MQ Fix Pack binaries (optional)

### checkForMQZipFile.ini
update ./parameter/checkForMQZipFile.ini

set `zipFile` to the name of the zip file that gets created in `createMQv8_FP0006Zip.sh`

### allocateStorage.ini
update ./parameters/allocateStorage.ini

set `mqGroup` to `mqm`
set `mqUserId` to `mqm`
set `mqPasswd` to a valid, strong password

set `disk` to `sdc`
set `alternateDisk` to `sdb`

set `partSize1` to the size of the partition for MQ `/var/mqm/qmgrs`
set `partSize2` to the size of the partition for MQ `/var/mqm/log`
set `partSize3` to the size of the partition for MQ `/var/mqm/errors`
set `partSize4` to the size of the partition for MQ `/var/mqm/trace`

### untarMQv8.ini
update ./parameter/untarMQv8.ini

set `mqSourceDir` to the destination folder of the target MQ server where the MQ binaries where unzipped to
set `mqSourceFile` to the name of the Linux MQ tar file that contains the MQ binaries
set `mqTargetDir` to the destination folder to where the MQ tar file will be untarted

### untarMQv8FP006.ini - Only required if Fix Pack 0006 is being installed
update ./parameters/untarMQv8FP0006.ini

set `mqSourceDir` to the destinaton folder of the target MQ server where the MQ Fix Pack binaries where unzipped to
set `mqSourceFile` to the name of the Linux MQ tar file that contains the MQ Fix Pack binaries
set `mqTargetDir` to the destination folder to where the MQ Fix Pack tar file will be untarted

### Queue Manager mqsc files
A queue manager cluster will be created as follows;

Queue manager naming conventions follows the following pattern;
   `XXXABC99`

   Where;

      `XXX` - could be the business unit
        `A` - `Q` for Queue Manager
              `I` for Integration Bus
        `B` - `F` for Full Repository queue manager
              `P` for Partial Repository queue manager
        `C` - `D` for Development
              `S` for System Testing
              `R` for Pre-Prod
              `P` for Production
       `99` - Sequence number
  
Full repository queue manager #1 `TSTQFD01`
Full repository queue manager #2 `TSTQFD02`

Partial repository queue manager #1 `TSTQPD01`
Partial repository queue manager #1 `TSTQPD02`
Partial repository queue manager #1 `TSTQPD03`
Partial repository queue manager #1 `TSTQPD04`

### Create `ini` files, for each queue manager required.
In each queue manager `ini` file;

set `queueManagerName` to the name of the queue manager being created
set `qmType` to `Full` or `Partial`
set `mqscDir` to the folder where `mqsc` files will be created

set `DLQ` to the name of the MQ Dead Letter Queue 
set `clusterName` to the name of the MQ cluster

set `remoteQueueMangerName` to the name of the remote queue manager that 'this' queue manager will connect to

set `qmHost` to the IP address of 'this' queue manager

set `qmPort` to the port number of 'this' queue manager will listen on

set `remoteHost` to the IP address of the remote queue manager, that 'this' queue manager will connect to

set `remoteqmPort` to the port number of the remote queue manager that 	'this' queue manager will connect to


### Create Zip file
Create a zip file, containing all the Linux installation/setup scripts and the MQ binaries
An .md5 sha file is also created, but is not added to the zip file

`sudo ./createMQv8_FP0006Zip.sh createMQv8_FP0006Zip.ini`

### Copy Zip File and MD5 files
Copy the created zip file and md5 file to appropriate server 

### Install
Setup the Linux Server and Install MQ

`sudo ./unzipMQv8_FP0006.sh {zip file} {MQ binary file location} {MQ Fix Pack file location} {Queue Manager Name}`
