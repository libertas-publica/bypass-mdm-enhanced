# Bypass MDM Enhanced

[中文](README-CN.md)

This project extends the original MDM bypass script by Assaf Dori. This enhanced version, developed by rponeawa, incorporates core bypass and persistence logic derived from the reverse engineering of the commercial tool micaixin.cn.

---

## Technical Enhancements (Reverse-engineered from micaixin.cn)

This version implements the following technical features identified through binary analysis:

1.  **Network Domain Redirection (IPv4 and IPv6)**
    *   Includes additional Apple MDM endpoints: `gdmf.apple.com`, `acmdm.apple.com`, and `albert.apple.com`.
    *   Applies entries for both IPv4 (0.0.0.0) and IPv6 (::) in the system hosts file to prevent connection attempts via IPv6 tunnels.

2.  **System Daemon Suppression**
    *   Initializes the system flag: `/var/db/.com.apple.mdmclient.daemon.forced_disable`.
    *   The `mdmclient` daemon checks for this flag during its initialization sequence. If detected, the process terminates, preventing background MDM synchronization regardless of network configuration.

3.  **Direct Configuration Profile Modification**
    *   Utilizes `PlistBuddy` to modify `/var/db/ConfigurationProfiles/Settings/com.apple.ManagedClient.plist`.
    *   Explicitly sets the following Boolean keys to `false`: `CloudConfigRecordFound`, `CloudConfigHasActivationRecord`, and `CloudConfigProfileInstalled`.

4.  **File System Attribute Locking**
    *   Applies the `uchg` (User Immutable) flag to all modified configuration files and markers using `chflags`.
    *   This ensures that the macOS kernel cannot overwrite or delete the bypass configuration during system updates or automated maintenance.

5.  **State Masking Markers**
    *   Deploys specific markers including `.CloudConfigDelete` and `.cloudConfigUserSkippedEnrollment`.
    *   These markers instruct the system setup process to bypass the remote management enrollment sequence.

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
Configure the temporary administrator account or utilize the default values.

**9. Finalization**
Wait for the confirmation message: "MDM Bypass Completed Successfully".

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
Ensure the script has execution permissions: `chmod +x bypass-mdm-enhanced.sh`.

---

**Disclaimer**: This tool is for educational and research purposes.
