#!/bin/bash
echo "[*] Membuat Bootable ISO (Membutuhkan grub-mkrescue di host)..."
mkdir -p iso_build/boot/grub
cp osboot/bzImage iso_build/boot/
cp osboot/single.gz iso_build/boot/
cp osboot/multi.gz iso_build/boot/

cat << 'EOF' > iso_build/boot/grub/grub.cfg
set timeout=15
set default=0
menuentry "Multi-User Mode" {
    linux /boot/bzImage console=tty1
    initrd /boot/multi.gz
}
menuentry "Single-User Mode" {
    linux /boot/bzImage console=tty1
    initrd /boot/single.gz
}
EOF

grub-mkrescue -o osboot/farewell.iso iso_build/ > /dev/null 2>&1
echo "[+] Bootable ISO dibuat di osboot/farewell.iso"
