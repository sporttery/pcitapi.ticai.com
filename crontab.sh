#!/bin/sh
#chmod +x /etc/rc.d/rc.local
#echo "nohup crontab.sh &" >> /etc/rc.d/rc.local
logFile=/var/log/pcitapi.log
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
    sleep 1.5
done