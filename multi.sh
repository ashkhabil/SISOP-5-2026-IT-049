#!/bin/bash
echo "[*] Membangun Multi-User Filesystem..."
mkdir -p osboot initramfs-multi
cd initramfs-multi || exit

# Scaffold hirarki direktori
mkdir -p bin dev proc sys etc tmp root home/{henn,hann,viii,kids} var/run etc/apk
chmod 1777 tmp
chmod 700 root

# Fetch busybox static
wget -q https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox -O bin/busybox
chmod +x bin/busybox
cd bin || exit
for prog in $(./busybox --list); do ln -s busybox $prog; done
cd ..

# Setup Package Manager 'party' (Absolute Static Fetch)
echo "[*] Mendownload package manager 'party' secara absolut..."
APK_URL="https://dl-cdn.alpinelinux.org/alpine/v3.18/main/x86_64/apk-tools-static-2.14.4-r0.apk"

wget -q --show-progress "$APK_URL" -O apk-tools.apk || { echo "[-] FATAL: Gagal mendownload apk-tools dari internet host-mu."; exit 1; }
tar -xzf apk-tools.apk sbin/apk.static 2>/dev/null || { echo "[-] FATAL: Gagal mengekstrak apk-tools. File korup."; exit 1; }

mv sbin/apk.static bin/party || { echo "[-] FATAL: Gagal memindahkan binary."; exit 1; }
chmod +x bin/party

rm -f apk-tools.apk
echo "http://dl-cdn.alpinelinux.org/alpine/v3.18/main" > etc/apk/repositories
echo "http://dl-cdn.alpinelinux.org/alpine/v3.18/community" >> etc/apk/repositories

cat << EOF > etc/passwd
root:x:0:0:root:/root:/bin/sh
henn:x:1001:1001:henn:/home/henn:/bin/sh
hann:x:1002:1002:hann:/home/hann:/bin/sh
viii:x:1003:1003:viii:/home/viii:/bin/sh
kids:x:1004:1004:kids:/home/kids:/bin/sh
EOF

# Using pre-computed MD5 hashes to avoid perl escaping issues across different shells
cat << EOF > etc/shadow
root:*:19000:0:99999:7:::
henn:*:19000:0:99999:7:::
hann:*:19000:0:99999:7:::
viii:*:19000:0:99999:7:::
kids:*:19000:0:99999:7:::
EOF

echo "ttyS0" > etc/securetty

# Implementasi ACL strict melalui UNIX Group Matrix
cat << EOF > etc/group
root:x:0:
henn:x:1001:
hann:x:1002:henn
viii:x:1003:henn,hann
kids:x:1004:henn,hann,viii
EOF

# Hak akses hirarki folder. Membutuhkan hak akses elevated (sudo) di sistem host
chmod 755 home
sudo chown 1001:1001 home/henn && sudo chmod 770 home/henn
sudo chown 1002:1002 home/hann && sudo chmod 770 home/hann
sudo chown 1003:1003 home/viii && sudo chmod 770 home/viii
sudo chown 1004:1004 home/kids && sudo chmod 770 home/kids

# TLS bypass dan Banner

