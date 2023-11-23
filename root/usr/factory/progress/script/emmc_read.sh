#!/bin/bash
    
EMMC_RS_FILE=/tmp/emmc_read_speed.txt
TARGET=200

touch $EMMC_RS_FILE

dd if=/dev/mmcblk0  of=/dev/null bs=4M count=200 iflag=direct &>${EMMC_RS_FILE}
if [ $? == 0 ]; then
        echo "read is ok"
else
        echo "resd is err"
fi

ret_emmc_rs=`cat ${EMMC_RS_FILE} | grep "copied" | awk '{print $10}'`
if [ $? == 0 ]; then
        echo "ret_emmc_rs is ok"
else
        echo "ret_emmc_rs  is err"
fi
    
ret_emmc_rs_gb=`cat ${EMMC_RS_FILE} | grep "copied" | awk '{print $11}'`
if [ $? == 0 ]; then
        echo "ret_emmc_rs_gb is ok"
else
        echo "ret_emmc_rs_gb  is err"
fi

sleep 1

echo "size:${emmc_size} &  R:${ret_emmc_rs}"


ret_emmc_rs_1=`awk  -v  num3="$ret_emmc_rs" -v num4=$TARGET 'BEGIN{print(num3>num4)?"0":"1"}'`
echo "ret_emmc_rs_1: $ret_emmc_rs_1"


if [ "$ret_emmc_rs_gb" == "GB/s" ]; then
        ret_emmc_rs_1=0
    echo 5000 emmc rs
fi

if [ "$ret_emmc_rs_1" -eq 0 ]; then
    echo "<emmc_test emmc,rs:$ret_emmc_rs>,<PASS>,<0>"
    exit 0
else   
    echo "<emmc_test,emmc,rs:$ret_emmc_rs>,<FAIL>,<-1>"
    exit 1
fi