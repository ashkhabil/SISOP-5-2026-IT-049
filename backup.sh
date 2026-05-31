#!/bin/bash
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")
OUT_FILE="osboot/farewell_backup_${TIMESTAMP}.zip"
zip -j -q "$OUT_FILE" osboot/bzImage osboot/single.gz osboot/multi.gz osboot/farewell.iso
echo "[+] Backup berhasil tersimpan di: $OUT_FILE"
