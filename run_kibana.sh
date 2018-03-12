#!/bin/bash

ES_URI=$(echo "${VCAP_SERVICES}" | jq -r .elasticsearch56[0].credentials.uri)

if grep ^elasticsearch.url config/kibana.yml >/dev/null ; then
	echo kibana.yml is already configured
else
	echo "elasticsearch.url: \"${ES_URI}\"" >> config/kibana.yml
	echo "server.port: \"9000\"" >> config/kibana.yml
	echo "logging.verbose: true" >> config/kibana.yml
fi

# start the app up
./bin/kibana &

# start up a proxy to redirect to the real app so that it comes up fast enough.
node server.js
