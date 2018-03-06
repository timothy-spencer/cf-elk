#!/bin/bash -xeu
# 
# This script will try to configure/deploy Kibana into cloud.gov

if cf services | grep OK >/dev/null ; then
	echo cf seems to be up and going.
	echo This deploy will be going into:
	cf target
else
	echo cf seems not to be logged into an org/space
	echo "please log in now with 'cf login -a api.fr.cloud.gov --sso'"
	exit 1
fi

if [ -d kibana ] ; then
	echo kibana seems to be checked out already.  Leaving alone.
else
	git clone --branch v5.6.8 --single-branch https://github.com/elastic/kibana.git
fi

cp run_kibana.sh package.json .node-version kibana/

if cf services | grep ^elk-elasticsearch >/dev/null ; then
	echo elk-elasticsearch seems to be set up already, leaving alone
else
	cf create-service elasticsearch56 medium elk-elasticsearch
fi

cf push
