# 机械革命旷世16 黑苹果 EFI 与配置文档

一台 **机械革命旷世16（Mechanical Revolution Kuangshi 16）** 笔记本的黑苹果（Hackintosh）EFI 与完整配置文档归档。

> ⚠️ **本仓库为公开仓库，`config.plist` 中的序列号 / MLB / UUID 已脱敏为占位符。**
> 若要实际使用此 EFI 启用 iMessage / FaceTime 等功能，请把 `EFI/OC/config.plist` 中
> `PlatformInfo → Generic` 下的 `SystemSerialNumber`、`MLB`、`SystemUUID`
> 替换成**你自己的**合法值（或直接用 OpenCore Configurator / ProperTree 重新生成）。

---

## 硬件配置

| 部件 | 型号 |
|---|---|
| CPU | Intel Core i7-13700H（6 性能核 + 8 能效核，14 核 20 线程） |
| 显卡 | NVIDIA GeForce RTX 4060 Laptop GPU 8GB（NullMoth NVRM 驱动栈） |
| 内存 | 32GB DDR4 3200MHz（2×16GB 双通道） |
| 存储 | WD_BLACK SN770 1TB（系统盘）+ Intel 512GB |
| 无线 | Intel AX 系列 CNVi（AirportItlwm 驱动，Wi-Fi 6/6E） |
| 有线 | Realtek RTL8111/RTL8125 |
| 声卡 | ALC256（layout-id 70，AppleALC） |
| 系统 | macOS 26.x（Tahoe），OpenCore 引导 |

## 目录结构

```
.
├── EFI/                      # OpenCore 引导分区完整内容
│   ├── BOOT/                 # 引导加载器
│   └── OC/
│       ├── config.plist      # 主配置（已脱敏）
│       ├── ACPI/             # SSDT 补丁
│       ├── Drivers/          # UEFI 驱动（OpenCanopy 等）
│       ├── Kexts/            # 内核扩展
│       ├── Resources/        # 引导主题（Acidanthera Syrah 等）
│       └── Tools/            # 实用工具
├── docs/                     # 配置文档
│   ├── 黑苹果配置终极指南.md   # 主文档（推荐先看这份）
│   ├── 黑苹果配置总览.md       # 深度参考（声卡修复等）
│   └── 机械革命旷世16-黑苹果EFI配置说明.md
└── scripts/                  # 声卡修复辅助脚本
```

## 文档导读

- **`docs/黑苹果配置终极指南.md`**：13 章节的完整指南，涵盖硬件清单、EFI 目录结构、每个 kext 的作用与官方下载链接、SSDT 说明、boot-args 逐项解释、重装 checklist、排错与回滚。**重装系统或配同款机器，照这份走。**
- **`docs/黑苹果配置总览.md`**：记录声卡（AppleHDA/KDK）修复的完整过程，这是最难排查、最容易复发的一个坑。
- **`docs/机械革命旷世16-黑苹果EFI配置说明.md`**：kext 按加载顺序列全、带官方下载链接的清单。

## 重要说明

1. **N 卡睡眠唤醒**：NullMoth 社区 NVRM 驱动在 macOS 26 上睡眠唤醒不可靠，已采用 `sleep=0`（关屏不睡机）方案——系统持续运行，只关闭屏幕，动鼠标键盘秒亮。这是当前最稳的做法。
2. **AirportItlwm 版本锁**：锁死 macOS 23~25，升级系统前必须先确认驱动兼容，否则 Wi-Fi 失效。
3. **OpenCanopy 版本**：必须与 OpenCore 主程序同版本。
4. **VirtualSMC 包内的 SMCLightSensor 不要装**：本机无机箱光线传感器，装了会导致"系统设置 → 显示器"面板卡顿数秒。

## 免责声明

本项目仅用于个人学习与备份归档。macOS 在非 Apple 硬件上的安装请遵守 Apple 软件许可协议。作者不对使用本仓库内容造成的任何损失负责。
