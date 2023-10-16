#!/bin/bash

echo "Start!"

OUTPUT_FILE=Roobi.img

echo "deb http://cz.archive.ubuntu.com/ubuntu lunar main universe" | sudo tee -a   /etc/apt/sources.list

apt update
apt install pacman-package-manager -y
apt install arch-install-scripts -y
apt install kpartx -y
apt install btrfs-progs -y
# ----------------------- configure pacman -------------------------

echo "[core]
Include = /etc/pacman.d/mirrorlist
[extra]
Include = /etc/pacman.d/mirrorlist
[options]
SigLevel = Never
" >> /etc/pacman.conf

mkdir -p /etc/pacman.d

echo "Server = https://mirrors.aliyun.com/archlinux/\$repo/os/\$arch
Server = https://mirrors.bfsu.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.cqu.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.hit.edu.cn/archlinux/\$repo/os/\$arch
Server = https://mirrors.jlu.edu.cn/archlinux/\$repo/os/\$arch
" > /etc/pacman.d/mirrorlist

# ^^^^^^^^^^^^^^^^^^^^^^^^ configure pacman ^^^^^^^^^^^^^^^^^^^^^^^^

# ------------------------ set disk --------------------------------

mount_image() {
    sudo kpartx -a "$OUTPUT_FILE"

    for i in /sys/class/block/loop*
    do
        if [[ "$(cat "$i/loop/backing_file")" == "$(realpath "$OUTPUT_FILE")" ]]
        then
            echo "$(basename "$i")"
            return
        fi
    done
}

truncate -s 5G "$OUTPUT_FILE"
sgdisk --clear --new=1::150M --typecode=1:ef00 --new=2:: "$OUTPUT_FILE"

TARGET_DEV="/dev/mapper/`mount_image`"

echo TARGET_DEV: $TARGET_DEV

EFI="${TARGET_DEV}p1"
ROOT="${TARGET_DEV}p2"

mkfs.fat -F 32 $EFI
mkfs.btrfs $ROOT

mount -o compress=zstd  $ROOT /mnt
mkdir /mnt/boot
mount  $EFI /mnt/boot


# ^^^^^^^^^^^^^^^^^^^^^^^^ set disk ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


# ------------------------ install base ----------------------------

# base
pacstrap -K /mnt base linux linux-firmware intel-ucode electron sudo  efibootmgr networkmanager xorg-server xorg-xinit openssh  adobe-source-han-sans-cn-fonts noto-fonts adobe-source-han-sans-kr-fonts parted pigz usbutils vim nano lsof iperf3  stress bc net-tools alsa-utils bluez bluez-utils btrfs-progs gptfdisk ntfs-3g python python-pyqt5
genfstab -U /mnt >> /mnt/etc/fstab
sed -i "s/^.*swap.*$//g" /mnt/etc/fstab

# boot 
echo "Createboot ..."

arch-chroot /mnt mkdir -p /boot/loader/entries
arch-chroot /mnt bash -c 'echo "title Roobi OS
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img" > /boot/loader/entries/arch.conf'
arch-chroot /mnt bash -c  'echo "options root=UUID=$(blkid -o value -s UUID `mount | grep " / "`) rw splash quite" >> /boot/loader/entries/arch.conf'
arch-chroot /mnt bootctl --path=/boot install


echo "Generate locale..."
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

echo "Ignore power event"
echo HandlePowerKey=ignore >> /mnt/etc/systemd/logind.conf

echo "Set up user accounts..."
arch-chroot /mnt useradd -m -G input ps
echo ps:ps | arch-chroot /mnt chpasswd

arch-chroot /mnt mkdir -p /etc/sudoers.d
arch-chroot /mnt bash -c 'echo "ps ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/ps'

sudo cp -r "./root/." /mnt

########################## server ####################################
echo "enable systemctl..."
arch-chroot /mnt systemctl enable systemd-timesyncd NetworkManager growroot roobi roobiChecker

echo "Clean up..."
rm /mnt/var/cache/pacman/pkg/*
rm /mnt/var/lib/pacman/sync/*.db





# ^^^^^^^^^^^^^^^^^^^^^^^^ install base ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

find_root_part() {
    local ROOT_PART
    ROOT_PART="$(sgdisk -p "$1" | grep "rootfs" | tail -n 1 | tr -s ' ' | cut -d ' ' -f 2)"
    if [[ -z $ROOT_PART ]]
    then
        ROOT_PART="$(sgdisk -p "$1" | grep -e "8300" -e "EF00" | tail -n 1 | tr -s ' ' | cut -d ' ' -f 2)"
    fi
    echo $ROOT_PART
}


SHRINK_SIZE=1
while sudo btrfs filesystem resize -${SHRINK_SIZE} /mnt
do
    SHRINK_SIZE=$(( $(sudo btrfs filesystem usage -b /mnt | grep "Free (estimated)" | sed "s/.*min: \([0-9]*\).*/\1/") / 2 ))
done
DEVICE_SIZE=$(( $(sudo btrfs filesystem usage -b /mnt | grep "Device size" | tr -s ' ' | cut -d ' ' -f 4) ))

echo "Unmount filesystem..."
sudo umount -lR /mnt

echo "Unmount image..."
sudo kpartx -d "$OUTPUT_FILE"

echo "Update partition table..."
ROOT_PART="$(find_root_part "$OUTPUT_FILE")"
SECTOR_SIZE="$(sgdisk -p "$OUTPUT_FILE" | grep "Sector size (logical):" | tail -n 1 | tr -s ' ' | cut -d ' ' -f 4)"
START_SECTOR="$(sgdisk -i "$ROOT_PART" "$OUTPUT_FILE" | grep "First sector:" | cut -d ' ' -f 3)"
NEW_SIZE=$(( $START_SECTOR * $SECTOR_SIZE + $DEVICE_SIZE ))
cat << EOF | parted ---pretend-input-tty "$OUTPUT_FILE" > /dev/null 2>&1
resizepart $ROOT_PART 
${NEW_SIZE}B
yes
EOF

echo "Shrink image..."
END_SECTOR="$(sgdisk -i "$ROOT_PART" "$OUTPUT_FILE" | grep "Last sector:" | cut -d ' ' -f 3)"
# leave some space for the secondary GPT header
FINAL_SIZE="$(( ($END_SECTOR + 34) * $SECTOR_SIZE ))"
truncate "--size=$FINAL_SIZE" "$OUTPUT_FILE" > /dev/null

echo "Fix backup GPT table..."
sgdisk -ge "$OUTPUT_FILE" &> /dev/null || true

echo "Test partition table for additional issue..."
sgdisk -v "$OUTPUT_FILE" > /dev/null

echo "Compress image."
xz -fT 0 "$OUTPUT_FILE"

echo "Image build completed."
