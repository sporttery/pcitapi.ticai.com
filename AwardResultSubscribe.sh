#!/bin/sh
while true
do
    curl -m 50000 http://pcitapi.ticai.com/sub -v
    sleep 1
done