# Bypass MDM Enhanced

[English Version / 英文版](README.md)

本项目在 Assaf Dori 原始脚本的基础上进行了功能扩展。此版本整合了通过对 micaixin.cn 商业工具进行技术分析，以及对多啦快解（Dora Fast Solve）脚本进行研究得出的核心绕过与持久化逻辑。

---

## 技术增强

此增强版本实现了通过二进制及脚本分析识别出的以下专业特性：

### 1. 源自 micaixin.cn 的逻辑
*   **系统守护进程抑制**：初始化系统标志位 `/var/db/.com.apple.mdmclient.daemon.forced_disable`。该标志位通过 `chmod 000` 与 `chflags uchg` 的组合操作，强制阻止 MDM 客户端初始化启动。
*   **字节级配置篡改**：利用 `PlistBuddy` 在系统核心数据库中将 `CloudConfigRecordFound`、`CloudConfigHasActivationRecord` 以及 `CloudConfigProfileInstalled` 显式设置为 `false`。
*   **第三方组件清理**：自动扫描并删除与 Jamf、Addigy、Kandji 等第三方 MDM 厂商相关的守护进程及代理文件。
*   **网络配置重置**：移除系统级网络接口及 Wi-Fi 配置 Plist 文件，切断已存在的受管网络连接。
*   **IPv6 协议屏蔽**：在 hosts 文件中应用 IPv6 (`::`) 屏蔽条目，防止系统通过现代网络隧道进行 MDM 同步。

### 2. 源自多啦快解的逻辑
*   **FileVault 卷管理**：集成检测并解锁受 FileVault 保护的 APFS 卷的逻辑，确保可以正常访问系统配置路径。
*   **细精化服务抑制**：实现了针对 `cloudconfigurationd`、`ManagedClientAgent` 及其他管理进程的显式 `launchctl` 禁用与 `bootout` 指令。
*   **状态精准管理**：明确删除正向激活记录，防止系统仅凭文件存在即触发注册序列。

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

**6. 执行绕过**
选择选项 1，并按照提示创建管理员账户及应用技术修改。

**7. 完成操作**
看到“Bypass Completed Successfully”提示后，退出终端并重启 Mac。

---

## 安装后后续步骤

**8. 身份验证**
使用临时账户登录 (默认值: Apple / 1234)。

**9. 设置助手**
跳过所有初始提示 (Apple ID、Siri、Touch ID、定位服务)。

**10. 创建正式账户**
通过“系统设置”创建一个永久的管理员账户，并删除临时账户。

---

**免责声明**: 本工具仅供教育与研究使用。
