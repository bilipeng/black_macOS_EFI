# 机械革命旷世16 黑苹果 EFI 配置说明

> 一份可复用的装机/恢复文档，记录本机 EFI 的完整驱动方案、目录结构、下载来源与本次解决的问题。
> 适用于重装、迁移 EFI、换 SSD 后重建，或排查同类机型时参考。
>
> 建档日期：2026-11-16
> OpenCore 版本：DBG-109（2026-10-22 编译）
> macOS 版本：26.7.2（Build 25G332，Darwin 25.6.0）

---

## 一、硬件与模拟机型

| 项目 | 真实硬件 | 备注 |
|---|---|---|
| CPU | Intel i7-13700H（6 性能核 + 8 能效核，14 核 20 线程，2.92GHz） | 13 代酷睿，需 `CpuTopologyRebuild` 重建大小核拓扑 |
| 显卡 | NVIDIA GeForce RTX 4060 Laptop GPU，8GB，PCIe x8（设备 ID 0x28a0） | 用 NullMoth NVRM 驱动栈，Metal 3 硬件加速已开启 |
| 内存 | 32GB DDR4 3200MHz（2×16GB 三星 M471A2K43DB1-CWE） | — |
| 主硬盘 | WD_BLACK SN770 1TB（NVMe） | 装 macOS（APFS）+ 一个 NTFS 数据分区 |
| 副硬盘 | INTEL SSDPEKNU512GZ 512GB（NVMe） | NTFS 分区，Windows 用 |
| 无线网卡 | Intel CNVi AX 系列（PCI 8086:51f1，子系统 0074），Wi-Fi 6/6E | 用 AirportItlwm + itlwm 驱动 |
| 蓝牙 | Intel（AX 系列自带） | IntelBluetoothFirmware + IntelBTPatcher |
| 有线网卡 | Realtek RTL8111/8168（PCI 10ec:8168） | 实测可用 |
| 声卡 | Realtek HD Audio（HDEF@1F,3） | layout-id = 70 |
| 摄像头 | UVC HD Webcam（VID 11134 / PID 46673） | UVC 免驱 |
| 屏幕 | 内建 2560×1600，HiDPI 显示为 1280×800 @ 240Hz | — |
| 电池 | OEM，3200mAh，循环 219 次 | SMCSuperIO 系列 SMC 驱动 |
| 模拟机型 | MacBookPro16,2 | board-id: Mac-5F9802EFE386AA28 |

---

## 二、EFI 目录结构

```
EFI/
└── OC/
    ├── OpenCore.efi                    # 引导核心（DBG-109）
    ├── config.plist                    # 主配置文件
    ├── .contentFlavour                 # OC 内容标记
    ├── .contentVisibility
    ├── ACPI/                           # 9 个 SSDT（见第四节）
    │   ├── SSDT-SBUS.aml
    │   ├── SSDT-EC.aml
    │   ├── SSDT-GPI0.aml
    │   ├── SSDT-MCHC.aml
    │   ├── SSDT-PLUG-ALT.aml
    │   ├── SSDT-RTCAWAC.aml
    │   ├── SSDT-USB-Reset.aml
    │   ├── SSDT-USBX.aml
    │   └── SSDT-XOSI.aml
    ├── Drivers/                        # UEFI 驱动（按加载顺序）
    │   ├── apfs_aligned.efi
    │   ├── HfsPlus.efi
    │   ├── OpenCanopy.efi              # GUI 引导菜单驱动（必须）
    │   ├── UsbMouseDxe.efi             #引导阶段 USB 鼠标支持
    │   ├── OpenRuntime.efi
    │   └── ResetNvramEntry.efi         # 引导菜单里的"重置 NVRAM"项
    ├── Kexts/                          # 30 个 kext（见第三节；SMCLightSensor 已移除）
    │   ├── AMFIPass.kext
    │   ├── AirportItlwm.kext
    │   ├── AppleALC.kext
    │   ├── BlueToolFixup.kext
    │   ├── BrightnessKeys.kext
    │   ├── CpuTopologyRebuild.kext
    │   ├── ECEnabler.kext
    │   ├── IO80211FamilyLegacy.kext
    │   ├── IOSkywalkFamily.kext
    │   ├── IntelBTPatcher.kext
    │   ├── IntelBluetoothFirmware.kext
    │   ├── Lilu.kext
    │   ├── NVMeFix.kext
    │   ├── RaptorLakeI2C.kext
    │   ├── RealtekRTL8111.kext
    │   ├── RestrictEvents.kext
    │   ├── SMCBatteryManager.kext
    │   ├── SMCProcessor.kext
    │   ├── SMCSuperIO.kext
    │   ├── USBMap.kext
    │   ├── USBToolBox.kext
    │   ├── UTBDefault.kext
    │   ├── VirtualSMC.kext
    │   ├── VoodooI2C.kext              # 内含 PlugIns: VoodooI2CServices, VoodooGPIO, VoodooInput
    │   ├── VoodooI2CHID.kext
    │   ├── VoodooPS2Controller.kext    # 内含 PlugIns: Keyboard, Mouse, Trackpad
    │   ├── WhateverGreen.kext
    │   ├── XHCI-unsupported.kext
    │   └── itlwm.kext
    ├── Resources/                      # 引导 GUI 主题与字体
    │   ├── Font/                       # Terminus 字体（Font_1x/2x.bin/.png）
    │   ├── Image/Acidanthera/
    │   │   ├── GoldenGate/             # 山峦背景主题（当前未用）
    │   │   ├── Chardonnay/             # 复古图标主题（未用）
    │   │   └── Syrah/                  # ✅ 当前使用：原生极简青绿图标，无背景图=纯黑
    │   └── Label/                      # Apple.lbl 等标签文件
    └── Tools/
        └── NullMothSafe.efi            # N 卡驱动的配套工具
```

