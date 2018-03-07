#!/bin/bash

ES_URI=$(echo "${VCAP_SERVICES}" | jq -r .elasticsearch56[0].credentials.uri)

if grep ^elasticsearch.url config/kibana.yml >/dev/null ; then
	echo elasticsearch.url is already configured
else
	echo "elasticsearch.url: \"${ES_URI}\"" >> config/kibana.yml
fi

# start the app up
bin/kibana
