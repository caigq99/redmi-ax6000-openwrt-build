# Redmi AX6000 OpenClash 固件构建

基于 [hanwckf/immortalwrt-mt798x](https://github.com/hanwckf/immortalwrt-mt798x)（ImmortalWrt 21.02 / Linux 5.4 / MT7986A），
只编译 Xiaomi Redmi Router AX6000，并内置 OpenClash。

## 运行

- push 到 `main` 自动触发，或 Actions 页面手动 Run workflow。
- 矩阵任务同时构建两种布局：
  - `uboot`：第三方 U-Boot 布局，产物含 `factory.bin` 和 `sysupgrade.bin`。
  - `stock`：原厂分区布局，产物只有 `sysupgrade.bin`。

## 产物

Actions run 页面底部两个 artifact：

- `redmi-ax6000-openclash-uboot`
- `redmi-ax6000-openclash-stock`

每个都包含镜像、`.manifest` 和 `sha256sums`。

## 刷机前

- 先备份 BL2 / Nvram / Bdata / Factory / FIP。
- 镜像布局必须与设备当前 bootloader/分区布局一致，否则可能无法启动。
- 首次刷 U-Boot 布局通过 U-Boot 网页刷 `factory.bin`；原厂布局用 `sysupgrade -n` 刷 `sysupgrade.bin`。

## OpenClash

- 固件内置 LuCI 应用，但**不包含 Clash/Mihomo 内核**。
- 首次启动需在 OpenClash 页面更新内核（MT7986 选 `linux-arm64`），或提前把内核放到 `/etc/openclash/core/`。
- 128MB NAND，规则库/内核注意占用。