> **重要**：NVIDIA 显卡后续的 NVRM 驱动栈（NVRM / NVAccel / NVRMFB / NVRMAGDC，版本 2.7.2）不在
> Kexts 目录里，而是由 `NullMothSafe.efi` 工具在引导阶段注入（bundle id: com.nullmoth.*）。
> 相关 boot-args：`nvrmacpibl=1 nvfb=1 nvaccel=1 nvfbheads=2 -nvkmsnosmooth gfxrst=4`。

---

## 三、Kext 驱动逐一说明

> 全部按 `config.plist → Kernel → Add` 的加载顺序排列。
> "来源"列的链接为官方发布页，下载时请认准与本机 OpenCore / macOS 版本匹配的发行版。

### 3.1 基础依赖

| Kext | 作用 | 来源 |
|---|---|---|
| **Lilu 1.7.3** | 所有插件的注入底座，几乎其它 kext 都依赖它 | https://github.com/acidanthera/Lilu/releases |
| **VirtualSMC 1.3.9** | 模拟 Apple SMC 芯片，是 SMC 系列传感器驱动的底座 | https://github.com/acidanthera/VirtualSMC/releases |

### 3.2 CPU / 电源管理

| Kext | 作用 | 来源 |
|---|---|---|
| **CpuTopologyRebuild 2.0.2** | 重建 13 代酷睿 P 核/E 核拓扑，让系统正确识别 14 核 | https://github.com/b00t0x/CpuTopologyRebuild |
| **SMCProcessor 1.3.9** | CPU 温度、频率传感（VirtualSMC 插件） | VirtualSMC 包内 |
| **SMCSuperIO 1.3.9** | 风扇转速、硬件监控（VirtualSMC 插件） | VirtualSMC 包内 |
| **SMCBatteryManager 1.3.9** | 电池电量、循环次数（VirtualSMC 插件） | VirtualSMC 包内 |
| **RestrictEvents 1.1.7** | 屏蔽不受支持硬件的报错弹窗、CPU 名称修正 | https://github.com/acidanthera/RestrictEvents/releases |

> 实测结论：CPU 变频正常。对应 boot-args `revpatch=sbvmm,cpuname`；
> `X86PlatformPlugin` 已接管电源管理，睿频表识别到 4100/3800MHz。

### 3.3 显卡

| Kext | 作用 | 来源 |
|---|---|---|
| **WhateverGreen 1.7.2** | 显卡通用补丁（配合 N 卡注入帧缓冲） | https://github.com/acidanthera/WhateverGreen/releases |
| **NVRM 驱动栈 2.7.2**（NullMoth，引导期注入） | RTX 4060 的硬件加速驱动，Metal 3 已启用 | 配套 `Tools/NullMothSafe.efi` 使用；boot-args 见第五节 |

