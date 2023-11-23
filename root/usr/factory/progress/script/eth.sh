#!/bin/bash

ETHER_WS_FILE=/tmp/ether0_ws_file.txt
ETHER_RS_FILE=/tmp/ether0_rs_file.txt
ret_ether_ws=0
ret_ether_rs=0
ret_ether_ws_gb=0
ret_ether_rs_gb=0
server_ip="192.168.2.61"
TARGET=900

ETH0=`ifconfig -a  | grep mtu | awk '{print  $1}' | sed -n '1p' | sed 's/.$//'`
#WLAN0=`ifconfig -a  | grep mtu | awk '{print  $1}' | sed -n '4p' | sed 's/.$//'`
echo "eth0: $ETH0"
#echo "wlan0:$WLAN0"


ETH0_IP=`ifconfig -a  | grep netmask | awk '{print  $2}' | sed -n '1p'`

route add  -host $server_ip  metric 100 dev $ETH0

echo "发送中..."
iperf3 -c $server_ip -B $ETH0_IP -t 10 -f m -P 4 > $ETHER_WS_FILE
echo "接收中..."
iperf3 -c $server_ip -B $ETH0_IP -R -t 10 -f m -P 4 > $ETHER_RS_FILE 
sleep 0.5

ret_ether_ws=`cat $ETHER_WS_FILE  | grep SUM | awk '{print $6}' | tail -n 1`
ret_ether_rs=`cat $ETHER_RS_FILE  | grep SUM | awk '{print $6}' | tail -n 1`
echo $ret_ether_ws
echo $ret_ether_rs

sleep 1

route del  -host $server_ip  metric 100 dev $ETH0
ret_ether_ws_1=`awk  -v  num1="$ret_ether_ws" -v num2=$TARGET  'BEGIN{print(num1>num2)?"0":"1"}'`
ret_ether_rs_1=`awk  -v  num3="$ret_ether_rs" -v num4=$TARGET  'BEGIN{print(num3>num4)?"0":"1"}'`

if [ $ret_ether_ws_1 -eq 0 ]; then
    if [ $ret_ether_rs_1  -eq 0 ]; then
        echo "<eth:$eth_IP,ws:$ret_ether_ws  rs:$ret_ether_rs>,<PASS>,<0>"
        exit 0
    else
        echo "<eth:$eth_IP,ws:$ret_ether_ws  rs:$ret_ether_rs>,<FAIL>,<-1>"
        exit 1
    fi
else
    echo "<eth:$eth_IP,ws:$ret_ether_ws  rs:$ret_ether_rs>,<FAIL>,<-2>"
    exit 2
fi

echo "<eth:$eth_IP>,<FAIL>,<-3>"
exit 3