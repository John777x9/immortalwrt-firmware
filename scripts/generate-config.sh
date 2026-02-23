#!/bin/bash
# ============================================
# 从设备 .conf 生成 ImmortalWrt .config
# 用法: generate-config.sh <conf-file>
# ============================================
set -e

CONF_FILE="$1"
if [ ! -f "$CONF_FILE" ]; then
    echo "❌ Config file not found: $CONF_FILE"
    exit 1
fi

source "$CONF_FILE"

echo "📋 Generating .config for ${DEVICE:-${TARGET}/${SUBTARGET}}"

# --- 基础 target ---
cat > .config << EOF
CONFIG_TARGET_${TARGET}=y
CONFIG_TARGET_${TARGET}_${SUBTARGET}=y
EOF

# --- 设备 ---
if [ -n "$DEVICE" ]; then
    echo "CONFIG_TARGET_${TARGET}_${SUBTARGET}_DEVICE_${DEVICE}=y" >> .config
fi

# --- x86 专用 ---
if [ "$TARGET" = "x86" ]; then
    [ -n "$ROOTFS_PARTSIZE" ] && echo "CONFIG_TARGET_ROOTFS_PARTSIZE=${ROOTFS_PARTSIZE}" >> .config
    [ "$EFI" = "yes" ] && echo "CONFIG_EFI_IMAGES=y" >> .config
fi

# --- 插件 ---
for pkg in "${PACKAGES[@]}"; do
    if [[ "$pkg" == +* ]]; then
        name="${pkg#+}"
        echo "CONFIG_PACKAGE_${name}=y" >> .config
    elif [[ "$pkg" == -* ]]; then
        name="${pkg#-}"
        echo "# CONFIG_PACKAGE_${name} is not set" >> .config
    fi
done

# --- 中文语言包 ---
if [ "$LANG" = "zh-cn" ]; then
    echo "CONFIG_PACKAGE_luci-i18n-base-zh-cn=y" >> .config
    for pkg in "${PACKAGES[@]}"; do
        if [[ "$pkg" == +luci-app-* ]]; then
            app_name="${pkg#+luci-app-}"
            echo "CONFIG_PACKAGE_luci-i18n-${app_name}-zh-cn=y" >> .config
        fi
    done
    echo "CONFIG_PACKAGE_luci-i18n-argon-config-zh-cn=y" >> .config
fi

# --- sing-box 编译特性 ---
if [ ${#SINGBOX_FEATURES[@]} -gt 0 ]; then
    for feat in "${SINGBOX_FEATURES[@]}"; do
        echo "CONFIG_SING_BOX_BUILD_${feat}=y" >> .config
    done
fi

# --- Passwall 组件 ---
if [ ${#PASSWALL_INCLUDE[@]} -gt 0 ]; then
    for inc in "${PASSWALL_INCLUDE[@]}"; do
        echo "CONFIG_PACKAGE_luci-app-passwall_INCLUDE_${inc}=y" >> .config
    done
fi

# --- defconfig 补全 ---
make defconfig > /dev/null 2>&1

# --- defconfig 后重新确保自定义选项生效 ---
if [ "$LANG" = "zh-cn" ]; then
    for pkg in "${PACKAGES[@]}"; do
        if [[ "$pkg" == +luci-app-* ]]; then
            app_name="${pkg#+luci-app-}"
            sed -i "s/# CONFIG_PACKAGE_luci-i18n-${app_name}-zh-cn is not set/CONFIG_PACKAGE_luci-i18n-${app_name}-zh-cn=y/" .config
        fi
    done
    sed -i "s/# CONFIG_PACKAGE_luci-i18n-base-zh-cn is not set/CONFIG_PACKAGE_luci-i18n-base-zh-cn=y/" .config
    sed -i "s/# CONFIG_PACKAGE_luci-i18n-argon-config-zh-cn is not set/CONFIG_PACKAGE_luci-i18n-argon-config-zh-cn=y/" .config
fi

if [ ${#SINGBOX_FEATURES[@]} -gt 0 ]; then
    for feat in "${SINGBOX_FEATURES[@]}"; do
        sed -i "s/# CONFIG_SING_BOX_BUILD_${feat} is not set/CONFIG_SING_BOX_BUILD_${feat}=y/" .config
        grep -q "SING_BOX_BUILD_${feat}" .config || echo "CONFIG_SING_BOX_BUILD_${feat}=y" >> .config
    done
fi

PKG_COUNT=$(grep '=y' .config | grep -c 'CONFIG_PACKAGE' || true)
echo "✅ .config generated: ${PKG_COUNT} packages selected"
