#!/bin/bash

echo "I: Start testing Bluetooth"

TIMEOUT=2
RESULT_FILE=/tmp/bt_result.txt
DEVFILE=/tmp/bt_dev.txt


for i in `seq ${TIMEOUT}`;do
    rm -rf ${RESULT_FILE}
    echo "I: Waiting for Bluetooth adapter... `expr ${TIMEOUT} - ${i}`"

    systemctl start bluetooth
    sleep 2
    bluetoothctl info > $DEVFILE &
    sleep 1
    kill %1
    sleep 1
    devices=`cat $DEVFILE`
    if [ "$devices" == "" ] || [ "`echo $devices | grep "No default controller available" `" != "" ]; then
        echo "<bt_no_dev>,<FAIL>,<-1>"
        exit 1
    fi 
        echo "I: Bluetooth adapter is found"
        BT_ADDR=`bluetoothctl list | awk '{print $2}'`
        if [ "$BT_ADDR" ]; then
            echo "I: BT Address is ${BT_ADDR}"
            echo "I: Scanning remote BT device..."
            stdbuf -i0 -o0 -e0  bluetoothctl scan on > $RESULT_FILE & 
           
            sleep 5
            kill %1
            sleep 1
            line_count=$(wc -l < $RESULT_FILE)
            echo $line_count
            if [ $line_count -gt 3 ]; then
                echo "I: List remote BT device:"
                echo "<bt_test, ADDRESS ${BT_ADDR}>,<PASS>,<0>"
                exit 0
            else
                echo "I: There is no remote BT device"
                echo "<bt_no_remote>,<FAIL>,<-3>"
                exit 3
            fi
        else
            echo "I: BT Address is NULL"
            echo "<bt_no_addr>,<FAIL>,<-2>"
            exit 2
        fi
    sleep 1
done

echo "<bt_no_dev>,<FAIL>,<-1>"
exit 1