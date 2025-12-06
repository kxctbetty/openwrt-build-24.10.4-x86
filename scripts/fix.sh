#!/bin/bash
set -e

cd $OPENWRT_ROOT_PATH || exit 1

# 修复iKoolProxy编译兼容（适配24.10.4，加路径判断）
IKOOLPROXY_PATH="package/luci-app-ikoolproxy/luci-app-ikoolproxy"
if [ -f "$IKOOLPROXY_PATH/Makefile" ]; then
    sed -i 's/luci.mk/luci-base.mk/g' "$IKOOLPROXY_PATH/Makefile"
    echo "Fixed iKoolProxy Makefile"
fi

# 修复Argon主题编译兼容（加路径判断）
ARGON_PATH="feeds/argon/luci-theme-argon"
if [ -f "$ARGON_PATH/Makefile" ]; then
    sed -i 's/luci.mk/luci-base.mk/g' "$ARGON_PATH/Makefile"
    echo "Fixed Argon theme Makefile"
fi

# 安装并全局配置ccache（确保编译时生效）
sudo apt-get install -y ccache >/dev/null 2>&1
ccache -M 50G >/dev/null 2>&1
# 全局导出ccache路径（避免子进程失效）
echo 'export PATH=/usr/lib/ccache:$PATH' >> /home/runner/.bashrc
source /home/runner/.bashrc
export PATH=/usr/lib/ccache:$PATH

# 修复dl目录权限（加容错，避免警告）
mkdir -p dl >/dev/null 2>&1
chmod 777 dl >/dev/null 2>&1
echo "Fixed dl directory permission"
