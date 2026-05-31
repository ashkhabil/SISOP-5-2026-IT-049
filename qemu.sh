#!/bin/bash
# Eksekusi QEMU dengan spesifikasi network DHCP
if [ "$1" == "--single" ]; then
    qemu-system-x86_64 -kernel osboot/bzImage -initrd osboot/single.gz -m 512M -net nic -net user -nographic -append "console=ttyS0"
elif [ "$1" == "--multi" ]; then
    qemu-system-x86_64 -kernel osboot/bzImage -initrd osboot/multi.gz -m 512M -net nic -net user -nographic -append "console=ttyS0"
elif [ "$1" == "--all" ]; then
    qemu-system-x86_64 -cdrom osboot/farewell.iso -m 512M -net nic -net user
else
    echo "Usage: $0 [--single | --multi | --all]"
    exit 1
fi
