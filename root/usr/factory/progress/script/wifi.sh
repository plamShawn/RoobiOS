#!/bin/bash

username=PALMSHELL_5G

password="PALMSHELL"

SERVER_IP="192.168.31.180"

TARGET=600

nmcli dev | grep wifi

if [ $? -ne 0 ];then
    echo "没有找到设备" >&2
    exit 1
fi

sleep 10

nmcli dev wifi connect $username password $password
sleep 1
ETHER_WS_FILE=/tmp/wlan_ws_file.txt
ETHER_RS_FILE=/tmp/wlan_rs_file.txt
WLAN0=/tmp/wlan0_test.txt
ret_ether_ws=0
ret_ether_rs=0
ret_ether_ws_gb=0
ret_ether_rs_gb=0
ret_ether_ws_1=9
ret_ether_ws_1=9
server_ip=$SERVER_IP

WLAN1=`nmcli device | grep "wifi " | awk {'print $1'}`
echo "eth0: $ETH0"
echo "eth1: $ETH1"
echo "wlan0:$WLAN1"

WLAN0_IP=`ifconfig $WLAN1 | sed -n  '2p' | awk '{print $2}'`


echo "wlan0_ip: $WLAN0_IP"


route add  -host $server_ip   metric 100 dev $WLAN1

echo "iperf3 -c $server_ip  -B $WLAN0_IP  -t 10   > $ETHER_WS_FILE"
iperf3 -c $server_ip  -B $WLAN0_IP  -t 10 -P 4 > $ETHER_WS_FILE

#pid=`ps -a | grep iperf3 | awk '{print $1}'`
#taskset -pc 2,3 $pid
#sleep 0.5

ret_ether_ws=`cat $ETHER_WS_FILE  | grep SUM | awk '{print $6}' | tail -n 1`
if [ $? == 0 ]; then
    echo "ret_ether_ws is ok"
else
    echo "ret_ether_ws  is err"
fi
echo "ret_ether_ws : $ret_ether_ws"

ret_ether_ws_gb=`cat $ETHER_WS_FILE | grep SUM | awk '{print $7}' | tail -n 1`
if [ $? == 0 ]; then
    echo "ret_ether_ws_gb is ok"
else
    echo "ret_ether_ws_gb  is err"
fi

echo "iperf3 -c $server_ip  -B $WLAN0_IP -R -t 10 > $ETHER_RS_FILE"
iperf3 -c $server_ip  -B $WLAN0_IP -R -t 10 -P 4 > $ETHER_RS_FILE

ret_ether_rs=`cat $ETHER_RS_FILE  | grep SUM | awk '{print $6}' | tail -n 1`
if [ $? == 0 ]; then
    echo "ret_ether_rs is ok"
else
    echo "ret_ether_rs  is err"
fi
echo "ret_ether_rs : $ret_ether_rs"

ret_ether_rs_gb=`cat $ETHER_RS_FILE | grep SUM | awk '{print $7}' | tail -n 1`
if [ $? == 0 ]; then
    echo "ret_ether_rs_gb is ok"
else
    echo "ret_ether_rs_gb  is err"
fi

route del  -host $server_ip  metric 100 dev $WLAN0
ret_ether_ws_1=`awk  -v  num1="$ret_ether_ws" -v num2=$TARGET  'BEGIN{print(num1>num2)?"0":"1"}'`
ret_ether_rs_1=`awk  -v  num3="$ret_ether_rs" -v num4=$TARGET  'BEGIN{print(num3>num4)?"0":"1"}'`

if [ $ret_ether_ws_1 -eq 0 ]; then
    if [ $ret_ether_rs_1  -eq 0 ]; then
        echo "<wlan0_test,ws:$ret_ether_ws  rs:$ret_ether_rs>,<PASS>,<0>"
        exit 0
    else
        echo "<wlan0_test,ws:$ret_ether_ws  rs:$ret_ether_rs>,<FAIL>,<-1>"
        exit 1
    fi
else
    echo "<wlan0_test,ws:$ret_ether_ws  rs:$ret_ether_rs>,<FAIL>,<-2>"
    exit 2
fi

echo "<wlan0_test>,<FAIL>,<-3>"
exit 3