FROM archlinux

RUN pacman -Syu --noconfirm \
        arch-install-scripts \
        sudo wget && \
        wget -O /etc/pacman.d/mirrorlist "https://archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on" && \
        sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist