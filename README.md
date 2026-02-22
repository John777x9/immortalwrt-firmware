# ImmortalWrt 自定义固件

[![Build ImmortalWrt](https://github.com/John777x9/immortalwrt-firmware/actions/workflows/build.yml/badge.svg)](https://github.com/John777x9/immortalwrt-firmware/actions/workflows/build.yml)

基于 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) 源码，通过 GitHub Actions 自动编译的多设备固件。

## 📥 固件下载

前往 [Releases](https://github.com/John777x9/immortalwrt-firmware/releases) 下载最新固件。

| 设备 | 平台 | 说明 |
|------|------|------|
| **x86/64** | x86_64 | 软路由 / PVE / ESXi / 物理机 |
| **CMCC RAX3000M** | MediaTek MT7981B | eMMC 64GB 版 |
| **GL.iNet MT3000** | MediaTek MT7981B | Beryl AX |

## 🔌 预装插件

| 类别 | 插件 |
|------|------|
| 代理 | HomeProxy, Passwall (sing-box 全特性) |
| 主题 | Argon + 中文界面 |
| 工具 | ttyd, ddns-go, netdata*, frpc, UPnP |
| 诊断 | tcpdump, curl, wget, ip-full |
| 内核 | nft-tproxy, nft-fullcone, tun |

> *netdata 仅 x86 和 RAX3000M 包含（MT3000 闪存较小已精简）

## 💡 刷机说明

### x86 软路由
```bash
# 写入磁盘
gunzip immortalwrt-x86-64-generic-ext4-combined-efi.img.gz
dd if=immortalwrt-*.img of=/dev/sdX bs=1M

# 或导入 PVE/ESXi 虚拟机
```

### ARM 设备（RAX3000M / MT3000）
```bash
# 上传固件到路由器后
sysupgrade -n /tmp/firmware.itb  # -n 不保留旧配置
```

### 默认设置
- 管理地址: `192.168.1.1`
- 密码: 无（首次登录设置）
- 时区: Asia/Shanghai

## 🔧 自定义编译

### 修改插件
编辑 `devices/<设备名>.conf`，在 `PACKAGES` 数组中增减插件：
```bash
PACKAGES=(
    +luci-app-xxx    # 添加
    -luci-app-yyy    # 移除
)
```

### 添加新设备
```bash
cp devices/rax3000m.conf devices/newdevice.conf
# 修改 TARGET/SUBTARGET/DEVICE
git add && git commit && git push  # 自动触发编译
```

### 手动触发编译
1. 进入 [Actions](https://github.com/John777x9/immortalwrt-firmware/actions/workflows/build.yml)
2. 点击 "Run workflow"
3. 选择设备，点击运行

## 📅 自动编译

每周一北京时间早 8:00 自动编译所有设备并发布 Release。

## 📄 License

[MIT](LICENSE)
