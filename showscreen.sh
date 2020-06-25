#!/bin/sh
cd /var/www/pcitapi.ticai.com/
m=$1
if [ -n "$m" ] ; then
    ssh -i /root/id_rsa root@$m "export DISPLAY=:0.0 && scrot /abc.png"
    scp -i /root/id_rsa root@$m:/abc.png ./abc-$m.png
else
    while true
    do
        ip=$(redis-cli lpop showscreen)
        if [ "A$ip" != "A" ] ; then
            ./showscreen.sh $ip
        fi
        sleep 1.5
    done
fi
