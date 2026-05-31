#!/bin/bash
echo "[*] Downloading and Compiling Linux Kernel 6.1.1..."
mkdir -p osboot
wget -q --show-progress https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.1.tar.xz
tar -xf linux-6.1.1.tar.xz
cd linux-6.1.1

# Generate konfigurasi dasar
make defconfig

# Mengaktifkan FUSE support di kernel agar requirement FUSE dapat terpenuhi
sed -i 's/# CONFIG_FUSE_FS is not set/CONFIG_FUSE_FS=y/' .config

# MEMATIKAN WERROR: Mencegah kompilasi berhenti karena warning sepele dari kompiler baru
scripts/config --disable WERROR

# Mulai kompilasi menggunakan seluruh core CPU yang tersedia
make -j$(nproc) bzImage

cp arch/x86/boot/bzImage ../osboot/bzImage
cd ..
echo "[+] Kernel bzImage siap di osboot/bzImage"
