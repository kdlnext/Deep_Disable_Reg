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

## ✨ 核心特性

- **三路深度检索**：同时结合 `/data/system/packages.list`、`dumpsys package` 与 `pm list packages -u` 进行扫描，突破系统对 `sharedUserId` 或隐藏系统包的常规查询限制。
- **四轮防自愈调度**：在系统完全启动（`sys.boot_completed=1`）后的 **15 秒、30 秒、60 秒、120 秒** 分别执行一次扫描与禁用，有效应对开机后基带/SIM 卡加载延迟触发的系统自动恢复机制。
- **纯禁用、零后台驻留**：采用 `pm disable` + `appops` 禁止后台运行的纯禁用策略，不常驻守护进程、不循环强杀进程；4 轮执行完毕后脚本自动退出，**零额外耗电**。
- **核心白名单保护**：内置核心系统包白名单（`android`、`com.android.systemui`、`com.android.settings`、`com.android.phone`），不修改任何系统分区文件，避免卡开机风险。

---

## 📦 安装方法

1. 下载最新版本的 `Deep_Disable_Reg_v1.0.zip`。
2. 打开 **Magisk / KernelSU / APatch**，选择「模块」->「从本地安装」。
3. 刷入 ZIP 包并重启设备即可生效。

---

## 🔍 生效验证

重启进入桌面并等待约 **2 分钟**（确保 4 轮扫描执行完毕）后，可通过 ADB 或 Termux（Root 权限）进行验证：

### 1. 查看模块运行日志
```bash
su -c 'cat /data/adb/modules/Deep_Disable_Reg/disable.log'
