#!/bin/bash

BLOCK_DEV=/tmp/block_dev2.0.txt
USBHOST_WS_FILE=/tmp/usb20host_write_speed.txt
USBHOST_RS_FILE=/tmp/usb20host_read_speed.txt
USB20_FLAG=0
USB20_RET=0
TMPFILE=/tmp_test.img

TARGET_RED=10
TARGTET_WRITE=5

### 鼠标占用一个 USB2.0 的口
### 获取得到目前挂载的U盘：sda sdb sdc
cat /proc/partitions | grep "^[^a-zA-Z].*[^0-9]$" | awk '{print $4}' > $BLOCK_DEV

### 在4个sdx中查询
for line in `cat $BLOCK_DEV`
do
    #### 检测这个sdx是不是usb
    DEV_TYPE=`udevadm info --query=all --name=/dev/$line | grep ID_BUS | cut -d "=" -f2`
    # USB devices
    if [[ $DEV_TYPE = "usb" ]];then
        echo "test device $line"
        #### 查看U盘大小：1.9G
        BLOCK_SIZE=`lsblk | grep $line | awk 'NR==1 {print $4}'`
        echo "devices block size = $BLOCK_SIZE"

        DEV_PRO_SPEED=`udevadm info -a /dev/$line | grep speed | sed -n '1p' | awk -F "\"" 'NR==1 {print $2}'| awk -F "," 'NR==1 {print $1}'`
        echo "DEV_PRO_SPEED = $DEV_PRO_SPEED"
        
        
        ############## 2.0 ##########################
        
        #### 2.0的处理方式
        if [ $DEV_PRO_SPEED = "480" ];then
            ##### 2.0 标志位，表示有2.0U盘
            let USB20_FLAG=$USB20_FLAG+1
            echo "usb2.0 ${USB20_FLAG} devices test"
            ##### 跑2.0的dd写速
            DEVICE=/dev/$line

            if blkid | grep -q "$DEVICE"; then
                echo "File system exists"
                MAX_SIZE=0
                MAX_PART=""
                for part in $(ls ${DEVICE}*); do
                    if blkid $part | grep -q "ext4" || blkid $part | grep -q "ext3" || blkid $part | grep -q "btrfs" || blkid $part | grep -q "exfat" ; then
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

            ##### 跑2.0的dd读速
            dd if=/dev/${line} of=/dev/null bs=4M count=10 iflag=direct &> ${USBHOST_RS_FILE}
            if [ $? == 0 ]; then
                echo "devices read is ok"
            else
                echo "devices read is err"
            fi
            ##### 获取读速
            RS_SPEED=`cat ${USBHOST_RS_FILE} | grep "copied" | awk '{print $10}' | awk -F "," 'NR==1 {print $1}'`
            echo "devices read speed = $RS_SPEED"


            # Test write speed
            if [ "$MOUNT_POINT" = "" ];then
                echo "Unable to mount USB partition. Please format it as one of the following types: ext4, ext3, btrfs, or exfat."
                echo "<usb_test,USB3.0, ${RS_SPEED}M/s>,<FAIL>,<-5>"
                exit 5
                continue
            fi
            dd if=/dev/zero of="$MOUNT_POINT/$TMPFILE" bs=4M count=5 oflag=direct &> ${USBHOST_WS_FILE}

            if [ $? == 0 ]; then
                echo "devices write is ok"
            else
                echo "devices write is err"
            fi
            rm $MOUNT_POINT/$TMPFILE
            WS_SPEED=`cat ${USBHOST_WS_FILE} | grep "copied" | awk '{print $10}' | awk -F "," 'NR==1 {print $1}'`
            echo "devices write speed = $WS_SPEED "


            # 要求USB2.0 写 > 5M/s，读 > 10M/s 
            ##### bc用于浮点数比较，正确为1，错误为0
            if [[ `echo "$WS_SPEED > $TARGTET_WRITE" | bc` -eq 1 ]]&&[[ `echo "$RS_SPEED > $TARGET_RED" | bc` -eq 1 ]];then
                ###### usb2.0读写通过标志位
                USB20_RET=1
            else
                ###### usb2.0读写测试不过 
                USB20_RET=0
            fi
        fi
        

        rm -rf $USBHOST_WS_FILE $USBHOST_RS_FILE
#        rm -rf /tmp/${line}1/zero.img 
        
#        umount /tmp/${line}1
#        rm -rf /tmp/${line}1
    fi
done

## 2.0不识别  -1
if [ $USB20_FLAG = "0" ];then
    echo "<usb2.0_test_no_dev>,<FAIL>,<-2>"
    exit 2
fi
## 2.0 通过
if [ $USB20_FLAG = "1" ]&&[ $USB20_RET = "1" ];then
    echo "<usb2.0_test W=${WS_SPEED}M/s,R=${RS_SPEED}M/s>,<PASS>,<0>"
    exit 0
fi
## 2.0读写不通过
if [ $USB20_FLAG = "1" ]&&[ $USB20_RET = "0" ];then
    echo "<usb2.0_test W=${WS_SPEED}M/s,R=${RS_SPEED}M/s>,<FAIL>,<-1>"
    exit 1
fi