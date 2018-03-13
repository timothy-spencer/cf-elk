#!/bin/bash

export ES_URI=$(echo "${VCAP_SERVICES}" | jq -r .elasticsearch56[0].credentials.uri)
export ES_URL=$(echo "${ES_URI}" | sed 's/\/\/.*@/\/\//')
export ES_USER=$(echo "${ES_URI}" | sed 's/.*\/\/\(.*\):.*@.*/\1/')
export ES_PW=$(echo "${ES_URI}" | sed 's/.*\/\/.*:\(.*\)@.*/\1/')

if grep ^elasticsearch.url config/logstash.yml >/dev/null ; then
	echo logstash.yml is already configured
else
	# echo "elasticsearch.url: \"${ES_URL}\"" >> config/logstash.yml
	# echo "server.port: \"${PORT}\"" >> config/logstash.yml
	# #echo "logging.verbose: true" >> config/logstash.yml
	# echo "logging.verbose: true" >> config/logstash.yml
	# echo "elasticsearch.username: \"${ES_USER}\"" >> config/logstash.yml
	# echo "elasticsearch.password: \"${ES_PW}\"" >> config/logstash.yml
	echo configure logstash here
fi

#rake bootstrap
#rake plugin:install-default
#bin/logstash -e 'input { stdin { } } output { stdout {} }'

# start logstash up
#./bin/logstash

# XXX stay up so we can get a shell
ruby -run -ehttpd . -p"${PORT}"
