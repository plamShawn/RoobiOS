#!/bin/bash

set -e

rm /tmp/mic_test.wav || true
echo 录音中...
arecord -Dhw:0,0 -d 4 -f cd -r 44100 -c 2 -t wav /tmp/mic_test.wav 2> /dev/null


echo 请等待...
sleep 1


echo 播放中...
aplay -D plughw:0,0 /tmp/mic_test.wav 2> /dev/null


if [ $? -eq 0 ]; then
    res=`./op popup bool 录音测试 是否有声音`
    if [ $res == "\"true\"" ]; then
        echo "成功"
        exit 0
    fi
    echo "手动失败"
    exit 2
    
else
   sleep 1
   echo "播放失败"
   exit 1
fi