#!/bin/bash
set -e

cd $OPENWRT_ROOT_PATH || exit 1

# ====================== 系统基础配置 ======================
# 默认语言改为中文
sed -i 's/^CONFIG_LUCI_LANG=.*/CONFIG_LUCI_LANG="zh_cn"/g' .config
echo "CONFIG_LUCI_I18N_ZH_CN=y" >> .config

# 时区设为上海
sed -i 's/^CONFIG_TIMEZONE=.*/CONFIG_TIMEZONE="Asia\/Shanghai"/g' .config
echo "CONFIG_DEFAULT_TIMEZONE=y" >> .config

# ====================== 内核优化（BBR/Cake/FQ） ======================
echo "CONFIG_KERNEL_CGROUP_BPF=y" >> .config
echo "CONFIG_KERNEL_NET_SCH_CAKE=y" >> .config
echo "CONFIG_KERNEL_NET_SCH_FQ_CODEL=y" >> .config
echo "CONFIG_KERNEL_NET_SCH_FQ=y" >> .config
echo "CONFIG_KERNEL_TCP_CONG_BBR=y" >> .config
echo "CONFIG_KERNEL_TCP_CONG_CAKE=y" >> .config

# ====================== 核心插件编译开关 ======================
# open-vm-tools
echo "CONFIG_PACKAGE_open-vm-tools=y" >> .config
echo "CONFIG_PACKAGE_luci-app-open-vm-tools=y" >> .config

# iKoolProxy
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

# Passwall
echo "CONFIG_PACKAGE_luci-app-passwall=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall2=y" >> .config
echo "CONFIG_PACKAGE_v2ray-core=y" >> .config
echo "CONFIG_PACKAGE_xray-core=y" >> .config
echo "CONFIG_PACKAGE_sing-box=y" >> .config

# Argon主题
echo "CONFIG_PACKAGE_luci-theme-argon=y" >> .config
echo "CONFIG_PACKAGE_luci-app-argon-config=y" >> .config

# ====================== 优化编译/固件 ======================
# 开启ccache缓存（加速重编译）
echo "CONFIG_CCACHE=y" >> .config
# 固件分区大小（x86_64，根分区2G）
sed -i 's/^CONFIG_TARGET_IMAGES_PARTITION_TABLE_TYPE=.*/CONFIG_TARGET_IMAGES_PARTITION_TABLE_TYPE="gpt"/g' .config
echo "CONFIG_TARGET_ROOTFS_PARTSIZE=2048" >> .config
# 移除默认主题（保留Argon）
sed -i '/CONFIG_PACKAGE_luci-theme-bootstrap=y/d' .config

# 生成最终配置
make defconfig
