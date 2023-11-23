#!/bin/bash

PREFIX="00E04C06"
CONF="linuxpg/8168HEF.cfg"
check_mac(){
    local dev=`nmcli dev | grep ethernet | awk '{print $1}'`

    mac=`ip a show $dev| grep ether | awk 'NR==1 {print $2}' | sed 's/://g'`
    perf=`echo ${mac:0:8} | awk '{print toupper($0)}'`
    if [ "$perf" == "$PREFIX" ];then
        echo "检测通过"
        result=0
        exit 0
    fi
}

check_mac
echo "获取mac地址中..."
mac_addr=`curl "http://120.24.183.202:9090/testprogram/mac?token=d1120f27-0c90-403f-b2b9-a83346dda0e9&device=PS006&count=1&hex=1&text=1" | sed 's/"//g'`

if [ "$?" -ne "0" ]; then
    echo "网络错误..."
    exit 1
fi

str=`echo $mac_addr | sed 's/../& /g;s/ $//'`

sed -i "1s/.*/NODEID = $str/" $CONF

rmmod r8169
if [ $? == "0" ];then
    echo "rmmod r8169"
    sleep 0.5
else
    echo "rmmod r8169 fail"
fi
insmod ./linuxpg/pgdrv.ko
if [ $? == "0" ];then
    sleep 0.5
    echo "insmod pgdrv"
else 
    echo "insmod pgdrv FAIL"
fi
cd linuxpg
./rtnicpg-x86_64 /efuse /w
result=1
if [ $? == "0" ];then
    echo "<FLASH>,<PASS>,<0>"
else
    echo "<FLASH>,<FAIL>,<-1>"
fi

rmmod pgdrv
sleep 0.5
modprobe  r8169
if [ $result == "0" ]; then
    echo 挂载网卡成功
else
   echo 挂载网卡失败
fi
sleep 1
check_mac