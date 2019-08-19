#!/bin/bash

# Script for:
# 1. Generating and re-creating AVRO schemas in Confluent registry schema
# 2. Generating KSQL Stream scripts

# ****************************************************************
# Variables section
# ****************************************************************
workFolder=/home/yermek/data/fortests

tbl_lst=${workFolder}"/"tbl.mysql.csr.csv
q1=${workFolder}"/"avro-generate-mysql.csr.sql
q2=${workFolder}"/"ksql-generate-mysq.sql

hostIP="xx.xx.x.xx"
topicHostname="zambia_test"
csregistryHost="xx.xx.xx.xx"
csregistryBaseURL="http://${csregistryHost}:8085/subjects"

port="3306"
user="dba"

export MYSQL_PWD="xxxxx"

tFolder=${workFolder}"/"${topicHostname}"_mysql"

# ****************************************************************
# Body section
# ****************************************************************
test ! -e ${workFolder} && echo "Error: Folder ${workFolder} not exist" && exit -1
test ! -e ${tbl_lst} && echo "Error: File ${tbl_lst} not found" && exit -1
test ! -e ${q1} && echo "Error: File ${q1} not found" && exit -1
test -e ${tFolder} && echo "Folder ${tFolder} exist. Re-create it" && rm -rf ${tFolder} && mkdir ${tFolder}
test ! -e ${tFolder} && echo "Folder ${tFolder} doesn't exist. Re-create it" && mkdir ${tFolder}

whatis mysql > /dev/null 2>&1; test $? -ne 0 && echo "Error: PostgreSQL client not installed" && exit -1
whatis curl > /dev/null 2>&1; test $? -ne 0 && echo "Error: Curl not installed"

curl -s --connect-timeout 5 ${csregistryBaseURL} > /dev/null
test $? -ne 0 && echo "Error: Problem connecting to Confluent Schema Registry host. Exit code: $?" && exit -1

test ! -e ${tbl_lst} && echo "Error: File ${tbl_lst} not found" && exit -1
tbl_list=$(cat ${tbl_lst})

for i in ${tbl_list[*]}; do
    db=${i%%.*}; tbl=${i##*.}
    rFile=${tFolder}/${topicHostname}"_"${db}"_"${tbl}".schema"
    ksqlFile=${tFolder}/${topicHostname}"_"${db}"_"${tbl}".sql"
    # *****************************************
    echo "Processing table: "${tbl}
    echo "Target schema: "${rFile}
    echo "Target script: "${ksqlFile}
    mysql -h ${hostIP} -u ${user} -P ${port} -A -sN -e "set @srv='${topicHostname}'; set @db='${db}'; set @table='${tbl}'; source ${q1};" > ${rFile}
    # *****************************************
    sed -i 's/|/\\/g' ${rFile}
    cnt=$(($(cat ${rFile}|wc -l)-1))
    sed -i "${cnt}s/},/}/" ${rFile}
    # *****************************************
    # Re-creating schemas
    # *****************************************
    s1=${csregistryBaseURL}"/"$(basename ${rFile} .schema)
    s2=${csregistryBaseURL}"/"$(basename ${rFile} .schema)"/versions"
    echo "Re-creating schema for table: ${tbl}"
    # echo "s1: ${s1}"; echo "s2: ${s2}"
    curl -s -X DELETE ${s1} > /dev/null 2>&1
    test $? -ne 0 && echo "Error: Cannot delete schema from Confluent Schema Registry" && exit -1
    curl -s --output /dev/null -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" -d @${rFile} ${s2}
    test $? -ne 0 && echo "Error: Cannot create schema in Confluent Schema Registry" && exit -1
    echo "Done"
done


