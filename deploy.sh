#!/bin/bash -xeu
# 
# This script will try to configure/deploy Kibana into cloud.gov

KIBANA_VERSION=5.6.8
LOGSTASH_VERSION=5.6.8

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

cp run_kibana.sh server.js package.json kibana/

if cf services | grep ^elk-elasticsearch >/dev/null ; then
	echo elk-elasticsearch seems to be set up already, leaving alone
else
	cf create-service elasticsearch56 medium elk-elasticsearch
	until cf services | grep 'elk-elasticsearch.*create succeeded' >/dev/null ; do
		echo sleeping until elasticsearch service is provisioned...
		sleep 5
	done
fi

# cf push -f kibana-manifest.yml
export ES_URI=$(cf env elk-kibana | grep '    "uri' | sed 's/.*\(http.*\)".*/\1/')
export ES_URL=$(echo "${ES_URI}" | sed 's/\/\/.*@/\/\//')
export ES_USER=$(echo "${ES_URI}" | sed 's/.*\/\/\(.*\):.*@.*/\1/')
export ES_PW=$(echo "${ES_URI}" | sed 's/.*\/\/.*:\(.*\)@.*/\1/')
echo "##########################################"
echo "Kibana username: ${ES_USER}"
echo "Kibana password: ${ES_PW}"
echo "##########################################"


############################################
# Start up logstash here

cf push -f logstash-manifest.yml --no-start -o docker.elastic.co/logstash/logstash:5.6.8
cf set-env elk-logstash XPACK.MONITORING.ENABLED false
cf set-env elk-logstash XPACK.SECURITY.ENABLED false
cf set-env elk-logstash CONFIG_STRING "$(cat <<EOF
output {
	elasticsearch {
		hosts => ["${ES_URL}"]
		user => "${ES_USER}"
		password => "${ES_PW}"
	}
}
EOF
)"
cf push -f logstash-manifest.yml -o docker.elastic.co/logstash/logstash:5.6.8

# cf create-user-provided-service XXX
# cf bind-service XXX