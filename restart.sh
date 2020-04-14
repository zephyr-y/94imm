#!/bin/sh
NAME="uwsgi"
if [ ! -n "$NAME" ];then
    echo "no arguments"
    exit;
fi
echo "Restart 94iMM"
ID=`ps -ef | grep "$NAME" | grep -v "$0" | grep -v "grep" | awk '{print $2}'`
for id in $ID
do
kill -9 $id
done
echo "Stop Success"
uwsgi --ini uwsgi.ini
echo  "start Success"
rm -rf cache/*
echo "Clear Cache"
echo "##############################################"
echo "Done"

