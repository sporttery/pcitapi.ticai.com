#!/bin/bash
logFile=/var/log/pcitapi.log
curl -s -m 3 http://pcitapi.ticai.com/api/getAwardResult 2>&1 >> $logFile

step=3 #间隔的秒数，不能大于60

for (( i = 0; i < 60; i=(i+step) )); do
    curl -s -m 3 http://pcitapi.ticai.com/api/getData 2>&1 >> $logFile
    sleep $step
done
exit 0

