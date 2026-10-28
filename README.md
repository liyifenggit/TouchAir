# TouchAir 📡

<p align="center">
  <img src="AppIcon_Preview.png" width="160" height="160" alt="TouchAir Icon" />
</p>

<p align="center">
  <strong>专为 MacBook 触控条 (Touch Bar) 打造的访达全能效率神器</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2011.0%2B-blue?style=flat-square&logo=apple" alt="Platform" />
  <img src="https://img.shields.io/badge/Language-Swift%206-orange?style=flat-square&logo=swift" alt="Language" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License" />
</p>

---

## 🌟 简介

**TouchAir** 是一款极简、现代、零侵入的 macOS 后台菜单栏常驻工具。

当你在 **访达 (Finder)** 中选中任意文件时，MacBook 的 **触控条 (Touch Bar)** 会立刻亮起一套精美的高效动作栏，让你脱离鼠标和繁琐的快捷键组合，指尖轻触即可搞定文件管理：

```text
[ 📡 隔空投送: 文件名 ]    [ ✏️ 重命名 ]    [ 🗑️ 移至废纸篓 ]      [ ✕ ]
      (Apple 经典蓝)          (工具暖橙色)        (警示红色)
```

## ✨ 核心特性

- 📡 **隔空投送 (AirDrop) 秒投**
  - 配备自主矢量渲染的官方蓝白同心圆雷达波纹图标；
  - 触控条轻按一下，屏幕中央瞬间呼出系统隔空投送面板，选人即发。
- ✏️ **一键触控重命名 (Inline Rename)**
  - 轻触触控条上的铅笔图标，选中的文件名立刻变为高亮编辑框；
  - 双手无需离开键盘，直接打新名字按回车完成更名。
- 🗑️ **安全移至废纸篓 (Safe Trash)**
  - 省去按反人类的 `Cmd + Delete` 快捷键，轻按触控条垃圾桶按钮即可将文件扔进废纸篓；
  - 接入 macOS 原生安全回收机制，若有误触随时按 `Cmd + Z` 即可一键撤销恢复。
- 💎 **系统级置顶渲染 (System Modal)**
  - 突破 macOS 触控条全宽控制条（Full Control Strip）的遮挡限制，使用底层 Direct IMP 直连系统模态，确保 100% 稳定亮起。
- 🍃 **极致轻量**
  - 仅约 136 KB 可执行文件，后台内存占用仅 ~15MB，CPU 占用 0.0%，完全无感静默运行。

---

## 🛠️ 编译与打包

本项目无需庞大的 Xcode IDE，直接使用 macOS 自带的 Swift 命令行工具链即可极速编译：

```bash
git clone https://github.com/liyifenggit/TouchAir.git
cd TouchAir

# 一键极速编译打包并自动代码签名
./build.sh

# 启动体验
open build/TouchAir.app
```

编译产物将生成在 `build/TouchAir.app`。

---

## 🚀 开机自启设置

1. 打开 **系统设置 -> 通用 -> 登录项**；
2. 在“登录时打开”列表中点击 `+` 号；
3. 选择 `TouchAir.app` 添加即可。

---

## 📄 开源许可证

本项目基于 [MIT 许可证](LICENSE) 开源。
