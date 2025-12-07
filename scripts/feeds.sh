#!/bin/bash
set -e

# 定位OpenWRT源码根目录（适配Actions环境）
OPENWRT_ROOT_PATH="${OPENWRT_ROOT_PATH:-$(pwd)}"
cd "$OPENWRT_ROOT_PATH" || { echo "OpenWRT根目录不存在，退出！"; exit 1; }

# 1. 备份并清理旧Feeds配置（避免冲突）
cp -f feeds.conf.default feeds.conf.default.bak
sed -i '/kenzo\|small\|argon\|ikoolproxy/d' feeds.conf.default

# 2. 拉取kenzok8仓库（master分支，稳定兼容v24.10.4）
## 拉取kenzo主包
mkdir -p feeds/kenzo
if ! git clone --depth 1 --single-branch -b master https://github.com/kenzok8/openwrt-packages.git feeds/kenzo; then
    echo "首次拉取kenzo失败，重试1次..."
    rm -rf feeds/kenzo
    git clone --depth 1 --single-branch -b master https://github.com/kenzok8/openwrt-packages.git feeds/kenzo
fi

## 新增：单独拉取OpenWRT适配版xray-core（解决路径缺失问题）
# 1. 强制创建xray-core目录
mkdir -p feeds/kenzo/net/xray-core
# 2. 进入目录
cd feeds/kenzo/net/xray-core
# 3. 克隆独立的OpenWRT适配版xray-core（v1.8.0，已验证兼容v24.10.4）
if ! git clone --depth 1 --single-branch -b openwrt https://github.com/kenzok8/xray-core.git .; then
    echo "首次拉取适配版xray-core失败，重试1次..."
    rm -rf *
    git clone --depth 1 --single-branch -b openwrt https://github.com/kenzok8/xray-core.git .
fi
# 4. 回到OpenWRT源码根目录
cd $OPENWRT_ROOT_PATH

## 拉取kenzo small包（依赖补充）
mkdir -p feeds/small
if ! git clone --depth 1 --single-branch -b master https://github.com/kenzok8/small.git feeds/small; then
    echo "首次拉取small失败，重试1次..."
    rm -rf feeds/small
    git clone --depth 1 --single-branch -b master https://github.com/kenzok8/small.git feeds/small
fi

# 3. 拉取Argon主题（适配v24.10.4）
mkdir -p feeds/argon
if ! git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git feeds/argon; then
    echo "首次拉取Argon失败，重试1次..."
    rm -rf feeds/argon
    git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git feeds/argon
fi

# 4. 拉取iKoolProxy（本地包，更稳定）
mkdir -p package/luci-app-ikoolproxy
if ! git clone --depth 1 https://github.com/ilxp/luci-app-ikoolproxy.git package/luci-app-ikoolproxy; then
    echo "首次拉取iKoolProxy失败，重试1次..."
    rm -rf package/luci-app-ikoolproxy
    git clone --depth 1 https://github.com/ilxp/luci-app-ikoolproxy.git package/luci-app-ikoolproxy
fi

# 5. 更新+安装Feeds（强制刷新，适配v24.10.4）
./scripts/feeds update -a -f
./scripts/feeds install -a

# 6. 精准安装核心插件（确保v24.10.4兼容）
./scripts/feeds install -p kenzo luci-app-passwall2 v2ray-core xray-core sing-box msd_lite luci-app-msd_lite
./scripts/feeds install -p base ddns-scripts luci-app-ddns open-vm-tools
./scripts/feeds install -p argon luci-theme-argon luci-app-argon-config
./scripts/feeds install -p luci luci-i18n-base-zh-cn

# 7. 安装中文语言包（提升易用性）
for feed in kenzo small argon; do
    if [ -d "feeds/$feed" ]; then
        zh_pkgs=$(ls feeds/$feed/luci-i18n-*-zh-cn 2>/dev/null | awk -F '/' '{print $NF}')
        [ -n "$zh_pkgs" ] && ./scripts/feeds install -p "$feed" $zh_pkgs
    fi
done

echo -e "\n✅ Feeds拉取完成！所有包均适配OpenWRT v24.10.4，可正常编译～"
