# Bypass MDM Enhanced

[English](README.md)

本工具在 Assaf Dori 原始脚本的基础上进行了功能扩展。由 rponeawa 开发的增强版本通过对付费工具 micaixin.cn 的二进制文件进行逆向工程分析，整合了其核心绕过与持久化逻辑。

---

## 技术增强 (逆向自 micaixin.cn)

通过二进制分析，本版本实现了以下技术特性：

**1. 网络域名屏蔽 (支持 IPv4 与 IPv6)**
*   增加了额外的 Apple MDM 端点：`gdmf.apple.com`、`acmdm.apple.com` 以及 `albert.apple.com`。
*   在系统 hosts 文件中同步应用 IPv4 (0.0.0.0) 和 IPv6 (::) 条目，防止在 VPN 环境下通过 IPv6 隧道进行连接尝试。

**2. 系统守护进程抑制**
*   初始化系统标志位：`/var/db/.com.apple.mdmclient.daemon.forced_disable`。
*   `mdmclient` 守护进程在启动序列中会检查此标志。一旦检测到，该进程将立即终止，从而阻断后台 MDM 同步。

**3. 直接修改配置 Profile**
*   利用 `PlistBuddy` 修改 `/var/db/ConfigurationProfiles/Settings/com.apple.ManagedClient.plist`。
*   将以下布尔键值显式设置为 `false`：`CloudConfigRecordFound`、`CloudConfigHasActivationRecord` 以及 `CloudConfigProfileInstalled`。

**4. 文件系统属性锁定**
*   使用 `chflags` 对所有修改后的配置文件及标记应用 `uchg` (用户不可变) 标志。
*   此操作确保 macOS 内核无法在系统更新或自动化维护期间覆盖或删除绕过配置。

**5. 状态掩盖标记**
*   部署特定标记文件，包括 `.CloudConfigDelete` 和 `.cloudConfigUserSkippedEnrollment`。
*   这些标记指示系统设置进程跳过远程管理注册序列。

---

## 安装与使用说明

请按照以下步骤在全新安装 macOS 过程中绕过 MDM 注册：

**1. 关机**
执行 Mac 的强制关机操作。

**2. 进入恢复模式**
*   Apple Silicon (M系列芯片)：按住电源键直至出现启动选项。
*   Intel 处理器：在启动过程中按住 Command + R。

**3. 网络激活**
连接 Wi-Fi 网络以确保 Mac 已激活。

**4. 终端初始化**
从顶部菜单栏选择“实用工具”，并打开“终端”。

**5. 执行脚本**
运行以下命令：
```bash
curl -L https://raw.githubusercontent.com/rponeawa/bypass-mdm-enhanced/main/bypass-mdm-enhanced.sh -o bypass-mdm.sh && chmod +x ./bypass-mdm.sh && ./bypass-mdm.sh
```

**6. 磁盘卷检测**
脚本将自动识别 System 卷和 Data 卷。

**7. 绕过选项**
选择选项 1: "Bypass MDM from Recovery"。

**8. 账户配置**
配置临时管理员账户或使用默认值。

**9. 完成操作**
等待提示：“MDM Bypass Completed Successfully”。

**10. 重启设备**
退出终端并重启 Mac。

---

## 安装后后续步骤

**11. 身份验证**
使用临时账户登录 (默认值: Apple / 1234)。

**12. 设置助手**
跳过所有初始提示 (Apple ID、Siri、Touch ID、定位服务)。

**13. 创建正式账户**
前往“系统设置 > 用户与群组”，创建一个永久的管理员账户。

**14. 账户切换**
注销临时账户，并登录新创建的正式账户。

**15. 系统清理**
在“系统设置”中删除临时的管理员账户。

---

## 故障排除

### 卷检测失败
确认设备处于恢复模式，并且目标磁盘上已存在有效的 macOS 安装。

### 权限被拒绝
确保脚本具有执行权限：`chmod +x bypass-mdm-enhanced.sh`。

---

**免责声明**: 本工具仅供教育与研究使用。
