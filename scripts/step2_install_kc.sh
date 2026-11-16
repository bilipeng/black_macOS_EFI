#!/bin/bash
# 把已构建好的干净 SystemKernelExtensions.kc 写入系统卷
VOL=/System/Volumes/Update/mnt1
NEW=/Users/penghaiyi/Desktop/EFI_work/kc_probe3.kc
DST=$VOL/System/Library/KernelCollections/SystemKernelExtensions.kc

echo "== 1. 挂载可写 =="
mount | grep -q "on $VOL " && umount "$VOL"
mount_apfs -o rw,nobrowse /dev/disk2s4 "$VOL" || { echo "MOUNT_FAIL"; exit 1; }
mount | grep "on $VOL "

echo "== 2. 写入 KC =="
cp "$NEW" "$DST" || { echo "CP_FAIL"; exit 1; }
chown root:wheel "$DST"
chmod 755 "$DST"
ls -la "$DST"

echo "== 3. 校验落位 =="
echo "mnt1残留: $(strings -a "$DST" | grep -c 'Update/mnt1')"
echo "AppleHDA路径: $(strings -a "$DST" | grep -c '/System/Library/Extensions/AppleHDA.kext')"
echo "PlugIns: $(strings -a "$DST" | grep -c 'AppleHDA.kext/Contents/PlugIns')"

echo "== 4. 卸载 =="
umount "$VOL"
mount | grep -c "on $VOL " || true

echo "RESULT_OK"
