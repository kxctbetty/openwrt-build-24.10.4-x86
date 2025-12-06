#!/bin/bash
set -e

# 切换到OpenWRT源码根目录
cd $OPENWRT_ROOT_PATH || exit 1

# 备份原始feeds.conf.default
cp feeds.conf.default feeds.conf.default.bak

# 添加第三方feeds（适配24.10.4）
cat >> feeds.conf.default << EOF
# Custom feeds for OpenWRT 24.10.4
src-git kenzo https://github.com/kenzok8/openwrt-packages.git;24.10
src-git small https://github.com/kenzok8/small.git;24.10
src-git argon https://github.com/jerrykuku/luci-theme-argon.git;master
src-git ikoolproxy https://github.com/ilxp/luci-app-ikoolproxy.git;master
EOF

# 更新feeds索引
./scripts/feeds update -a

# 安装核心插件
./scripts/feeds install -p ikoolproxy luci-app-ikoolproxy          # iKoolProxy
./scripts/feeds install -p argon luci-theme-argon luci-app-argon-config  # Argon主题
./scripts/feeds install -p kenzo luci-app-passwall luci-app-passwall2 v2ray-core xray-core sing-box  # Passwall
./scripts/feeds install -p kenzo msd_lite luci-app-msd_lite        # msd_lite
./scripts/feeds install -p base ddns-scripts luci-app-ddns         # DDNS
./scripts/feeds install -p packages open-vm-tools                  # open-vm-tools
./scripts/feeds install -p luci luci-i18n-base-zh-cn              # 中文语言包

# 批量安装插件中文语言包
for feed in $(ls feeds/); do
    if [ -d "feeds/$feed/luci-i18n-*-zh-cn" ]; then
        ./scripts/feeds install -p $feed $(ls feeds/$feed/luci-i18n-*-zh-cn | awk -F '/' '{print $NF}')
    fi
done

chmod 644 feeds.conf.default
