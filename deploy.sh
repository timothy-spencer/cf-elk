#!/bin/bash -xeu
# 
# This script will try to configure/deploy Kibana into cloud.gov

KIBANA_VERSION=5.6.8

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
	git clone -b "v${KIBANA_VERSION}" --single-branch --depth 1 https://github.com/elastic/kibana.git
fi

cp run_kibana.sh package.json kibana/

if cf services | grep ^elk-elasticsearch >/dev/null ; then
	echo elk-elasticsearch seems to be set up already, leaving alone
else
	cf create-service elasticsearch56 medium elk-elasticsearch
fi

cf push
