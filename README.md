# SISOP-5-2026-IT-049

## Reporting

Ashkhabil Abror Budihardjo (5027251049)

### Soal 1

Berikut adalah penjelasan dari setiap filenya:

### 1. `kernel.sh`
berfungsi untuk mengunduh, mengonfigurasi, dan mengompilasi kode sumber Linux Kernel (v6.1.1) menjadi *binary* kernel yang dapat di-boot (`bzImage`).
**Komponen Krusial:**
* **Pengambilan Kode Sumber:** Menggunakan `wget` dan `tar` untuk menarik repositori kernel murni.
* **Konfigurasi Hypervisor:** Mengeksekusi `make defconfig` dan `make kvm_guest.config`. Ini adalah langkah optimasi krusial yang membuang modul *hardware* fisik yang tidak perlu dan menyesuaikan kernel secara spesifik agar berjalan ringan di atas virtualisasi QEMU/KVM.
* **Kompilasi Paralel:** Menggunakan parameter `make -j$(nproc)` untuk memaksa *compiler* menggunakan seluruh *thread* CPU *host*, memangkas waktu kompilasi secara drastis.

### 2. `single.sh` 
berfungsi untuk merakit *Initial RAM Filesystem* (`initramfs`) mode *single-user*. Ini adalah fondasi sistem operasi yang paling primitif.
**Komponen Krusial:**
* **BusyBox Static Integration:** Mengunduh *binary* BusyBox statis yang akan bertindak sebagai "pisau Swiss Army", menggantikan utilitas GNU standar (seperti `ls`, `cat`, `mkdir`).
* **Scaffolding VFS:** Membangun kerangka direktori virtual absolut (`/dev`, `/proc`, `/sys`).
* **Init Script Bypass:** Skrip `init` pada mode ini secara eksplisit melakukan *mount* pada *Virtual File System* (VFS) dan langsung mengeksekusi `/bin/sh`. Tidak ada proses *login* atau autentikasi; pengguna langsung dijatuhkan ke dalam terminal dengan akses `root` absolut (PID 1).
* **CPIO Packaging:** Membungkus hierarki direktori ke dalam format arsip `cpio` dan mengompresnya menjadi `single.gz` agar dapat dimuat ke dalam RAM oleh kernel.

### 3. `multi.sh` 
berfungsi sebagai otak dari penugasan ini. Merakit `initramfs` yang kompleks, mendukung banyak *user*, *package manager* dinamis, dan keamanan tingkat lanjut.
**Komponen Krusial:**
* **Dynamic Package Manager (`party`):** Menarik `apk-tools` statis (versi 2.x) dari server Alpine. Resolusi ini secara sadar menghindari protokol HTTPS murni (`http://`) pada konfigurasi `repositories` untuk melewati limitasi *Root Certificate* pada OS telanjang.
* **Declarative Identity (Matrix ACL):** Menyuntikkan identitas *user* (`root`, `henn`, `hann`, `viii`, `kids`) secara terprogram (IaC) ke dalam `/etc/passwd` dan `/etc/group` untuk membentuk hierarki *Access Control List* (ACL) sebelum sistem menyala.
* **Native Init Script (The Entry Point):** Skrip `init` tidak hanya memasang VFS, tetapi juga:
    1.  Menetapkan konfigurasi jaringan statis (`ifconfig eth0 10.0.2.15`) dan *Gateway*.
    2.  Menyuntikkan DNS internal QEMU (`10.0.2.3`) ke `resolv.conf` untuk memecahkan masalah *Domain Name Resolution*.
    3.  Mengeksekusi perintah `chown` untuk folder `/home/` secara **native dari dalam Guest OS**. Ini adalah keputusan arsitektural untuk mencegah rusaknya *file permission* jika *chown* dieksekusi oleh sistem *host* Ubuntu.
* **Autologin Wrapper:** Merombak siklus *getty* untuk membungkus `/bin/login` sehingga sistem langsung masuk sebagai `root` tanpa intervensi *keyboard*, dan secara otomatis mengeksekusi `ls -la /` melalui injeksi `/root/.profile`.
* **FUSE Compilation Script:** Membangun *file* `/root/fuse_test.sh` yang bertugas memalsukan *database package manager*, mengunduh kompilator (`gcc`), dan mengompilasi kode C *Filesystem in Userspace* secara dinamis di dalam OS.

### 4. `iso.sh`
berfungsi untuk menggabungkan Kernel (`bzImage`) dan RAM Disk (`multi.gz`) ke dalam format standar *disk image* (`.iso`).
**Komponen Krusial:**
* **ISOLINUX Bootloader:** Memasang `isolinux.bin` sebagai manajer *boot*.
* **Configuration (`isolinux.cfg`):** Menentukan parameter *boot* kernel absolut: `append initrd=/osboot/multi.gz console=ttyS0`. Parameter `console=ttyS0` memaksa kernel untuk membuang antarmuka grafis (VGA) dan melempar seluruh *output* log langsung ke terminal serial (teks).
* **Xorriso:** Alat generasi akhir yang membakar struktur direktori tersebut menjadi *file* ISO yang *bootable*.

### 5. `qemu.sh`
berfungsi sebagai skrip pengendali hypervisor untuk menyimulasikan perangkat keras dan mengeksekusi OS buatan.
**Komponen Krusial:**
* **Routing Parameter (`--single`, `--multi`, `--iso`):** Membaca argumen *command line* untuk menentukan *file* OS mana yang akan dimuat ke dalam memori.
* **Resource Allocation:** Menetapkan `-m 512M` (membatasi RAM sebesar 512 MB).
* **SLIRP Networking:** Menggunakan `-net nic -net user` untuk menciptakan mode parasit jaringan (NAT ganda) yang meminjam tumpukan koneksi TCP/UDP dari *host* Windows/WSL.
* **Nographic Forcing:** Parameter `-nographic -append "console=ttyS0"` memastikan emulator tidak membuka jendela GUI baru, melainkan menahan seluruh sesi interaktif di dalam terminal *host* yang sedang berjalan.

### 6. `backup.sh`
berfungsi untuk mengompres semua file dari kernel.sh sampai iso.sh ke dalam file farewell_backup_03062026-194057.zip

### Output
berikut adalah outputnya.
<img width="1447" height="558" alt="image" src="https://github.com/user-attachments/assets/07912847-864b-43d9-b32f-2e259d915581" />
<img width="795" height="644" alt="image" src="https://github.com/user-attachments/assets/9e02af5d-ffb5-4e82-8574-a88e6eb7352a" />
<img width="742" height="656" alt="image" src="https://github.com/user-attachments/assets/62ede37a-7ef3-40bb-8ee5-01347c495e9a" />
<img width="632" height="335" alt="image" src="https://github.com/user-attachments/assets/590beb60-ba96-4740-9604-71295defea59" />
<img width="636" height="311" alt="image" src="https://github.com/user-attachments/assets/fd0c3c38-9dba-4f2e-8258-b6a1a4c6fa22" />


### Kendala
Untuk connect ke internet sebenarnya sudah bisa cuma memang untuk tes pingnya memang tertulis kalau OS nya tidak terkoneksi dengan internet.
Kemudian untuk multi user tidak bisa melihat isi direktori pada OS.
