#!/bin/bash
set -e
set -x  # 开启执行日志，方便排查

# 定位OpenWRT源码根目录
OPENWRT_ROOT_PATH="${OPENWRT_ROOT_PATH:-$(pwd)}"
cd "$OPENWRT_ROOT_PATH" || { echo "根目录不存在，退出！"; exit 1; }

# ===================== 核心优化：多镜像源配置（失败自动切换） =====================
# 定义国内镜像源列表（优先级：清华→中科大→阿里云）
PACKAGES_MIRRORS=(
  "https://mirrors.tuna.tsinghua.edu.cn/openwrt/packages.git;openwrt-24.10"
  "https://mirrors.ustc.edu.cn/openwrt/packages.git;openwrt-24.10"
  "https://mirrors.aliyun.com/openwrt/packages.git;openwrt-24.10"
)
LUCI_MIRRORS=(
  "https://mirrors.tuna.tsinghua.edu.cn/openwrt/luci.git;openwrt-24.10"
  "https://mirrors.ustc.edu.cn/openwrt/luci.git;openwrt-24.10"
  "https://mirrors.aliyun.com/openwrt/luci.git;openwrt-24.10"
)

# 1. 彻底清理旧Feeds（删缓存+配置，避免干扰）
rm -rf feeds/ feeds.conf.default feeds.conf.default.bak
rm -rf package/luci-app-ikoolproxy package/luci-theme-argon  # 新增清理argon缓存

# 2. 生成Feeds配置文件（移除argon的src-git配置）
cat > feeds.conf.default << EOF
src-git packages ${PACKAGES_MIRRORS[0]}
src-git luci ${LUCI_MIRRORS[0]}
src-git kenzo https://github.com/kenzok8/openwrt-packages.git;master
src-git small https://github.com/kenzok8/small.git;master
EOF

# 3. Feeds拉取（带镜像自动切换+3次重试）
function update_feeds_with_mirror() {
  local mirror_index=$1
  # 切换镜像源
  sed -i "s|src-git packages .*|src-git packages ${PACKAGES_MIRRORS[$mirror_index]}|g" feeds.conf.default
  sed -i "s|src-git luci .*|src-git luci ${LUCI_MIRRORS[$mirror_index]}|g" feeds.conf.default
  echo -e "\n🔍 尝试第 $((mirror_index+1)) 个镜像源：${PACKAGES_MIRRORS[$mirror_index]}"
  
  # 拉取Feeds（3次重试）
  for retry in {1..3}; do
    ./scripts/feeds update -a -f && return 0  # 拉取成功则退出函数
    echo "⚠️ 镜像源拉取失败，第 $retry/3 次重试..."
    sleep 10
    rm -rf feeds/  # 重试前清空缓存
  done
  return 1  # 该镜像源所有重试都失败
}

# 依次尝试镜像源，直到成功
for mirror_idx in 0 1 2; do
  if update_feeds_with_mirror $mirror_idx; then
    echo -e "\n✅ 镜像源 ${PACKAGES_MIRRORS[$mirror_idx]} 拉取成功！"
    break
  fi
  if [ $mirror_idx -eq 2 ]; then
    echo -e "\n❌ 所有镜像源都拉取失败，退出！"
    exit 1
  fi
done

# 4. 安装Feeds（强制安装核心包，确保xray-core/golang装上）
./scripts/feeds install -a
# 单独安装核心包（避免漏装）
./scripts/feeds install -p packages xray-core golang golang-x-net golang-x-sys
./scripts/feeds install -p kenzo luci-app-passwall2 v2ray-core sing-box msd_lite luci-app-msd_lite
./scripts/feeds install -p luci luci-i18n-base-zh-cn
./scripts/feeds install -p base ddns-scripts luci-app-ddns open-vm-tools

# 5. 拉取argon主题（直接克隆到package目录，带3次重试）
mkdir -p package/luci-theme-argon
for retry in {1..3}; do
  git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon && break
  echo "⚠️ argon主题拉取失败，第 $retry/3 次重试..."
  rm -rf package/luci-theme-argon
  sleep 10
done
# 安装argon本地包
./scripts/feeds install -p packages package/luci-theme-argon

# 6. 拉取iKoolProxy（带3次重试）
mkdir -p package/luci-app-ikoolproxy
for retry in {1..3}; do
  git clone --depth 1 https://github.com/ilxp/luci-app-ikoolproxy.git package/luci-app-ikoolproxy && break
  echo "⚠️ iKoolProxy拉取失败，第 $retry/3 次重试..."
  rm -rf package/luci-app-ikoolproxy
  sleep 10
done

# 7. 验证关键包是否拉取成功（提前排查）
echo -e "\n🔍 验证核心包源码目录："
if [ -d "feeds/packages/net/xray-core" ]; then
  echo "✅ xray-core源码已拉取"
else
  echo "❌ xray-core源码缺失，编译会失败！"
  exit 1
fi
if [ -d "feeds/packages/lang/golang" ]; then
  echo "✅ golang源码已拉取"
else
  echo "❌ golang源码缺失，编译会失败！"
  exit 1
fi
if [ -d "package/luci-theme-argon" ]; then
  echo "✅ argon主题源码已拉取"
else
  echo "❌ argon主题源码缺失！"
  exit 1
fi

echo -e "\n✅ 所有核心包拉取完成，可正常编译！"
