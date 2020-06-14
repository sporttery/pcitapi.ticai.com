#!/bin/bash
# crond 运行方式
#* * * * * /var/www/pcitapi.ticai.com/crontab.sh
# logFile=/var/log/pcitapi.log
# curl -s -m 3 http://pcitapi.ticai.com/api/getAwardResult 2>&1 >> $logFile

# step=3 #间隔的秒数，不能大于60

# for (( i = 0; i < 60; i=(i+step) )); do
#     curl -s -m 3 http://pcitapi.ticai.com/api/getData 2>&1 >> $logFile
#     sleep $step
# done
# exit 0


# nohup /var/www/pcitapi.ticai.com/crontab.sh &
logFile=/var/log/pcitapi.log
datetime=$(date +"%F %T")
echo "START AT $datetime" >> $logFile
while true
do
    datetime=$(date +"%F %T")
    data=$(curl -s -m 2 http://pcitapi.ticai.com/api/getData 2>&1)
    mcount=$(echo $data | wc -m)
    if [ $mcount -gt 76 ] ; then
        echo [$datetime] - $data >> $logFile
    fi
    result=$(curl -s -m 2 http://pcitapi.ticai.com/api/getAwardResult 2>&1)
    mcount=$(echo $result | wc -m)
    if [ $mcount -gt 60 ] ; then
        echo [$datetime] - $result >> $logFile
    fi
    sleep 1
done

