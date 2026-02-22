#!/bin/bash
# ============================================
# ImmortalWrt 编译主脚本
# 用法: build.sh <device-name> [--clean] [--update]
# ============================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DEVICE="$1"
CLEAN=false
UPDATE=false

# 解析参数
for arg in "$@"; do
    case $arg in
        --clean) CLEAN=true ;;
        --update) UPDATE=true ;;
    esac
done

# 检查设备配置
CONF="${ROOT_DIR}/devices/${DEVICE}.conf"
if [ ! -f "$CONF" ]; then
    echo "❌ Unknown device: $DEVICE"
    echo "Available devices:"
    ls "${ROOT_DIR}/devices/"*.conf 2>/dev/null | xargs -I{} basename {} .conf | sed 's/^/  - /'
    exit 1
fi

source "$CONF"
BUILD_DIR="${ROOT_DIR}/build/${DEVICE}"
OUTPUT_DIR="${ROOT_DIR}/output/${DEVICE}"
CACHE_DL="${ROOT_DIR}/cache/dl"

echo "============================================"
echo "🔨 Building ImmortalWrt for: ${DEVICE}"
echo "   Target: ${TARGET}/${SUBTARGET}"
echo "   Device: ${DEVICE}"
echo "   Branch: ${BRANCH}"
echo "============================================"

# --- Clone 或更新源码 ---
mkdir -p "$BUILD_DIR" "$OUTPUT_DIR" "$CACHE_DL"

if [ ! -d "${BUILD_DIR}/immortalwrt/.git" ]; then
    echo "📦 Cloning ImmortalWrt..."
    git clone --depth 1 -b "$BRANCH" "$REPO" "${BUILD_DIR}/immortalwrt"
elif [ "$UPDATE" = true ]; then
    echo "🔄 Updating source..."
    cd "${BUILD_DIR}/immortalwrt"
    git pull
fi

cd "${BUILD_DIR}/immortalwrt"

# 共享下载缓存
ln -sf "$CACHE_DL" dl 2>/dev/null || true

# --- Clean ---
if [ "$CLEAN" = true ]; then
    echo "🧹 Full clean..."
    make dirclean
fi

# --- Feeds ---
echo "📡 Updating feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

# --- 注入自定义文件 ---
if [ -d "${ROOT_DIR}/files" ]; then
    echo "📂 Injecting custom files..."
    cp -r "${ROOT_DIR}/files" ./files
fi

# --- 生成 .config ---
echo "⚙️ Generating config..."
bash "${SCRIPT_DIR}/generate-config.sh" "$CONF"

# --- 下载 ---
echo "⬇️ Downloading packages..."
make download -j16
find dl -size -1024c -exec rm -f {} \; 2>/dev/null

# --- 编译 ---
NPROC=$(nproc)
echo "🔨 Compiling with ${NPROC} threads..."
make -j${NPROC} || {
    echo "⚠️ Parallel build failed, retrying with -j1 V=s..."
    make -j1 V=s
}

# --- 整理输出 ---
echo "📦 Collecting firmware..."
bash "${SCRIPT_DIR}/post-build.sh" "$DEVICE"

echo "============================================"
echo "✅ Build complete!"
echo "   Output: ${OUTPUT_DIR}/"
ls -lh "${OUTPUT_DIR}/"
echo "============================================"
