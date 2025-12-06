#!/bin/bash
set -e

# 定位OpenWRT源码根目录（适配Actions环境变量）
OPENWRT_ROOT_PATH="${OPENWRT_ROOT_PATH:-$(pwd)}"
cd "$OPENWRT_ROOT_PATH" || { echo "OpenWRT根目录不存在"; exit 1; }

# ====================== 适配v24.10.4：备份并清理旧Feeds ======================
cp -f feeds.conf.default feeds.conf.default.bak
# 移除所有旧的自定义Feeds（避免冲突）
sed -i '/kenzo\|small\|argon\|ikoolproxy/d' feeds.conf.default

# ====================== 适配v24.10.4：克隆对应分支的Feeds ======================
# 1. kenzo包（严格适配openwrt-24.10分支，匹配v24.10.4）
mkdir -p feeds/kenzo
git clone --depth 1 --single-branch -b openwrt-24.10 https://github.com/kenzok8/openwrt-packages.git feeds/kenzo || {
    echo "拉取kenzo Feeds失败，重试..."
    rm -rf feeds/kenzo && git clone --depth 1 --single-branch -b openwrt-24.10 https://github.com/kenzok8/openwrt-packages.git feeds/kenzo
}

# 2. small包（openwrt-24.10分支，适配v24.10.4）
mkdir -p feeds/small
git clone --depth 1 --single-branch -b openwrt-24.10 https://github.com/kenzok8/small.git feeds/small || {
    echo "拉取small Feeds失败，重试..."
    rm -rf feeds/small && git clone --depth 1 --single-branch -b openwrt-24.10 https://github.com/kenzok8/small.git feeds/small
}

# 3. Argon主题（适配v24.10.4的最新版本）
mkdir -p feeds/argon
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git feeds/argon || {
    echo "拉取Argon主题失败，重试..."
    rm -rf feeds/argon && git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git feeds/argon
}

# 4. iKoolProxy（适配v24.10.4，放到package目录更稳定）
mkdir -p package/luci-app-ikoolproxy
git clone --depth 1 https://github.com/ilxp/luci-app-ikoolproxy.git package/luci-app-ikoolproxy || {
    echo "拉取iKoolProxy失败，重试..."
    rm -rf package/luci-app-ikoolproxy && git clone --depth 1 https://github.com/ilxp/luci-app-ikoolproxy.git package/luci-app-ikoolproxy
}

# ====================== 适配v24.10.4：更新并安装Feeds ======================
# 更新所有Feeds（强制刷新，适配v24.10.4）
./scripts/feeds update -a -f

# 安装所有Feeds包（优先适配v24.10.4的依赖）
./scripts/feeds install -a

# 精准安装v24.10.4核心插件（避免版本不兼容）
./scripts/feeds install -p kenzo luci-app-passwall2 v2ray-core xray-core sing-box msd_lite luci-app-msd_lite
./scripts/feeds install -p base ddns-scripts luci-app-ddns open-vm-tools
./scripts/feeds install -p argon luci-theme-argon luci-app-argon-config
./scripts/feeds install -p luci luci-i18n-base-zh-cn

# 批量安装v24.10.4中文语言包
for feed in kenzo small argon; do
    if [ -d "feeds/$feed" ]; then
        zh_pkgs=$(ls feeds/$feed/luci-i18n-*-zh-cn 2>/dev/null | awk -F '/' '{print $NF}')
        [ -n "$zh_pkgs" ] && ./scripts/feeds install -p "$feed" $zh_pkgs
    fi
done

echo "Feeds配置完成，全部适配OpenWRT v24.10.4！"
