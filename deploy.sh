#!/bin/bash -eu
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

cf push -f kibana-manifest.yml
export ES_URI=$(cf env elk-kibana | grep '    "uri' | sed 's/.*\(http.*\)".*/\1/')
export ES_URL=$(echo "${ES_URI}" | sed 's/\/\/.*@/\/\//')
export ES_USER=$(echo "${ES_URI}" | sed 's/.*\/\/\(.*\):.*@.*/\1/')
export ES_PW=$(echo "${ES_URI}" | sed 's/.*\/\/.*:\(.*\)@.*/\1/')


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

## set logstash service up for our space to drain logs into
# cf create-user-provided-service XXX
# cf bind-service XXX


# load some data into logstash
cf ssh elk-logstash -c 'curl -o shakespeare_6.0.json https://download.elastic.co/demos/kibana/gettingstarted/shakespeare_6.0.json'
cf ssh elk-logstash -c 'curl -o logs.jsonl.gz https://download.elastic.co/demos/kibana/gettingstarted/logs.jsonl.gz'
cf ssh elk-logstash -c "curl -XPUT '${ES_URI}/shakespeare?pretty' -H 'Content-Type: application/json' -d'
{
 \"mappings\": {
  \"doc\": {
   \"properties\": {
    \"speaker\": {\"type\": \"keyword\"},
    \"play_name\": {\"type\": \"keyword\"},
    \"line_id\": {\"type\": \"integer\"},
    \"speech_number\": {\"type\": \"integer\"}
   }
  }
 }
}
'"
cf ssh elk-logstash -c "curl -XPUT '${ES_URI}/logstash-2015.05.18?pretty' -H 'Content-Type: application/json' -d'
{
  \"mappings\": {
    \"log\": {
      \"properties\": {
        \"geo\": {
          \"properties\": {
            \"coordinates\": {
              \"type\": \"geo_point\"
            }
          }
        }
      }
    }
  }
}
'"
cf ssh elk-logstash -c "curl -XPUT '${ES_URI}/logstash-2015.05.19?pretty' -H 'Content-Type: application/json' -d'
{
  \"mappings\": {
    \"log\": {
      \"properties\": {
        \"geo\": {
          \"properties\": {
            \"coordinates\": {
              \"type\": \"geo_point\"
            }
          }
        }
      }
    }
  }
}
'"
cf ssh elk-logstash -c "curl -XPUT '${ES_URI}/logstash-2015.05.20?pretty' -H 'Content-Type: application/json' -d'
{
  \"mappings\": {
    \"log\": {
      \"properties\": {
        \"geo\": {
          \"properties\": {
            \"coordinates\": {
              \"type\": \"geo_point\"
            }
          }
        }
      }
    }
  }
}
'"
cf ssh elk-logstash -c 'gunzip logs.jsonl.gz'
cf ssh elk-logstash -c 'mkdir shakespearetmp ; cd shakespearetmp ; split -l 100 ../shakespeare_6.0.json'
cf ssh elk-logstash -c 'mkdir logstmp ; cd logstmp ; split -l 100 ../logs.jsonl'
cf ssh elk-logstash -c "cd shakespearetmp ; for i in * ; do curl -H 'Content-Type: application/x-ndjson' -XPOST '${ES_URI}/shakespeare/doc/_bulk?pretty' --data-binary @\$i ; done"
cf ssh elk-logstash -c "cd logstmp ; for i in * ; do curl -H 'Content-Type: application/x-ndjson' -XPOST '${ES_URI}/_bulk?pretty' --data-binary @\$i ; done"


# let folks know how to get in:
KIBANA_URL=$(cf apps | grep elk-kibana | awk '{print $6}')
echo "##########################################"
echo "Kibana username: ${ES_USER}"
echo "Kibana password: ${ES_PW}"
echo "Kibana URL: ${KIBANA_URL}"
echo "##########################################"
