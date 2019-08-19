#!/usr/bin/env bash


#export PATH=$PATH:/opt/kafka-2.3.0/bin

#topic="/opt/app/bash/topic.lst"

# test ! -e ${topic} && echo "File "${topic}" doesn't exist" && exit -1
# cat ${topic}|xargs -I {} kafka-topics.sh --zookeeper localhost:2181 --delete --topic {}
# topic_list=$(cat ${topic})
# for i in ${topic_list[*]}; do; kafka-topics.sh --zookeeper localhost:2181 --delete --topic ${i}; done

whatis curl > /dev/null 2>&1; test $? -ne 0 && echo "Error: Curl not installed"

# Deleting topics
# curl -s http://localhost:8082/topics|jq -r '.[]'|grep "_10200413306_test"|xargs -I {} /opt/confluent-5.2.2/bin/kafka-topics --zookeeper localhost:2181 --delete --topic {}

hostIP="xx.xx.x.xx"
restBaseURL="http://${hostIP}:8082"
prefixData="_10200413306_test"

topic_list=$(curl -s ${restBaseURL}"/topics"|jq -r '.[]'|grep ${prefixData})

curl -s -GET ${restBaseURL}"/brokers"|jq '.'

#for i in ${topic_list[*]}
#do
#    echo "Topic: ${i}"
#    # curl -s ${restBaseURL}"/"${i}|jq '.name'
#
#done