> 实测：GPU 温度 56°C、设备占用 32%，硬件加速正常。
> `nvfbheads=2` 表示开 2 个显示输出头（原先为 4，已改小以减少显示器面板枚举卡顿）。

### 3.4 声卡

| Kext | 作用 | 来源 |
|---|---|---|
| **AppleALC 1.9.8** | Realtek HD 声卡驱动，layout-id = 70（boot-args `alcid=70`） | https://github.com/acidanthera/AppleALC/releases |

> 实测：内置麦克风、内置扬声器输入/输出均正常（Built-in Input/Output）。

### 3.5 网卡（Wi-Fi / 蓝牙 / 有线）

| Kext | 作用 | 来源 |
|---|---|---|
| **AirportItlwm 1.0.0** | Intel Wi-Fi 6/6E 驱动（native Wi-Fi 菜单），限 macOS 23~25 | https://github.com/OpenIntelWireless/itlwm/releases |
| **itlwm.kext** | AirportItlwm 的底层依赖 | 同上仓库 |
| **IOSkywalkFamily.kext** | 网络框架（限 macOS 23~25） | 系统提取 / OpenIntelWireless 说明 |
| **IO80211FamilyLegacy.kext** + **AirPortBrcmNIC.plugin** | 旧版 80211 框架（限 macOS 23~25） | 系统提取 / 社区提供 |
| **IntelBluetoothFirmware 2.5.2** | Intel 蓝牙固件加载 | https://github.com/OpenIntelWireless/IntelBluetoothFirmware/releases |
| **IntelBTPatcher 2.5.2** | 蓝牙补丁（配合 BlueToolFixup） | 同上仓库 |
| **BlueToolFixup 2.7.3** | 蓝牙协议栈修复（Lilu 插件） | https://github.com/acidanthera/BrcmPatchRAM/releases |
| **RealtekRTL8111 2.4.2** | 有线网卡 RTL8111/8168 驱动 | https://github.com/Mieze/RTL8111_driver_for_OS_X |

> Wi-Fi 限制说明：`MinKernel=23.0.0 / MaxKernel=25.99.99`，即只支持 macOS 23~25。
> **升级到更高版本 macOS 前，必须先更新这套网卡驱动，否则 Wi-Fi 会失效。**
> 关于 AirDrop：社区有 ForbiddenItlwm 项目能让 Intel 网卡实现隔空投送，但为 AI 辅助编写的
> 实验性测试版、有内核崩溃风险，本机未采用（当前 Wi-Fi 正常即可满足上网需求）。

### 3.6 输入设备（触控板 / 键盘 / 鼠标）

| Kext | 作用 | 来源 |
|---|---|---|
| **VoodooI2C 2.9.1**（含 VoodooI2CServices / VoodooGPIO / VoodooInput） | I2C 总线触控板驱动，实现原生多点触控手势 | https://github.com/alexandred/VoodooI2C/releases |
| **VoodooI2CHID** | I2C HID 设备驱动 | 同上仓库 |
| **RaptorLakeI2C** | 13 代（Raptor Lake）平台 I2C 控制器补充驱动 | 社区提供 |
| **VoodooPS2Controller 2.3.8**（含 Keyboard / Mouse / Trackpad） | PS/2 键盘鼠标驱动 | https://github.com/acidanthera/VoodooPS2/releases |
| **BrightnessKeys 1.0.4** | 屏幕亮度快捷键（F1/F2） | https://github.com/acidanthera/BrightnessKeys/releases |

> 实测：触控板是 VoodooI2C 完整的原生精确式触控板链路（Precision Touchpad + NativeEngine +
> AppleMultitouchDevice），手势正常。键盘按 `Fn+F6/F7` 可调背光亮度。
> boot-args `-vi2c-force-polling` 用于修复 I2C 触控板唤醒后失灵的问题。

### 3.7 USB

| Kext | 作用 | 来源 |
|---|---|---|
| **USBToolBox + UTBDefault** | USB 端口定制工具链（生成端口映射） | https://github.com/USBToolBox/kext |
| **USBMap.kext** | 定制好的 USB 端口映射（让每个 USB 口正确工作、修复睡眠唤醒） | 由 USBToolBox 工具按本机端口生成 |
| **XHCI-unsupported.kext** | 部分芯片组 XHCI 控制器支持补丁 | 社区提供 |

