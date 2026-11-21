# Deep_Disable_Reg

一个轻量级 Magisk / KernelSU / APatch 模块，用于在 Android（特别是 ColorOS 等定制系统）开机后深度检索并禁用三大运营商的设备管理（DM）与自注册组件，减少后台静默自注册与唤醒。

- **模块名称**：`Deep_Disable_Reg`
- **当前版本**：`v1.0`
- **作者**：`kdlnext`

---

## 🎯 针对目标

本模块通过关键字匹配，重点检测并屏蔽以下运营商自注册/管理服务组件：

| 运营商 | 目标关键字 | 说明 |
| :--- | :--- | :--- |
| **中国移动** | `regservice` | 移动设备管理（DM）与终端自注册服务 |
| **中国联通** | `systemhelper` | 联通终端自注册辅助服务组件 |
| **中国电信** | `ctautoregist` | 电信终端自注册服务 |

---

## 🕵️ 关于移动 `regservice` 的深度隐藏机制

在 ColorOS 等定制系统中，如中国移动的 `regservice`（如 `com.coloros.regservice`）并非普通系统应用，而是采用了**极高隐蔽性的底层隐藏与自愈机制**：

1. **常规工具完全不可见**：该组件通过 `sharedUserId` 与系统底层框架/内核级白名单过滤，在「系统设置 -> 应用管理」、常规冻结工具（如钛备份、Swift Backup、冰箱、黑阈等）甚至标准的 `pm list packages` 命令中均会被隐藏，导致用户误以为手机里不存在该服务或已经卸载。
2. **重启与网络触发自愈**：即便手动通过底层命令将其禁用，系统在重启、识别 SIM 卡或切换移动网络时，仍可能触发自愈机制将其重新启用。
3. **本模块的应对方案**：绕过常规应用列表，直接从底层包注册表 `/data/system/packages.list` 与 `dumpsys package` 中提取真实包名，并在开机后 **15s / 30s / 60s / 120s** 执行四轮强力禁用与后台权限封锁。

---

---

## ✨ 核心特性

- **三路深度检索**：同时结合 `/data/system/packages.list`、`dumpsys package` 与 `pm list packages -u` 进行扫描，彻底穿透系统对隐藏包的查询屏蔽。
- **四轮防自愈调度**：在系统完全启动（`sys.boot_completed=1`）后的 **15 秒、30 秒、60 秒、120 秒** 分别执行一次扫描与禁用，应对基带/SIM 卡延迟加载触发的自动恢复。
- **纯禁用、零后台驻留**：采用 `pm disable` + `appops` 禁止后台运行的纯禁用策略，不常驻守护进程、不循环强杀；4 轮执行完毕后脚本自动退出，**零额外耗电**。
- **核心白名单保护**：内置核心系统包白名单（`android`、`com.android.systemui`、`com.android.settings`、`com.android.phone`），不修改任何系统分区文件，避免卡开机风险。

---

## 📦 安装方法

1. 下载最新版本的 `Deep_Disable_Reg_v1.0.zip`。
2. 打开 **Magisk / KernelSU / APatch**，选择「模块」->「从本地安装」。
3. 刷入 ZIP 包并重启设备即可生效。

---

## 🔍 隐藏组件禁用状态自查方案（ADB / 手机终端）

由于 `regservice` 等组件在系统界面和常规冻结软件中不可见，**请勿通过系统设置判断其状态**。

重启进入桌面并等待约 **2 分钟**（确保 4 轮扫描完成）后，可通过以下任意方式进行**独立底层自查**（不依赖模块日志）：

> **运行环境说明：**
> - **手机 Termux / 终端**：直接运行下方 `su -c '...'` 命令。
> - **电脑 ADB**：在下方命令最前面加上 `adb shell ` 即可（例如 `adb shell su -c '...'`）。

---

### 1. 独立扫描并核对底层真实禁用状态（最核心）
直接从系统底层注册表 `/data/system/packages.list` 穿透抓取包名，并用 `dumpsys package` 核对真实状态码：
```bash
su -c 'for p in $(awk "{print \$1}" /data/system/packages.list | grep -iE "regservice|systemhelper|ctautoregist"); do echo "=== $p ==="; dumpsys package "$p" | grep -E "enabled=|stopped=" | head -n 3; done'
```

---

### 2. 查看模块日志与已捕获的隐藏包清单
```bash
su -c 'cat /data/adb/modules/Deep_Disable_Reg/disable.log'
```
