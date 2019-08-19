#!/usr/bin/env bash

# Script for:
# 1. Generating and re-creating AVRO schemas in Confluent registry schema
# 2. Generating KSQL Stream scripts

# ****************************************************************
# Variables section
# ****************************************************************
workFolder=/home/yermek/data/fortests

tbl_lst=${workFolder}"/"tbl.postgres.csr.csv
q1=${workFolder}"/"avro-generate-postgres.csr.sql
q2=${workFolder}"/"ksql-generate-postgres.sql

hostIP="localhost"
topicHostname="testsrv"
csregistryHost="localhost"
csregistryBaseURL="http://${csregistryHost}:8085/subjects"

port="5432"
user="postgres"

export PGPASSWORD="xxxxxxxx"

tFolder=${workFolder}"/"${topicHostname}"_postgres"

# ****************************************************************
# Body section
# ****************************************************************
test ! -e ${workFolder} && echo "Error: Folder ${workFolder} not exist" && exit -1
test ! -e ${tbl_lst} && echo "Error: File ${tbl_lst} not found" && exit -1
test ! -e ${q1} && echo "Error: File ${q1} not found" && exit -1
test -e ${tFolder} && echo "Folder ${tFolder} exist. Re-create it" && rm -rf ${tFolder} && mkdir ${tFolder}
test ! -e ${tFolder} && echo "Folder ${tFolder} doesn't exist. Re-create it" && mkdir ${tFolder}

whatis psql > /dev/null 2>&1; test $? -ne 0 && echo "Error: PostgreSQL client not installed" && exit -1
whatis curl > /dev/null 2>&1; test $? -ne 0 && echo "Error: Curl not installed"

curl -s --connect-timeout 5 ${csregistryBaseURL} > /dev/null
test $? -ne 0 && echo "Error: Problem connecting to Confluent Schema Registry host. Exit code: $?" && exit -1

test ! -e ${tbl_lst} && echo "Error: File ${tbl_lst} not found" && exit -1
tblList=$(cat ${tbl_lst})

for i in ${tblList[*]}; do
    db=${i%%.*}; tbl=${i##*.}
    rFile=${tFolder}/${topicHostname}"_"${db}"_"${tbl}".schema"
    ksqlFile=${tFolder}/${topicHostname}"_"${db}"_"${tbl}".sql"
    # *****************************************
    echo "Processing table: "${tbl}
    # echo "Target schema: "${rFile}
    # echo "Target script: "${ksqlFile}
    # *****************************************
    psql -h ${hostIP} -U ${user} -p ${port} -d ${db} -q -A -t -v v1="'${topicHostname}'" -v v2="'${db}'" -v v3="'$tbl'" -f ${q1} > ${rFile}
    psql -h ${hostIP} -U ${user} -p ${port} -d ${db} -q -A -t -v v1="'${topicHostname}'" -v v2="'${db}'" -v v3="'$tbl'" -f ${q2} > ${ksqlFile}
     # *****************************************
    sed -i 's/|/\\/g' ${rFile}
    cnt=$(($(cat ${rFile}|wc -l)-1))
    sed -i "${cnt}s/},/}/" ${rFile}
    cnt=$(($(cat ${ksqlFile}|wc -l)-1))
    sed -i "${cnt}s/,//" ${ksqlFile}
    cnt=$(cat ${ksqlFile}|wc -l)
    sed -i "${cnt}s/\"/\'/g" $ksqlFile
    # *****************************************
    # Re-creating schemas
    # *****************************************
    s1=${csregistryBaseURL}"/"$(basename ${rFile} .schema)
    s2=${csregistryBaseURL}"/"$(basename ${rFile} .schema)"/versions"
    echo "Re-creating schema for table: ${tbl}"
    echo "s1: ${s1}"; echo "s2: ${s2}"
    curl -s -X DELETE ${s1} > /dev/null 2>&1
    test $? -ne 0 && echo "Error: Cannot delete schema from Confluent Schema Registry" && exit -1
    echo ${rFile}
    echo ${s2}
    curl -s --output /dev/null -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" -d @${rFile} ${s2}
    test $? -ne 0 && echo "Error: Cannot create schema in Confluent Schema Registry" && exit -1
    echo "Done"
done