> USB 端口定制是黑苹果睡眠唤醒稳定的关键一环，重装时务必保留 USBMap.kext。

### 3.8 存储 / 其它

| Kext | 作用 | 来源 |
|---|---|---|
| **NVMeFix 1.1.4** | NVMe SSD 电源管理与兼容性修复 | https://github.com/acidanthera/NVMeFix/releases |
| **ECEnabler 1.0.6** | 修复 EC（嵌入式控制器）读取长度，电池等信息完整显示 | https://github.com/1Revenger1/ECEnabler |
| **AMFIPass 1.4.1** | AMFI 校验绕过（限 macOS 20+） | 社区提供；boot-args 配合 `-amfipassbeta amfi=0x80` |

---

## 四、ACPI 表（SSDT）说明

| 文件 | 作用 |
|---|---|
| **SSDT-EC.aml** | 创建虚拟 EC（Embedded Controller），供 macOS 电池/传感器使用 |
| **SSDT-PLUG-ALT.aml** | CPU 电源管理插件接管（X86PlatformPlugin，变频必需） |
| **SSDT-USBX.aml** | 定义 USB 电源属性，配合 USBMap 使用 |
| **SSDT-USB-Reset.aml** | USB 控制器重置，修复唤醒后 USB 失灵 |
| **SSDT-GPI0.aml** | GPIO 控制器定义（配合 VoodooGPIO / 触控板） |
| **SSDT-SBUS.aml** | SMBus 控制器启用（电池、传感器需要） |
| **SSDT-MCHC.aml** | 内存控制器定义 |
| **SSDT-RTCAWAC.aml** | RTC 唤醒兼容修复 |
| **SSDT-XOSI.aml** | 伪装 Windows 系统，让部分 ACPI 方法正确执行 |

---

## 五、boot-args 逐项解释

当前完整 boot-args（2026-11-16 最终版）：

```
-vi2c-force-polling -ibtcompatbeta revpatch=sbvmm,cpuname -amfipassbeta alcid=70 nvrmacpibl=1 nvfb=1 nvaccel=1 nvfbheads=2 -nvkmsnosmooth amfi_get_out_of_my_way=0x1 amfi=0x80 ipc_control_port_options=0 gfxrst=4
```

| 参数 | 作用 |
|---|---|
| `-vi2c-force-polling` | I2C 触控板强制轮询，修复唤醒后触控板失灵 |
| `-ibtcompatbeta` | Intel 蓝牙兼容性 beta 开关 |
| `revpatch=sbvmm,cpuname` | 系统版本补丁 + CPU 名称修正 |
| `-amfipassbeta` / `amfi=0x80` / `amfi_get_out_of_my_way=0x1` | AMFI 相关，配合 AMFIPass |
| `alcid=70` | 声卡 layout-id = 70 |
| `nvrmacpibl=1` / `nvfb=1` / `nvaccel=1` | N 卡驱动栈开关：帧缓冲、硬件加速 |
| `nvfbheads=2` | 显示输出头数量（从 4 改为 2，减少显示器面板枚举卡顿） |
| `-nvkmsnosmooth` | N 卡 KMS 相关修正 |
| `ipc_control_port_options=0` | 特定内核安全选项，避免某些 kext 崩溃 |
| `gfxrst=4` | 显卡复位方式（与唤醒相关，若唤醒黑屏可尝试调整此值） |

> **已移除的调试参数**（2026-11-16 关闭，因其持续写内核追踪日志造成隐性卡顿）：
> `keepsyms=1`、`-vsmcdbg`、`-alcdebug`、`-liludbg`
> 排错需要时可临时加回，稳定后务必移除。

---

## 六、关键 config.plist 设置

| 路径 | 值 | 说明 |
|---|---|---|
| `Misc → Boot → PickerMode` | `External` | 使用图形化引导菜单（OpenCanopy） |
| `Misc → Boot → PickerAttributes` | `17` | 启用鼠标/触控板 + 读取卷标图标 |
| `Misc → Boot → PickerVariant` | `Acidanthera\Syrah` | 原生极简青绿图标主题 + 纯黑背景 |
| `Misc → Boot → Timeout` | `0` | 禁用自动倒计时，纯手动选择系统 |
| `Misc → Boot → ShowPicker` | `True` | 每次启动都显示引导菜单 |
| `PlatformInfo → Generic → SystemProductName` | `MacBookPro16,2` | 模拟机型 |
| `PlatformInfo → Generic → ProcessorType` | `3841` | CPU 类型标识 |
| `UEFI → Drivers` | 见目录树 | OpenCanopy 必须在列 |
| `NVRAM → Add → boot-args` | 见第五节 | — |

