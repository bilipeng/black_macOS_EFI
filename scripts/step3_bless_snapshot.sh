#!/bin/bash
VOL=/System/Volumes/Update/mnt1
mount | grep -q "on $VOL " && umount "$VOL"
mount_apfs -o rw,nobrowse /dev/disk2s4 "$VOL" || { echo "MOUNT_FAIL"; exit 1; }
echo "== bless --folder CoreServices --bootefi --create-snapshot =="
bless --folder "$VOL/System/Library/CoreServices" --bootefi --create-snapshot --verbose 2>&1
echo "bless_exit=$?"
umount "$VOL"
echo "== 快照现状 =="
diskutil apfs listSnapshots / 2>&1 | head -24
echo "RESULT_OK"
