#!/bin/bash
    
BLOCK_DEV=/tmp/block_dev.txt
USBHOST_WS_FILE=/tmp/usbhost_write_speed.txt
USBHOST_RS_FILE=/tmp/usbhost_read_speed.txt
USB20_FLAG=0
USB30_FLAG=0
USB20_RET=0
USB30_RET=0
TMPFILE=/tmp_test.img
TARGET_RED=100
TARGTET_WRITE=55


cat /proc/partitions | grep "^[^a-zA-Z].*[^0-9]$" | awk '{print $4}' > $BLOCK_DEV

for line in `cat $BLOCK_DEV`
do
    DEV_TYPE=`udevadm info --query=all --name=/dev/$line | grep ID_BUS | cut -d "=" -f2`
    # USB devices
    if [[ $DEV_TYPE = "usb" ]];then
        echo "test device $line"

        BLOCK_SIZE=`lsblk | grep $line | awk 'NR==1 {print $4}'`
        echo "devices block size = $BLOCK_SIZE"

        DEV_PRO_SPEED=`udevadm info -a /dev/$line | grep speed | sed -n '1p' | awk -F "\"" 'NR==1 {print $2}'| awk -F "," 'NR==1 {print $1}'`

        if [ $DEV_PRO_SPEED = "5000" ];then
            let USB30_FLAG=$USB30_FLAG+1
            echo "usb3.0 devices test $line"
            DEVICE=/dev/$line
            ######## 判断是否有文件系统 找出最大的分区 ##########
            if blkid | grep -q "$DEVICE"; then
                echo "File system exists"
                MAX_SIZE=0
                MAX_PART=""
                for part in $(ls ${DEVICE}*); do
                    if blkid $part | grep -q "ext4" || blkid $part | grep -q "ext3" || blkid $part | grep -q "btrfs" || blkid $part | grep -q "exfat" || blkid $part | grep -q "vfat" ; then
                        SIZE=$(df $part | tail -n 1 | awk '{print $2}')
                        if (( SIZE > MAX_SIZE )); then
                            MAX_SIZE=$SIZE
                            MAX_PART=$part
                        fi
                    fi
                done
            else
                echo "No file system exists. Continue"
                continue
            fi
            if [ -z "$MAX_PART" ]; then
                echo " $DEVICE No ext4 | ext3 | btrfs | exfat partition found, exiting."
                continue
            fi
            MOUNT_POINT=$(df | grep $MAX_PART | awk '{print $6}')
            if [ "$MOUNT_POINT" = "" ];then
                echo $MAX_PART not mount and try to mount
                mkdir -p /mnt/$MAX_PART
                mount $MAX_PART /mnt/$MAX_PART
                MOUNT_POINT=$(df | grep $MAX_PART | awk '{print $6}')
            fi

            dd if=/dev/${line} of=/dev/null bs=4M count=100 iflag=direct &> ${USBHOST_RS_FILE}
            if [ $? == 0 ]; then
                echo "devoces read is ok"
            else
                echo "devoces resd is err"
            fi
            RS_SPEED=`cat ${USBHOST_RS_FILE} | grep "copied" | awk '{print $10}' | awk -F "," 'NR==1 {print $1}'`
            echo "devices read speed = $RS_SPEED"
            # Test write speed
            if [ "$MOUNT_POINT" = "" ];then
                echo "Unable to mount USB partition. Please format it as one of the following types: ext4, ext3, btrfs, or exfat."
                echo "<usb_test,USB3.0, ${RS_SPEED}M/s>,<FAIL>,<-5>"
                exit 5
                continue
            fi
            dd if=/dev/zero of="$MOUNT_POINT/$TMPFILE" bs=4M count=100 oflag=direct &> ${USBHOST_WS_FILE}
            rm $MOUNT_POINT/$TMPFILE
            WS_SPEED=`cat ${USBHOST_WS_FILE} | grep "copied" | awk '{print $10}' | awk -F "," 'NR==1 {print $1}'`
            echo "devices write speed = $WS_SPEED "
            if [[ `echo "$WS_SPEED >$TARGTET_WRITE" | bc` -eq 1 ]]&&[[ `echo "$RS_SPEED > $TARGET_RED" | bc` -eq 1 ]];then
                USB30_RET=1
            else
                echo "<usb_test,USB3.0,${WS_SPEED}M/s,${RS_SPEED}M/s,$BLOCK_SIZE>,<FAIL>,<-4>"
                exit 4
            fi
        fi
    fi
done

if [ $USB30_FLAG = "0" ];then
    echo "<usb30_test>,<FAIL>,<-2>"
    exit 2
fi

if [ $USB30_FLAG = "1" ]&&[ $USB30_RET = "1" ];then
    echo "<usb30 x1>,<FAIL>,<-1>"
    exit 1
fi

if [ $USB30_FLAG = "2" ]&&[ $USB30_RET = "1" ];then
    echo "<usb30_test>,<PASS>,<0>"
    exit 0
fi
exit 1