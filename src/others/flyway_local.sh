#!/usr/bin/env bash


workFolder=/home/yermek/data/fortests
flywayFolder=/opt/flyway-5.2.4

files=$(find ${workFolder} -iname *.conf -type f)

export PATH=$PATH:${flywayFolder}

user=""
url=""
pwd=""
sqlFolder=""
logFolder=""

for i in ${files[*]}
do
    echo "Processing file: ${i}"
    # ***************************
    while read n
    do
        case $(echo ${n}|cut -f 1 -d ' ') in
        "url") url=$(echo ${n}|cut -f 2 -d ' ')
        ;;
        "user") user=$(echo ${n}|cut -f 2 -d ' ')
        ;;
        "password") pwd=$(echo ${n}|cut -f 2 -d ' ')
        ;;
        "sqlfolder") sqlFolder=$(echo ${n}|cut -f 2 -d ' ')
        ;;
        "logfolder") logFolder=$(echo ${n}|cut -f 2 -d ' ')
        esac
    done < ${i}
    # ***************************
    if [[ -n ${user} ]] && [[ -n ${url} ]] && [[ -n ${pwd} ]] && [[ -n ${sqlFolder} ]] && [[ -n ${logFolder} ]]
    then
       if [[ -e ${sqlFolder} ]] && [[ -e ${logFolder} ]]
       then
         logFile=${logFolder}"/"$(basename ${i} .conf)".log."$(date +"%m_%d_%Y")
         cmd="flyway migrate -url='${url}' -user='${user}' -password='${pwd}' -locations='${sqlFolder}' > ${logFile} 2>&1"
         echo "Run: ${cmd}"
       else
         echo "Cannot find folder: ${sqlFolder} or folder: ${logFolder}"
       fi
    else
       echo "some of parameters are empty"
    fi
    # ***************************
done