#!/bin/bash


res=`./op popup bool 风扇测试 查看风扇是否转动`

if [ $res == "\"true\"" ];
then 
    exit 0
fi
exit 1