#!/bin/bash
set -e

cd $OPENWRT_ROOT_PATH || exit 1

# ====================== 系统基础配置（容错修改，避免重复） ======================
# 默认语言改为中文（先删后加，避免重复）
sed -i '/^CONFIG_LUCI_LANG=/d' .config
echo "CONFIG_LUCI_LANG=\"zh_cn\"" >> .config

# 时区设为上海（容错修改）
sed -i '/^CONFIG_TIMEZONE=/d' .config
sed -i '/^CONFIG_DEFAULT_TIMEZONE=/d' .config
echo "CONFIG_TIMEZONE=\"Asia/Shanghai\"" >> .config
echo "CONFIG_DEFAULT_TIMEZONE=y" >> .config

# ====================== 内核优化（适配6.6内核，仅保留有效配置） ======================
# 先清空原有内核配置，避免重复
sed -i '/^CONFIG_KERNEL_CGROUP_BPF=/d' .config
sed -i '/^CONFIG_KERNEL_NET_SCH_CAKE=/d' .config
sed -i '/^CONFIG_KERNEL_NET_SCH_FQ_CODEL=/d' .config
sed -i '/^CONFIG_KERNEL_TCP_CONG_BBR=/d' .config

# 6.6内核有效配置
echo "CONFIG_KERNEL_CGROUP_BPF=y" >> .config
echo "CONFIG_KERNEL_NET_SCH_CAKE=y" >> .config
echo "CONFIG_KERNEL_NET_SCH_FQ_CODEL=y" >> .config
echo "CONFIG_KERNEL_TCP_CONG_BBR=y" >> .config

# ====================== 核心插件编译开关（精准配置，避免冲突） ======================
# 先清空原有插件配置，避免重复
sed -i '/^CONFIG_PACKAGE_open-vm-tools=/d' .config
sed -i '/^CONFIG_PACKAGE_luci-app-ikoolproxy=/d' .config
sed -i '/^CONFIG_PACKAGE_ddns-scripts=/d' .config
sed -i '/^CONFIG_PACKAGE_msd_lite=/d' .config
sed -i '/^CONFIG_PACKAGE_luci-app-passwall=/d' .config
sed -i '/^CONFIG_PACKAGE_luci-theme-argon=/d' .config

# open-vm-tools
echo "CONFIG_PACKAGE_open-vm-tools=y" >> .config
echo "CONFIG_PACKAGE_luci-app-open-vm-tools=y" >> .config

# iKoolProxy（本地包）
echo "CONFIG_PACKAGE_luci-app-ikoolproxy=y" >> .config
echo "CONFIG_PACKAGE_ikoolproxy-core=y" >> .config

# DDNS（含阿里云/腾讯云）
echo "CONFIG_PACKAGE_ddns-scripts=y" >> .config
echo "CONFIG_PACKAGE_luci-app-ddns=y" >> .config
echo "CONFIG_PACKAGE_ddns-scripts_aliyun=y" >> .config
echo "CONFIG_PACKAGE_ddns-scripts_dnspod=y" >> .config

# msd_lite
echo "CONFIG_PACKAGE_msd_lite=y" >> .config
echo "CONFIG_PACKAGE_luci-app-msd_lite=y" >> .config

# Passwall2（仅装2代，避免冲突）
echo "CONFIG_PACKAGE_luci-app-passwall2=y" >> .config
echo "CONFIG_PACKAGE_v2ray-core=y" >> .config
echo "CONFIG_PACKAGE_xray-core=y" >> .config
echo "CONFIG_PACKAGE_sing-box=y" >> .config

# Argon主题
echo "CONFIG_PACKAGE_luci-theme-argon=y" >> .config
echo "CONFIG_PACKAGE_luci-app-argon-config=y" >> .config

# ====================== 优化编译/固件 ======================
# 开启ccache缓存（加速重编译）
sed -i '/^CONFIG_CCACHE=/d' .config
echo "CONFIG_CCACHE=y" >> .config

# 固件分区大小（x86_64，根分区2G，容错修改）
sed -i '/^CONFIG_TARGET_IMAGES_PARTITION_TABLE_TYPE=/d' .config
sed -i '/^CONFIG_TARGET_ROOTFS_PARTSIZE=/d' .config
echo "CONFIG_TARGET_IMAGES_PARTITION_TABLE_TYPE=\"gpt\"" >> .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=2048" >> .config

# 移除默认主题（加容错，无对应行时不报错）
sed -i '/CONFIG_PACKAGE_luci-theme-bootstrap=y/d' .config 2>/dev/null

# 生成最终配置（加详细日志）
make defconfig V=s
