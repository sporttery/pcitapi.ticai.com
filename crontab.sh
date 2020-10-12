#!/bin/sh
logFile=/var/log/pcitapi.log
datetime=$(date +"%F %T")
echo "START AT $datetime" >> $logFile
/usr/sbin/ntpdate -u  sslitntp.lottery-it.com sslitntp.lottery-it.com 2>&1 >> $logFile
nohup /var/www/pcitapi.ticai.com/AwardResultSubscribe.sh &
nohup /var/www/pcitapi.ticai.com/showscreen.sh &
while true
do
    datetime=$(date +"%F %T")
    if [ ! -f /tmp/stopData ] ; then
        data=$(curl -s -m 2 http://pcitapi.ticai.com/api/getData 2>&1)
        mcount=$(echo $data | wc -m)
        if [ $mcount -gt 76 ] ; then
            echo [$datetime] - $data >> $logFile
        fi
    fi
    #if [ ! -f /tmp/stopAwardResult ] ; then
    #    result=$(curl -s -m 2 http://pcitapi.ticai.com/api/getAwardResult 2>&1)
    #    mcount=$(echo $result | wc -m)
    #   if [ $mcount -gt 150 ] ; then
    #        echo [$datetime] - $result >> $logFile
    #    fi
    #fi
    sleep 2
done
