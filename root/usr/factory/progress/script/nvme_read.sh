#!/bin/bash

NVME_RS_FILE=/tmp/nvme_read_speed.txt

TARGET_READ=1000

touch $NVME_RS_FILE


dd if=/dev/nvme0n1  of=/dev/null bs=4M count=1000 iflag=direct &>${NVME_RS_FILE}
if [ $? == 0 ]; then
        echo "read is ok"
else
        echo "resd is err"
fi

ret_nvme_rs=`cat ${NVME_RS_FILE} | grep "copied" | awk '{print $10}'`
if [ $? == 0 ]; then
        echo "ret_nvme_rs is ok"
else
        echo "ret_nvme_rs  is err"
fi

ret_nvme_rs_gb=`cat ${NVME_RS_FILE} | grep "copied" | awk '{print $11}'`
if [ $? == 0 ]; then
        echo "ret_nvme_rs_gb is ok"
else
        echo "ret_nvme_rs_gb  is err"
fi

sleep 1

echo "size:${nvme_size} &  R:${ret_nvme_rs}"


ret_nvme_rs_1=`awk  -v  num3="$ret_nvme_rs" -v num4=%s 'BEGIN{print(num3>num4)?"0":"1"}'`
echo "ret_nvme_rs_1: $ret_nvme_rs_1"


if [ "$ret_nvme_rs_gb" == "GB/s" ]; then
        ret_nvme_rs_1=0
fi

if [ "$ret_nvme_rs_1" -eq 0 ]; then
    echo "<nvme_test nvme,rs:$ret_nvme_rs>,<PASS>,<0>"
    exit 0
else   
    echo "<nvme_test,nvme,rs:$ret_nvme_rs>,<FAIL>,<-1>"
    exit 1
fi