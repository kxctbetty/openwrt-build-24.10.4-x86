#!/bin/bash
set -e

# 切换到OpenWRT源码根目录
cd $OPENWRT_ROOT_PATH || exit 1

# 备份原始feeds.conf.default
cp -f feeds.conf.default feeds.conf.default.bak

# 清空原有自定义feeds（避免重复）
sed -i '/^src-git kenzo/d' feeds.conf.default
sed -i '/^src-git small/d' feeds.conf.default
sed -i '/^src-git argon/d' feeds.conf.default
sed -i '/^src-git ikoolproxy/d' feeds.conf.default

# 添加第三方feeds（适配24.10.4，避免分支冲突）
cat >> feeds.conf.default << EOF
# Custom feeds for OpenWRT 24.10.4
src-git kenzo https://github.com/kenzok8/openwrt-packages.git;openwrt-24.10
src-git small https://github.com/kenzok8/small.git;openwrt-24.10
src-git argon https://github.com/jerrykuku/luci-theme-argon.git;master
EOF

# 单独克隆ikoolproxy（避免feeds命名冲突）
mkdir -p package/luci-app-ikoolproxy
git clone --depth 1 https://github.com/ilxp/luci-app-ikoolproxy.git package/luci-app-ikoolproxy

# 仅更新一次feeds（后续步骤不再重复）
./scripts/feeds update -a

# 安装核心插件（精准安装，避免冗余）
./scripts/feeds install -p kenzo luci-app-passwall2 v2ray-core xray-core sing-box  # 仅装passwall2（避免和passwall冲突）
./scripts/feeds install -p kenzo msd_lite luci-app-msd_lite
./scripts/feeds install -p base ddns-scripts luci-app-ddns
./scripts/feeds install -p packages open-vm-tools
./scripts/feeds install -p argon luci-theme-argon luci-app-argon-config
./scripts/feeds install -p luci luci-i18n-base-zh-cn

# 批量安装插件中文语言包（加容错，避免报错）
for feed in $(ls feeds/ 2>/dev/null); do
    if [ -d "feeds/$feed" ]; then
        zh_pkgs=$(ls feeds/$feed/luci-i18n-*-zh-cn 2>/dev/null | awk -F '/' '{print $NF}')
        if [ -n "$zh_pkgs" ]; then
            ./scripts/feeds install -p $feed $zh_pkgs
        fi
    fi
done

# 修复feeds权限
chmod 644 feeds.conf.default