### 已开启的关键 Quirks

**Kernel Quirks**：`AppleXcpmCfgLock`、`CustomSMBIOSGuid`、`DisableIoMapper`、
`DisableLinkeditJettison`、`PanicNoKextDump`、`PowerTimeoutKernelPanic`、
`ProvideCurrentCpuInfo`、`SetApfsTrimTimeout=-1`

**Booter Quirks**：`AllowRelocationBlock`、`AvoidRuntimeDefrag`、`EnableSafeModeSlide`、
`FixupAppleEfiImages`、`ProtectUefiServices`、`ProvideCustomSlide`、`RebuildAppleMemoryMap`、
`SetupVirtualMap`、`SyncRuntimePermissions`

> 这些 Quirks 是本机 13 代 Intel + N 卡平台稳定运行的关键，重建 config 时不要遗漏。

---

## 七、系统内配置（非 EFI）

### 7.1 电源/休眠（已优化，解决合盖无法唤醒）

```bash
sudo pmset -a hibernatemode 0      # 纯内存睡眠，不写磁盘（N 卡唤醒关键）
sudo pmset -a standby 0            # 禁止转入深度休眠
sudo pmset -a powernap 0           # 关闭睡眠中后台活动，杜绝 DarkWake
sudo pmset -a autopoweroff 0       # 禁止长时间后自动断电休眠
```

用 `pmset -g custom` 验证四项均为 0。

### 7.2 验证命令速查

```bash
# 查看已加载的第三方驱动
kextstat | grep -v com.apple

# CPU 实时频率（需 sudo）
sudo powermetrics --samplers cpu_power -i 1000 -n 3 | grep -i "frequency"

# Wi-Fi 信号强度
system_profiler SPAirPortDataType | grep "Signal / Noise"

# 休眠唤醒日志
pmset -g log | grep -iE "Wake|Sleep|DarkWake"

# 引导日志写入速率（验证 debug 是否关掉，应接近 0）
A=$(du -sk /var/db/diagnostics | cut -f1); sleep 5; B=$(du -sk /var/db/diagnostics | cut -f1); echo $((B-A)) KB/5s
```

---

## 八、下载清单（重建 EFI 时按此准备）

| 类别 | 下载内容 | 地址 |
|---|---|---|
| 引导核心 | OpenCorePkg（含 OpenCore.efi、OpenCanopy.efi、驱动） | https://github.com/acidanthera/OpenCorePkg/releases |
| 基础依赖 | Lilu | https://github.com/acidanthera/Lilu/releases |
| 声卡 | AppleALC | https://github.com/acidanthera/AppleALC/releases |
| 显卡 | WhateverGreen | https://github.com/acidanthera/WhateverGreen/releases |
| SMC 全家桶 | VirtualSMC（只用 Battery/Processor/SuperIO；**LightSensor 不要注入**，本机无此硬件，装了会导致显示器面板卡顿） | https://github.com/acidanthera/VirtualSMC/releases |
| 网卡 | itlwm（含 AirportItlwm / itlwm） | https://github.com/OpenIntelWireless/itlwm/releases |
| 蓝牙 | IntelBluetoothFirmware（含 BTPatcher） | https://github.com/OpenIntelWireless/IntelBluetoothFirmware/releases |
| 蓝牙补丁 | BlueToolFixup（在 BrcmPatchRAM 发布包内） | https://github.com/acidanthera/BrcmPatchRAM/releases |
| 触控板 | VoodooI2C（含 Services/GPIO/Input/HID） | https://github.com/alexandred/VoodooI2C/releases |
| 键鼠 | VoodooPS2Controller | https://github.com/acidanthera/VoodooPS2/releases |
| 亮度键 | BrightnessKeys | https://github.com/acidanthera/BrightnessKeys/releases |
| NVMe | NVMeFix | https://github.com/acidanthera/NVMeFix/releases |
| CPU 拓扑 | CpuTopologyRebuild | https://github.com/b00t0x/CpuTopologyRebuild |
| EC | ECEnabler | https://github.com/1Revenger1/ECEnabler |
| 有线网卡 | RealtekRTL8111 | https://github.com/Mieze/RTL8111_driver_for_OS_X |
| USB | USBToolBox（+ 本机生成的 USBMap.kext） | https://github.com/USBToolBox/kext |
| 主题资源 | OcBinaryData（Resources 文件夹） | https://github.com/acidanthera/OcBinaryData |
| 配置编辑 | ProperTree（编辑 config.plist） | https://github.com/corpnewt/ProperTree |
| N 卡驱动 | NullMoth NVRM 驱动栈 + NullMothSafe.efi | 随 EFI 备份保留（社区渠道获取） |

