#!/bin/bash

(for i in {1..100}; do
   aplay -D plughw:0,3 test_sound.wav
done) &

res=`./op popup bool 声音测试 是否能听见声音`

if [ $res == "\"true\"" ];
then 
    exit 0
fi
exit 1