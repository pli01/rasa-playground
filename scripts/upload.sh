#!/bin/bash

rasa_host=$RASA_HOST
[ -z "${RASA_HOST}" ] && exit 1

#
# get bearer and api_token from jwt
#
access_token=$(curl  -s -XPOST http://$rasa_host/api/auth -d '{"username": "me", "password": "AdminMe"}' )
bearer=$(echo $access_token | jq -re '.access_token')

payload=$(echo $access_token | jq '.access_token' | awk -F\. '{ print $2 }')
api_token=$(echo "$payload==" | base64 -d | jq '.user.api_token')

# nlu
curl -k -XPUT \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: text/yaml" \
       -H "Connection: keep-alive" \
       -T data/nlu.yml \
      "http://$rasa_host/api/projects/default/training_examples"

# stories
curl -k -XPUT \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: text/yaml" \
       -H "Connection: keep-alive" \
       -T data/stories.yml \
      "http://$rasa_host/api/stories"

# rules
curl -k -XPUT \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: text/yaml" \
       -H "Connection: keep-alive" \
       -T data/rules.yml \
      "http://$rasa_host/api/rules"

# config
curl -k -XPUT \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: application/x-yaml" \
       -H "Connection: keep-alive" \
       -T config.yml \
      "http://$rasa_host/api/projects/default/settings"

exit 0
## TODO domain
# domain

curl -k -XGET \
       -H "Authorization: Bearer $bearer" \
       -H "Connection: keep-alive" \
      "http://$rasa_host/api/projects/default/domains/"

curl -k -XDELETE \
       -H "Authorization: Bearer $bearer" \
      "http://$rasa_host/api/projects/default/domains/9"

curl -k -XPOST \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: application/json;charset=utf-8" \
       -d '{"content_yaml":"version: 2.0\r\n","filename":"domain.yml"}'
      "http://$rasa_host/api/projects/default/domains/"

## responses

curl -k -XPOST \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: application/json;charset=utf-8" \
        -d '{"response_name":"utter_greet","text":"Hello! How can I help you?"}'
      "http://$rasa_host/api/responses"
