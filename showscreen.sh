#!/bin/sh
cd /var/www/pcitapi.ticai.com/
m=$1
if [ -n "$m" ] ; then
    ssh root@$m "export DISPLAY=:0.0 && scrot /abc.png"
    scp root@$m:/abc.png ./abc-$m.png
else
    while true
    do
        while read ip
        do
            if [ "A$ip" != "A" ] ; then
                $0 $ip
                sed -i "/$ip/d" showscreen
            fi
        done < showscreen
        sleep 1.5
    done
fi
