#!/bin/bash

rasa_host=$RASA_HOST
[ -z "${RASA_HOST}" ] && exit 1

#
# get bearer and api_token from jwt
#
access_token=$(curl  -s -XPOST http://$rasa_host/api/auth -d '{"username": "me", "password": "AdminMe"}' )
bearer=$(echo $access_token | jq -re '.access_token')

#payload=$(echo $access_token | jq '.access_token' | awk -F\. '{ print $2 }')
#api_token=$(echo "$payload==" | base64 -d | jq '.user.api_token')


# nlu
echo "# nlu"
curl -k -XPUT \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: text/yaml" \
       -H "Connection: keep-alive" \
       -T data/nlu.yml \
      "http://$rasa_host/api/projects/default/training_examples"

# stories
echo "# stories"
curl -k -XPUT \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: text/yaml" \
       -H "Connection: keep-alive" \
       -T data/stories.yml \
      "http://$rasa_host/api/stories"

# rules
echo "# rules"
curl -k -XPUT \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: text/yaml" \
       -H "Connection: keep-alive" \
       -T data/rules.yml \
      "http://$rasa_host/api/rules"

# Responses are in domain.yml
#  if you need mode responses out of domain.yml file use the following
# TODO:  convert yaml/json from domain.yml ?
#echo "# responses"
#cat responses.json | jq '.' | \
#curl -k -XPUT \
#       -H "Authorization: Bearer $bearer" \
#       -H "Content-Type: application/json;charset=utf-8" \
#        -d @- \
#      "http://$rasa_host/api/responses"
#
# config
echo "# config"
curl -k -XPUT \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: application/x-yaml" \
       -H "Connection: keep-alive" \
       -T config.yml \
      "http://$rasa_host/api/projects/default/settings"

echo "# domains"
echo "GET domains"
curl -s -k -XGET \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: application/json;charset=utf-8" \
      "http://$rasa_host/api/projects/default/domains" | \
jq '.[]|.id , .filename'

# FIXME: force update of the first domain
echo "UPDATE domains"
cat domain.yml | jq --raw-input --slurp -e '.|{content_yaml: ., filename: "domain.yml"}' | jq -c '.' |  \
curl -k -XPUT \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: application/json;charset=utf-8" \
       -d @- \
      "http://$rasa_host/api/projects/default/domains/1"

# modeles
echo "# models"
curl -k -XGET \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: application/json;charset=utf-8" \
      "http://$rasa_host/api/projects/default/models"

model_file=models/20210304-100351.tar.gz
model_name=$(basename ${model_file} .tar.gz)

echo "# Disable active models"
curl -k -XDELETE \
       -H "Authorization: Bearer $bearer" \
      "http://$rasa_host/api/projects/default/models/${model_name}"

# upload models
echo "# upload models"
curl -k -XPOST \
       -H "Authorization: Bearer $bearer" \
       -F model=@${model_file} \
      "http://$rasa_host/api/projects/default/models"

curl -k -XGET \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: application/json;charset=utf-8" \
      "http://$rasa_host/api/projects/default/models"

echo "# active models"
curl -k -XPUT \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: application/json;charset=utf-8" \
      "http://$rasa_host/api/projects/default/models/${model_name}/tags/production"

curl -k -XGET \
       -H "Authorization: Bearer $bearer" \
       -H "Content-Type: application/json;charset=utf-8" \
      "http://$rasa_host/api/projects/default/models"


exit 0
#echo "# Disable active models"
#curl -k -XDELETE \
#       -H "Authorization: Bearer $bearer" \
#      "http://$rasa_host/api/projects/default/models/$model_file/tags/production"
#
#echo "# active models"
#curl -k -XPUT \
#       -H "Authorization: Bearer $bearer" \
#       -H "Content-Type: application/json;charset=utf-8" \
#      "http://$rasa_host/api/projects/default/models/$model_file/tags/production"
#



#echo "DELETE domains"
#curl -k -XDELETE \
#       -H "Authorization: Bearer $bearer" \
#      "http://$rasa_host/api/projects/default/domains/2"
#echo "POST domains (create new)"
#cat domain.yml | jq --raw-input --slurp -e '.|{content_yaml: ., filename: "domain.yml"}' | jq -c '.' |  \
#curl -k -XPOST \
#       -H "Authorization: Bearer $bearer" \
#       -H "Content-Type: application/json;charset=utf-8" \
#       -d @- \
#      "http://$rasa_host/api/projects/default/domains?store_responses=true"
