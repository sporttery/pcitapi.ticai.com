#!/bin/sh
logFile=/var/log/pcitapi.log
while true
curl http://pcitapi.ticai.com/api/getData 2>&1 >> $logFile
curl http://pcitapi.ticai.com/api/getAwardResult 2>&1 >> $logFile
sleep 1
done