#!/bin/bash
echo "[*] Membangun Single-User Filesystem..."
mkdir -p osboot initramfs-single
cd initramfs-single
mkdir -p bin dev proc sys etc tmp root
chmod 1777 tmp
chmod 700 root

# Fetch busybox static
wget -q https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox -O bin/busybox
chmod +x bin/busybox
cd bin
for prog in $(./busybox --list); do ln -s busybox $prog; done
cd ..

# Scaffold init shell environment
cat << 'EOF' > init
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
mount -t tmpfs none /tmp
ip link set lo up
ip link set eth0 up
ifconfig eth0 10.0.2.15 netmask 255.255.255.0
route add default gw 10.0.2.2
echo "=== Welcome to Single-User Mode ==="
exec setsid cttyhack /bin/sh
EOF
chmod +x init

find . | cpio -H newc -o | gzip -9 > ../osboot/single.gz
cd ..
echo "[+] Single filesystem dibuat di osboot/single.gz"
