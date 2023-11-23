#!/bin/bash
echo "I: Start testing DDR"
SIZE=`cat /proc/zoneinfo | grep present | awk 'BEGIN{a=0}{a+=$2}END{print a}'`
 let SIZE=${SIZE}*4/1024
 if [[ $SIZE -gt 7900 ]]&&[[ $SIZE -lt 8300 ]]; then
        echo "<ddr_test, ${SIZE}MB>,<PASS>,<0>"
        exit 0
 fi
echo "<ddr_test, ${SIZE}MB>,<FAIL>,<-1>" >&2
exit 1