#!/usr/bin/env bash
set -euo pipefail

JOBS="${JOBS:-$(nproc)}"
WORKDIR="${GITHUB_WORKSPACE}"
SRC="${WORKDIR}/istoreos"
BRANCH="istoreos-24.10"

echo "=========================================="
echo " iStoreOS x86-64 Custom Build"
echo " PassWall + OpenClash"
echo "=========================================="

echo "[1/8] Install build dependencies"

sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  build-essential \
  clang \
  flex \
  bison \
  g++ \
  gawk \
  gcc \
  gettext \
  git \
  libncurses5-dev \
  libncurses-dev \
  libssl-dev \
  python3 \
  python3-setuptools \
  rsync \
  unzip \
  zlib1g-dev \
  file \
  wget \
  curl \
  subversion \
  swig \
  time \
  xsltproc \
  libxml-parser-perl \
  libusb-1.0-0-dev

echo "[2/8] Clone iStoreOS"

if [ ! -d "${SRC}/.git" ]; then
    git clone \
      --branch "${BRANCH}" \
      --single-branch \
      https://github.com/istoreos/istoreos.git \
      "${SRC}"
else
    git -C "${SRC}" fetch origin "${BRANCH}"
    git -C "${SRC}" checkout "${BRANCH}"
    git -C "${SRC}" pull --ff-only origin "${BRANCH}"
fi

cd "${SRC}"

echo "[3/8] Add PassWall feeds"

cp feeds.conf.default feeds.conf.default.bak

grep -q '^src-git passwall_packages ' feeds.conf.default || \
sed -i '1i src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' feeds.conf.default

grep -q '^src-git passwall_luci ' feeds.conf.default || \
sed -i '1i src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' feeds.conf.default

echo "[4/8] Update feeds"

./scripts/feeds update -a
./scripts/feeds install -a

echo "[5/8] Add OpenClash"

rm -rf package/luci-app-openclash

git clone \
  --depth=1 \
  https://github.com/vernesong/OpenClash.git \
  /tmp/openclash-src

mkdir -p package/luci-app-openclash

cp -a \
  /tmp/openclash-src/luci-app-openclash/. \
  package/luci-app-openclash/

echo "[6/8] Load configuration"

cp \
  "${WORKDIR}/configs/x86-64.config" \
  .config

make defconfig

echo "[7/8] Download source packages"

make download -j"${JOBS}"

echo "[8/8] Compile"

make -j"${JOBS}" V=s

echo "=========================================="
echo " BUILD FINISHED"
echo "=========================================="

ls -lh bin/targets/x86/64/
