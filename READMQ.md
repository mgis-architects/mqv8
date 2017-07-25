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

