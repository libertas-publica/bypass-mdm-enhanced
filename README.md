# Bypass MDM Enhanced

[Chinese Version / 中文版](README-CN.md)

This project extends the original MDM bypass script by Assaf Dori. This enhanced version incorporates bypass and persistence logic derived from the analysis of the commercial tool micaixin.cn and scripts from the Dora Fast Solve (多啦快解) toolset on Xianyu.

---

## Technical Enhancements

This version implements the technical features identified through comprehensive binary and script analysis:

### 1. Logic Derived from micaixin.cn
*   **System Daemon Suppression**: Initializes the system flag `/var/db/.com.apple.mdmclient.daemon.forced_disable` to prevent the `mdmclient` process from initializing.
*   **Direct Configuration Modification**: Uses `PlistBuddy` to set `CloudConfigRecordFound`, `CloudConfigHasActivationRecord`, and `CloudConfigProfileInstalled` to `false` in the system database.
*   **Attribute Locking**: Applies the `uchg` (User Immutable) flag to bypass markers and Plist configurations to prevent automated restoration.
*   **IPv6 Connectivity Blocking**: Implements IPv6 (`::`) entries in the hosts file to block MDM synchronization via modern network tunnels.

### 2. Logic Derived from Dora Fast Solve (多啦快解)
*   **FileVault Volume Management**: Includes logic to detect and unlock APFS volumes protected by FileVault, ensuring accessibility to the system configuration paths.
*   **Granular Service Suppression**: Implements explicit `launchctl` disable and `bootout` commands for `cloudconfigurationd`, `ManagedClientAgent`, and other management daemons across system and user domains.
*   **Precise Activation State Management**: Explicitly removes positive activation records (`.cloudConfigRecordFound`, etc.) to prevent the system from triggering enrollment sequences based on file existence.

---

## Installation and Usage

Follow these procedures to bypass MDM enrollment during a fresh macOS installation:

**1. Shutdown**
Perform a hard shutdown of the Mac.

**2. Boot into Recovery Mode**
*   Apple Silicon: Hold the Power button until Startup Options appear.
*   Intel: Hold Command + R during the boot sequence.

**3. Network Activation**
Connect to a Wi-Fi network to ensure the Mac is activated.

**4. Terminal Initialization**
Select Utilities from the menu bar and open Terminal.

**5. Execution**
Run the following command:
```bash
curl -L https://raw.githubusercontent.com/rponeawa/bypass-mdm-enhanced/main/bypass-mdm-enhanced.sh -o bypass-mdm.sh && chmod +x ./bypass-mdm.sh && ./bypass-mdm.sh
```

**6. Volume Detection**
The script will identify the System and Data volumes automatically.

**7. Bypass Selection**
Select Option 1: "Bypass MDM from Recovery".

**8. Account Configuration**
Configure the temporary administrator account or utilize default values.

**9. Finalization**
Wait for the confirmation message: "Bypass Completed Successfully".

**10. Reboot**
Exit the Terminal and restart the Mac.

---

## Post-Installation Steps

**11. Authentication**
Login using the temporary account (Default: Apple / 1234).

**12. Setup Assistant**
Skip all introductory prompts (Apple ID, Siri, Touch ID, Location Services).

**13. Primary Account Creation**
Navigate to System Settings > Users and Groups and create a permanent administrator account.

**14. Account Migration**
Log out of the temporary account and log into the new primary account.

**15. System Cleanup**
Delete the temporary administrator account from System Settings.

---

## Troubleshooting

### Volume Detection Failure
Verify the device is in Recovery Mode and that a valid macOS installation exists on the target drive.

### Permission Denied
Ensure the script has execution permissions: `chmod +x bypass-mdm.sh`.

---

**Disclaimer**: This tool is for educational and research purposes only.
