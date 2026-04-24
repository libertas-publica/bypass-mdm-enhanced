# Bypass MDM Enhanced

[Chinese Version / 中文版](README-CN.md)

This project extends the original MDM bypass script by Assaf Dori. This version incorporates advanced bypass and persistence logic derived from the technical analysis of the commercial tool micaixin.cn and scripts from the Dora Fast Solve (多啦快解) script.

---

## Technical Enhancements

This enhanced version implements the following specialized features identified through binary and script analysis:

### 1. Logic Derived from micaixin.cn
*   **System Daemon Suppression**: Initializes the system flag `/var/db/.com.apple.mdmclient.daemon.forced_disable`. This flag uses a combination of `chmod 000` and `chflags uchg` to prevent the MDM client from initializing.
*   **Byte-level Plist Modification**: Uses `PlistBuddy` to set `CloudConfigRecordFound`, `CloudConfigHasActivationRecord`, and `CloudConfigProfileInstalled` to `false` in the core configuration database.
*   **Vendor Component Purge**: Scans and deletes LaunchDaemons and LaunchAgents associated with third-party MDM vendors such as Jamf, Addigy, Kandji, and others.
*   **Network Config Reset**: Removes system-level network and Wi-Fi configuration Plist files to break existing managed network profiles.
*   **IPv6 Connectivity Blocking**: Prevents MDM synchronization via modern network tunnels by applying IPv6 (`::`) entries in the hosts file.

### 2. Logic Derived from Dora Fast Solve (多啦快解)
*   **FileVault Decryption**: Detects and provides a workflow to unlock APFS volumes protected by FileVault, ensuring accessibility to the system partition.
*   **Granular Service Suppression**: Implements explicit `launchctl` disable and `bootout` commands for `cloudconfigurationd`, `ManagedClientAgent`, and other management daemons.
*   **Activation Record Management**: Explicitly removes positive cloud configuration records to prevent enrollment triggers based on file existence.

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
curl -L https://raw.githubusercontent.com/libertas-publica/bypass-mdm-enhanced/refs/heads/main/bypass-mdm-enhanced.sh -o bypass-mdm.sh && chmod +x ./bypass-mdm.sh && ./bypass-mdm.sh
```

**6. Bypass Procedure**
Select Option 1 and follow the prompts to create an administrator account and apply technical modifications.

**7. Finalization**
Once the "Bypass Completed Successfully" message appears, exit the Terminal and restart the Mac.

---

## Post-Installation Steps

**8. Authentication**
Login using the temporary account (Default: Apple / 1234).

**9. Setup Assistant**
Skip all introductory prompts (Apple ID, Siri, Touch ID, Location Services).

**10. Primary Account Creation**
Create a permanent administrator account via System Settings and delete the temporary account.

---

**Disclaimer**: This tool is for educational and research purposes only.
