#!/bin/bash
# ============================================
# 编译后处理：收集固件、生成校验和
# 用法: post-build.sh <device-name>
# 在 immortalwrt/ 源码目录内执行
# ============================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DEVICE="$1"
DATE=$(date +%Y.%m.%d)

CONF="${ROOT_DIR}/devices/${DEVICE}.conf"
source "$CONF"

# 固件目录（相对于当前 immortalwrt/ 目录）
SRC="bin/targets/${TARGET}/${SUBTARGET}"

if [ ! -d "$SRC" ]; then
    echo "❌ No build output found at: $SRC"
    echo "Current dir: $(pwd)"
    ls -la bin/targets/ 2>/dev/null || echo "bin/targets/ does not exist"
    exit 1
fi

OUT="${ROOT_DIR}/output/${DEVICE}"
mkdir -p "$OUT"
rm -f "$OUT"/*

echo "📦 Collecting firmware from: $(pwd)/$SRC"
echo "📦 Output to: $OUT"

# 复制固件
if [ "$TARGET" = "x86" ]; then
    cp ${SRC}/*combined-efi.img.gz "$OUT/" 2>/dev/null || true
    cp ${SRC}/*combined.img.gz "$OUT/" 2>/dev/null || true
    cp ${SRC}/*rootfs.img.gz "$OUT/" 2>/dev/null || true
else
    # ARM devices: match by device name pattern
    DEVICE_PATTERN=$(echo "$DEVICE" | tr '_' '-')
    cp ${SRC}/*${DEVICE_PATTERN}*sysupgrade* "$OUT/" 2>/dev/null || true
    cp ${SRC}/*${DEVICE_PATTERN}*factory* "$OUT/" 2>/dev/null || true
    cp ${SRC}/*${DEVICE_PATTERN}*uboot*.fip "$OUT/" 2>/dev/null || true
fi

# manifest + buildinfo
cp ${SRC}/*.manifest "$OUT/" 2>/dev/null || true
cp ${SRC}/config.buildinfo "$OUT/" 2>/dev/null || true

# sha256
cd "$OUT"
sha256sum * > sha256sums.txt 2>/dev/null || true

# 设备信息（Release Notes 用）
FW_FILES=$(ls *.itb *.img.gz *.bin *.fip 2>/dev/null | wc -l || echo 0)
cat > info.txt << INFO
- **${DESCRIPTION}**
  - Target: \`${TARGET}/${SUBTARGET}\`
  - Device: \`${DEVICE:-generic}\`
  - Files: ${FW_FILES} firmware images
INFO

echo "✅ Output ready: $OUT ($(ls | wc -l) files)"
ls -lh "$OUT/"
