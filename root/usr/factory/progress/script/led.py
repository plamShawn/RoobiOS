#!/bin/bash


res=`./op popup bool 灯光检查 检查电源灯亮白/红色。网口灯绿色常亮，黄色闪烁`

if [ $res == "\"true\"" ];
then 
    exit 0
fi
exit 1