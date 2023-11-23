#!/bin/bash
DEVICE="/dev/mmcblk0"
TMPFILE="/tmp_testfile"
WRITE_FILE=/tmp/emmc_write_speed.txt
TARGET_SPEED=100

# Check if file system exists
if blkid | grep -q "$DEVICE"; then
    echo "File system exists, writing"

    # Find the largest ext4 partition
    MAX_SIZE=0
    MAX_PART=""
    for part in $(ls ${DEVICE}p*); do
    if blkid $part | grep -q "ext4" || blkid $part | grep -q "ext3" || blkid $part | grep -q "btrfs" || blkid $part | grep -q "exfat" || blkid $part | grep -q "vfat" ; then
        SIZE=$(df $part | tail -n 1 | awk '{print $2}')
        if (( SIZE > MAX_SIZE )); then
        MAX_SIZE=$SIZE
        MAX_PART=$part
        fi
    fi
    done

    if [ -z "$MAX_PART" ]; then
    echo "No ext4 | ext3 | btrfs | exfat | vfat partition found, exiting."
    exit 1
    fi

    # Mount point of the largest ext4 partition
     MOUNT_POINT=$(df | grep $MAX_PART | awk '{print $6}')
            if [ "$MOUNT_POINT" = "" ];then
                echo $MAX_PART not mount and try to mount
                mkdir -p /mnt/$MAX_PART
                mount $MAX_PART /mnt/$MAX_PART
                MOUNT_POINT=$(df | grep $MAX_PART | awk '{print $6}')
            fi

     echo testing $MOUNT_POINT/$TMPFILE

    # Test write speed
    dd if=/dev/zero of="$MOUNT_POINT/$TMPFILE" bs=4M count=100 oflag=direct &> ${WRITE_FILE}

    # Clean up
    rm "$MOUNT_POINT/$TMPFILE"

else
    echo "No file system found, writing directly to device."
    dd if=/dev/zero of="$DEVICE" bs=4M count=100 oflag=direct &> ${WRITE_FILE}
fi

cur_write=`cat ${WRITE_FILE} | grep MB/s | awk 'NR=1{print$10}'`

if [[ `echo "$cur_write > $TARGET_SPEED" | bc` -eq 1 ]]; then
    echo "<emmc_test,W:${cur_write}MB/s,<PASS>,<0>"
    exit 0
else
    echo "<emmc_test,W:${cur_write}MB/s,<FAIL>,<-1>"
    exit  1
fi