> **警告**：OpenCanopy.efi、OpenRuntime.efi 等 OC 自带驱动必须与 OpenCore 主程序**同版本**，
> 混用不同版本可能导致无法启动。下载时从同一个 OpenCorePkg 发布包里取。

---

## 九、本次排查与解决的问题记录（2026-11-16）

| # | 问题 | 诊断 | 解决方案 | 状态 |
|---|---|---|---|---|
| 1 | 硬件驱动全面检测 | kextstat / ioreg / 功能实测交叉验证 | 确认 11 项核心驱动正常；有线网卡、CPU 实测确认无问题 | ✅ |
| 2 | 系统设置→显示器面板卡顿数秒 | SMCLightSensor 驱动存在但无真实硬件，面板查询环境光超时 | 从 config 与 Kexts 目录移除 SMCLightSensor.kext | ✅ 待重启验证 |
| 3 | 引导界面丑（山峦背景） | PickerVariant=Auto 选中 GoldenGate 主题 | 改为 `Acidanthera\Syrah`（原生极简 + 纯黑背景） | ✅ 待重启验证 |
| 4 | 开机 5 秒自动进 Windows 来不及选 | Timeout=5 | 改为 `Timeout=0`，纯手动选择 | ✅ 待重启验证 |
| 5 | 合盖休眠后无法唤醒，只能强制关机 | DarkWake 循环；hibernatemode=3 + standby + powernap 叠加 | 用 pmset 改为 hibernatemode 0 等四项 | ✅ 已生效待实测 |
| 6 | 整机感觉卡、不流畅 | 三个 debug 开关持续写内核追踪日志（~1MB/5s） | 移除 keepsyms=1 / -vsmcdbg / -alcdebug / -liludbg | ✅ 待重启验证 |
| 7 | Wi-Fi 列表不按信号强度排 | macOS 原生排序规则（已保存网络优先）+ 第三方驱动差异 | 非故障，无需处理 | ℹ️ 说明 |
| 8 | AirDrop（隔空投送） | 社区 ForbiddenItlwm 项目可实现但有内核崩溃风险 | 未采用，保持现状 | ℹ️ 说明 |
| 9 | 键盘 RGB 颜色无法改 | 亮度走标准背光接口，颜色走厂商私有 EC 命令，macOS 无对应软件 | 未处理（可选：双系统设色后重启尝试保留） | ℹ️ 说明 |

### 备份文件

本次修改 config.plist 前留有备份，位于 `/Volumes/EFI/EFI/OC/`：
- `config.plist.bak.20261116_212137`
- `config.plist.bak.20261116_213031`
- `config.plist.bak.20261116_214753`

如需回退某一步，用对应备份覆盖 `config.plist` 即可。

---

## 十、已知限制与后续事项

1. **Wi-Fi 驱动版本锁**：AirportItlwm 限定 macOS 23~25，升级系统前先确认有对应新版本，否则 Wi-Fi 失效。
2. **AirDrop 不可用**：Intel 网卡黑苹果原生不支持隔空投送，如需该功能需承担实验性驱动风险。
3. **键盘 RGB 颜色**：macOS 下无法软件改色（机械革命私有 EC 命令），仅亮度可调。
4. **SD 读卡器 / 雷电**：未驱动，如日常不用可忽略。
5. **睡眠唤醒**：已按标准配置优化，若仍偶发黑屏，优先调整 `gfxrst` 启动参数值。
6. **重启验证清单**：本次 config 改动（第 2/3/4/6 项）均需重启生效，重启后按第七节命令逐项确认。