# 1. Simpan gambar mentah ke /etc/motd (Aman dari eksekusi bash)
cat << 'MOTD_EOF' > etc/motd
  _____                             _ _   ____            _         
 |  ___|_ _ _ __ _____      _____| | | |  _ \ __ _ _ __| |_ _   _ 
 | |_ / _` | '__/ _ \ \ /\ / / _ \ | | | |_) / _` | '__| __| | | |
 |  _| (_| | | |  __/\ V  V /  __/ | | |  __/ (_| | |  | |_| |_| |
 |_|  \__,_|_|  \___| \_/\_/ \___|_|_| |_|   \__,_|_|   \__|\__, |
                                                            |___/ 
MOTD_EOF

# 2. Buat /etc/profile yang bersih untuk membaca motd
cat << 'EOF' > etc/profile
alias wget="wget --no-check-certificate"
echo ""
echo "Welcome, $USER"
EOF

# Setup DNS
cat << 'EOF' > etc/resolv.conf
nameserver 10.0.2.3
nameserver 8.8.8.8
EOF
chmod 644 etc/resolv.conf

# Init
cat << 'EOF' > init
#!/bin/sh
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev
mount -t tmpfs none /tmp

# Konfigurasi Jaringan Statis
ip link set lo up
ip link set eth0 up
ifconfig eth0 10.0.2.15 netmask 255.255.255.0
route add default gw 10.0.2.2

# Injeksi DNS QEMU Internal
echo "nameserver 10.0.2.3" > /etc/resolv.conf

# Set Kata Sandi Secara Native (Bypass ketidakcocokan Host-Guest)
echo "root:root123" | chpasswd
echo "henn:henn123" | chpasswd
echo "hann:hann123" | chpasswd
echo "viii:viii123" | chpasswd
echo "kids:kids123" | chpasswd

# Koreksi Hak Akses (Dieksekusi oleh Guest OS)
chown -R 1001:1001 /home/henn
chown -R 1002:1002 /home/hann
chown -R 1003:1003 /home/viii
chown -R 1004:1004 /home/kids
chmod 750 /home/*

# Sistem Respawn
while true; do
    /bin/getty -n -l /bin/login 115200 ttyS0
done
EOF
chmod +x init

# Script tes FUSE
cat << 'EOF' > root/fuse_test.sh
#!/bin/sh
echo "[*] Inisialisasi Database Package Manager..."
mkdir -p /lib/apk/db /var/cache/apk /etc/apk
party --allow-untrusted --initdb add

echo "[*] Update dan Install FUSE/GCC..."
party --allow-untrusted update
party --allow-untrusted add fuse fuse-dev gcc musl-dev

echo "[*] Compiling Hello FUSE..."
# (Kode C FUSE dan eksekusinya tetap di bawah sini)
cat << 'C_EOF' > /root/hello.c
#define FUSE_USE_VERSION 30
#include <fuse.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
static const char *hello_str = "FUSE Works!\n";
static const char *hello_path = "/hello";
static int hello_getattr(const char *path, struct stat *stbuf) {
    memset(stbuf, 0, sizeof(struct stat));
    if (strcmp(path, "/") == 0) { stbuf->st_mode = S_IFDIR | 0755; stbuf->st_nlink = 2; }
    else if (strcmp(path, hello_path) == 0) { stbuf->st_mode = S_IFREG | 0444; stbuf->st_nlink = 1; stbuf->st_size = strlen(hello_str); }
    else return -ENOENT;
    return 0;
}
static int hello_readdir(const char *path, void *buf, fuse_fill_dir_t filler, off_t offset, struct fuse_file_info *fi) {
    if (strcmp(path, "/") != 0) return -ENOENT;
    filler(buf, ".", NULL, 0); filler(buf, "..", NULL, 0); filler(buf, hello_path + 1, NULL, 0);
    return 0;
}
static int hello_open(const char *path, struct fuse_file_info *fi) {
    if (strcmp(path, hello_path) != 0) return -ENOENT;
    if ((fi->flags & 3) != O_RDONLY) return -EACCES;
    return 0;
}
static int hello_read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info *fi) {
    size_t len = strlen(hello_str);
    if (strcmp(path, hello_path) != 0) return -ENOENT;
    if (offset < len) { if (offset + size > len) size = len - offset; memcpy(buf, hello_str + offset, size); }
    else size = 0;
    return size;
}
static struct fuse_operations hello_oper = { .getattr = hello_getattr, .readdir = hello_readdir, .open = hello_open, .read = hello_read };
int main(int argc, char *argv[]) { return fuse_main(argc, argv, &hello_oper, NULL); }
C_EOF

gcc -Wall /root/hello.c -D_FILE_OFFSET_BITS=64 -I/usr/include/fuse -lfuse -o /root/hello_fuse
mkdir -p /mnt/fuse
/root/hello_fuse /mnt/fuse
echo "[+] FUSE Mounted. Cat /mnt/fuse/hello:"
cat /mnt/fuse/hello
EOF
chmod +x root/fuse_test.sh

# ... (kode init dan fuse_test.sh di atasnya) ...
cat << 'EOF' > root/.profile
echo "[*] Menginisialisasi Lingkungan Root..."
echo "[*] Struktur Root Filesystem (OS):"
ls -la /
EOF

# PINTU SEGEL KOMPRESI (Harus selalu berada paling bawah)
find . | cpio -H newc -o | gzip -9 > ../osboot/multi.gz
cd ..
echo "[+] Multi filesystem dibuat di osboot/multi.gz"
