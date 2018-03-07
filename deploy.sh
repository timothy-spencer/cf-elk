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
	echo kibana seems to be pulled down already.  Leaving alone.
else
	if which shasum >/dev/null ; then
		SHASUM="shasum"
	else
		SHASUM="sha1sum"
	fi
	wget -c https://artifacts.elastic.co/downloads/kibana/kibana-"${KIBANA_VERSION}"-linux-x86_64.tar.gz
	if [ "$(${SHASUM} kibana-${KIBANA_VERSION}-linux-x86_64.tar.gz | awk '{print $1}')" != "4c08284c6b3c8225f8607fd349717cc3b37c1897" ] ; then
		echo kibana package is corrupted, aborting
		exit 2
	fi
	tar zxpf kibana-"${KIBANA_VERSION}"-linux-x86_64.tar.gz
	mv kibana-"${KIBANA_VERSION}"-linux-x86_64 kibana
fi

cp run_kibana.sh package.json kibana/

if cf services | grep ^elk-elasticsearch >/dev/null ; then
	echo elk-elasticsearch seems to be set up already, leaving alone
else
	cf create-service elasticsearch56 medium elk-elasticsearch
fi

cf push
