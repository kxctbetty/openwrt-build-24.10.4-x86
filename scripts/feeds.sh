#!/bin/bash
set -e

# 定位OpenWRT源码根目录
OPENWRT_ROOT_PATH="${OPENWRT_ROOT_PATH:-$(pwd)}"
cd "$OPENWRT_ROOT_PATH" || { echo "OpenWRT根目录不存在"; exit 1; }

# 备份并清理旧Feeds
cp -f feeds.conf.default feeds.conf.default.bak
sed -i '/kenzo\|small\|argon\|ikoolproxy/d' feeds.conf.default

# ====================== 适配v24.10.4：克隆Feeds（使用main分支，自动兼容） ======================
# 1. kenzo包（main分支，兼容v24.10.4）
mkdir -p feeds/kenzo
git clone --depth 1 --single-branch -b main https://github.com/kenzok8/openwrt-packages.git feeds/kenzo || {
    rm -rf feeds/kenzo && git clone --depth 1 --single-branch -b main https://github.com/kenzok8/openwrt-packages.git feeds/kenzo
}

# 2. small包（main分支，兼容v24.10.4）
mkdir -p feeds/small
git clone --depth 1 --single-branch -b main https://github.com/kenzok8/small.git feeds/small || {
    rm -rf feeds/small && git clone --depth 1 --single-branch -b main https://github.com/kenzok8/small.git feeds/small
}

# 3. Argon主题（main分支，适配v24.10.4）
mkdir -p feeds/argon
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git feeds/argon || {
    rm -rf feeds/argon && git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git feeds/argon
}

# 4. iKoolProxy（本地包，适配v24.10.4）
mkdir -p package/luci-app-ikoolproxy
git clone --depth 1 https://github.com/ilxp/luci-app-ikoolproxy.git package/luci-app-ikoolproxy || {
    rm -rf package/luci-app-ikoolproxy && git clone --depth 1 https://github.com/ilxp/luci-app-ikoolproxy.git package/luci-app-ikoolproxy
}

# 更新并安装Feeds
./scripts/feeds update -a -f
./scripts/feeds install -a

# 安装核心插件
./scripts/feeds install -p kenzo luci-app-passwall2 v2ray-core xray-core sing-box msd_lite luci-app-msd_lite
./scripts/feeds install -p base ddns-scripts luci-app-ddns open-vm-tools
./scripts/feeds install -p argon luci-theme-argon luci-app-argon-config
./scripts/feeds install -p luci luci-i18n-base-zh-cn

# 安装中文语言包
for feed in kenzo small argon; do
    [ -d "feeds/$feed" ] && {
        zh_pkgs=$(ls feeds/$feed/luci-i18n-*-zh-cn 2>/dev/null | awk -F '/' '{print $NF}')
        [ -n "$zh_pkgs" ] && ./scripts/feeds install -p "$feed" $zh_pkgs
    }
done

echo "Feeds配置完成，兼容OpenWRT v24.10.4！"
