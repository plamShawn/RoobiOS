#!/bin/bash
echo "I: Start testing CPU"
FREQ=2200000
MODEL="Intel(R) Celeron(R) J4125 CPU @ 2.00GHz"
TOTAL=4
cpu_num=`cat /proc/cpuinfo | grep processor | awk 'END {print}' | awk '{print $3}'`
######## cpu 核心数 ########
total=`expr $cpu_num + 1`
if [[ $total != $TOTAL ]];then
    echo "<cpu_test, CPUs ${total}>,<FAIL>,<-1>"
    exit 1
fi
######## cpu 型号 ########
model=`cat /proc/cpuinfo | grep "model name" | awk 'END {print}' | awk -F ':' '{print $2}' | awk '{$1=$1;print}'`

if [[ $model != $MODEL ]];then
    echo "<cpu_test, model ${model}>,<FAIL>,<-2>"
    exit 2
fi
######## cpu 频率 ########
echo running stress...
stress --cpu 4 --timeout 3 > /dev/null 2>&1 & 
sleep 0.5
sucess_count=0
for i in $(seq 0 3)
do
    cpuinfo_cur_freq=`cat /sys/bus/cpu/devices/cpu$i/cpufreq/scaling_cur_freq`
    echo cpu$i=$cpuinfo_cur_freq
    if [[ $cpuinfo_cur_freq -ge $FREQ ]];then
        echo cpu$i ok
        let sucess_count=$sucess_count+1
    else
        echo cpu$i fail
    fi
done
if [[ $sucess_count -eq $TOTAL ]];then
    sleep 0.1
    echo "<cpu_test, CPUs ${total}, model ${model}, sucess_count ${sucess_count}>,<PASS>,<0>"
    exit 0
else
    sleep 0.1
    echo "<cpu_test,sucess_count ${sucess_count} >,<FAIL>,<-3>"
    exit 3
fi