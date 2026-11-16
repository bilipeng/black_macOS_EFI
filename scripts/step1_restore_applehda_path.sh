#!/bin/bash
# 把 AppleHDA 补回 System KC 里记录的期望路径（/System/Volumes/Update/mnt1/...）
# 只写 Update 暂存卷，不触碰 /S/L/E、不触碰原 EFI 分区
set -u

DEST="/System/Volumes/Update/mnt1/System/Library/Extensions"
SRC="/Users/penghaiyi/Desktop/EFI_work/AppleHDA_stage/AppleHDA.kext"

echo "== 1) 校验源 kext =="
if [ ! -d "$SRC" ]; then
  echo "FAIL: 源不存在 $SRC"
  exit 2
fi
echo "源大小: $(du -sh "$SRC" | awk '{print $1}')"

echo "== 2) 建目录 =="
mkdir -p "$DEST" || { echo "FAIL: mkdir"; exit 3; }

echo "== 3) 复制 =="
rm -rf "$DEST/AppleHDA.kext"
cp -R "$SRC" "$DEST/" || { echo "FAIL: cp"; exit 4; }

echo "== 4) 修正属主 =="
chown -R root:wheel "$DEST/AppleHDA.kext" || { echo "FAIL: chown"; exit 5; }

echo "== 5) 落位核对 =="
ls -la "$DEST/AppleHDA.kext/Contents/"
echo "-- Resources --"
ls "$DEST/AppleHDA.kext/Contents/Resources/" 2>/dev/null | grep -E "Platforms|layout7" 
echo "-- PlugIns --"
ls "$DEST/AppleHDA.kext/Contents/PlugIns/" 2>/dev/null

echo "RESULT_OK"
