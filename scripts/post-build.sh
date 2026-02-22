#!/bin/bash
# ============================================
# 编译后处理：收集固件、重命名、生成校验和
# 用法: post-build.sh <device-name>
# ============================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DEVICE="$1"
DATE=$(date +%Y.%m.%d)

CONF="${ROOT_DIR}/devices/${DEVICE}.conf"
source "$CONF"

# 查找固件目录
if [ -d "bin/targets/${TARGET}/${SUBTARGET}" ]; then
    SRC="bin/targets/${TARGET}/${SUBTARGET}"
elif [ -d "${ROOT_DIR}/build/${DEVICE}/immortalwrt/bin/targets/${TARGET}/${SUBTARGET}" ]; then
    SRC="${ROOT_DIR}/build/${DEVICE}/immortalwrt/bin/targets/${TARGET}/${SUBTARGET}"
else
    echo "❌ No build output found"
    exit 1
fi

OUT="${ROOT_DIR}/output/${DEVICE}"
mkdir -p "$OUT"
rm -f "$OUT"/*

echo "📦 Collecting firmware from: $SRC"

# 复制固件
if [ "$TARGET" = "x86" ]; then
    cp ${SRC}/*combined-efi.img.gz "$OUT/" 2>/dev/null || true
    cp ${SRC}/*combined.img.gz "$OUT/" 2>/dev/null || true
    cp ${SRC}/*rootfs.img.gz "$OUT/" 2>/dev/null || true
else
    DEVICE_PATTERN=$(echo "$DEVICE" | tr '_' '-')
    cp ${SRC}/*${DEVICE_PATTERN}*sysupgrade* "$OUT/" 2>/dev/null || true
    cp ${SRC}/*${DEVICE_PATTERN}*factory* "$OUT/" 2>/dev/null || true
    # 也复制 u-boot
    cp ${SRC}/*${DEVICE_PATTERN}*uboot* "$OUT/" 2>/dev/null || true
fi

# 复制 manifest 和 buildinfo
cp ${SRC}/*.manifest "$OUT/" 2>/dev/null || true
cp ${SRC}/config.buildinfo "$OUT/" 2>/dev/null || true

# 生成 sha256
cd "$OUT"
sha256sum *.img.gz *.itb *.bin *.fip 2>/dev/null > sha256sums.txt || true

# 写设备信息（Release Notes 用）
FW_SIZE=$(du -sh *.itb *.img.gz *.bin 2>/dev/null | head -1 | awk '{print $1}' || echo "N/A")
FW_COUNT=$(ls *.itb *.img.gz *.bin *.fip 2>/dev/null | wc -l || echo 0)
cat > info.txt << INFO
- **${DESCRIPTION}**
  - Target: \`${TARGET}/${SUBTARGET}\`
  - Device: \`${DEVICE:-generic}\`
  - Files: ${FW_COUNT} firmware images
INFO

echo "✅ Output ready: $OUT (${FW_COUNT} files)"
ls -lh "$OUT/" 2>/dev/null
