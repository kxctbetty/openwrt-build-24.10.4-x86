#!/bin/bash
set -e

cd $OPENWRT_ROOT_PATH || exit 1

# 修复iKoolProxy编译兼容（适配24.10.4）
if [ -d "feeds/ikoolproxy/luci-app-ikoolproxy" ]; then
    sed -i 's/luci.mk/luci-base.mk/g' feeds/ikoolproxy/luci-app-ikoolproxy/Makefile
fi

# 修复Argon主题编译兼容
if [ -d "feeds/argon/luci-theme-argon" ]; then
    sed -i 's/luci.mk/luci-base.mk/g' feeds/argon/luci-theme-argon/Makefile
fi

# 安装ccache（编译缓存工具）
sudo apt-get install -y ccache
ccache -M 50G  # 设置缓存大小50G
export PATH=/usr/lib/ccache:$PATH

# 修复dl目录权限（缓存下载包）
mkdir -p dl
chmod 777 dl
