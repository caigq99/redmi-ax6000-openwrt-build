#!/usr/bin/env bash
set -euo pipefail

LAYOUT="${1:?usage: build.sh uboot|stock}"

case "$LAYOUT" in
  uboot) DEVICE="xiaomi_redmi-router-ax6000" ;;
  stock) DEVICE="xiaomi_redmi-router-ax6000-stock" ;;
  *) echo "unknown layout: $LAYOUT (use uboot or stock)" >&2; exit 1 ;;
esac

SRC="/work/src"
rm -rf "$SRC"

git clone --depth=1 --branch openwrt-21.02 \
  https://github.com/hanwckf/immortalwrt-mt798x.git "$SRC"

cd "$SRC"

echo "== upstream commit: $(git log -1 --oneline)"
echo "== layout: $LAYOUT -> $DEVICE"

ok=0
for i in 1 2 3; do
  if ./scripts/feeds update -a; then ok=1; break; fi
  echo "feeds update failed (attempt $i), retrying..." >&2
  sleep 5
done
if [ "$ok" -ne 1 ]; then
  echo "ERROR: feeds update failed" >&2
  exit 1
fi

./scripts/feeds install -a

cp -f defconfig/mt7986-ax6000.config .config

# 只保留 Redmi AX6000 这一款机型
sed -i '/^CONFIG_TARGET_DEVICE_/d' .config

cat >> .config <<EOF
CONFIG_TARGET_DEVICE_mediatek_mt7986_DEVICE_${DEVICE}=y
CONFIG_TARGET_DEVICE_PACKAGES_mediatek_mt7986_DEVICE_${DEVICE}=""
CONFIG_PACKAGE_luci-app-openclash=y
EOF

make defconfig

# 断言：目标设备只剩一个，OpenClash 没有被 defconfig 丢弃
COUNT=$(grep -c '^CONFIG_TARGET_DEVICE_mediatek_mt7986_DEVICE_.*=y$' .config || true)
if [ "$COUNT" -ne 1 ]; then
  echo "ERROR: expected exactly 1 target device, got $COUNT" >&2
  grep '^CONFIG_TARGET_DEVICE_' .config >&2 || true
  exit 1
fi

grep '^CONFIG_TARGET_DEVICE_' .config
grep '^CONFIG_PACKAGE_luci-app-openclash=y' .config

make download -j"$(nproc)" || make download -j1 V=s
make -j"$(nproc)" V=s

echo "== images:"
ls -lh bin/targets/mediatek/mt7986/

echo "== OpenClash packages in manifest:"
grep -E '^(luci-app-openclash|ruby|ruby-yaml|bash|ip-full|libcap)' \
  bin/targets/mediatek/mt7986/*.manifest || true
