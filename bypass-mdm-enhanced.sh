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

# Validation function for username
validate_username() {
	local username="$1"
	if [ -z "$username" ]; then
		echo "Username cannot be empty"
		return 1
	fi
	if [ ${#username} -gt 31 ]; then
		echo "Username too long (max 31 characters)"
		return 1
	fi
	if ! [[ "$username" =~ ^[a-zA-Z0-9_-]+$ ]]; then
		echo "Username can only contain letters, numbers, underscore, and hyphen"
		return 1
	fi
	if ! [[ "$username" =~ ^[a-zA-Z_] ]]; then
		echo "Username must start with a letter or underscore"
		return 1
	fi
	return 0
}

# Validation function for password
validate_password() {
	local password="$1"
	if [ -z "$password" ]; then
		echo "Password cannot be empty"
		return 1
	fi
	if [ ${#password} -lt 4 ]; then
		echo "Password too short (minimum 4 characters recommended)"
		return 1
	fi
	return 0
}

# Check if user already exists
check_user_exists() {
	local dscl_path="$1"
	local username="$2"
	if dscl -f "$dscl_path" localhost -read "/Local/Default/Users/$username" 2>/dev/null; then
		return 0 # User exists
	else
		return 1 # User doesn't exist
	fi
}

# Find available UID
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
	return 1
}

# Function to detect system volumes with multiple fallback strategies (Restored Original)
detect_volumes() {
	local system_vol=""
	local data_vol=""

	info "Detecting system volumes..." >&2

	# Strategy 1: Look for common macOS APFS volume patterns
	for vol in /Volumes/*; do
		if [ -d "$vol" ]; then
			vol_name=$(basename "$vol")
			if [[ ! "$vol_name" =~ "Data"$ ]] && [[ ! "$vol_name" =~ "Recovery" ]] && [ -d "$vol/System" ]; then
				system_vol="$vol_name"
				info "Found system volume: $system_vol" >&2
				break
			fi
		fi
	done

	# Strategy 2: Fallback
	if [ -z "$system_vol" ]; then
		for vol in /Volumes/*; do
			if [ -d "$vol/System" ]; then
				system_vol=$(basename "$vol")
				warn "Using volume with /System directory: $system_vol" >&2
				break
			fi
		done
	fi

	# Strategy 3: Data volume detection
	if [ -d "/Volumes/Data" ]; then
		data_vol="Data"
		info "Found data volume: $data_vol" >&2
	elif [ -n "$system_vol" ] && [ -d "/Volumes/$system_vol - Data" ]; then
		data_vol="$system_vol - Data"
		info "Found data volume: $data_vol" >&2
	else
		for vol in /Volumes/*Data; do
			if [ -d "$vol" ]; then
				data_vol=$(basename "$vol")
				warn "Found data volume: $data_vol" >&2
				break
			fi
		done
	fi

	if [ -z "$system_vol" ] || [ -z "$data_vol" ]; then
		error_exit "Could not detect system or data volume. Ensure you are in Recovery mode."
	fi

	echo "$system_vol|$data_vol"
}

# Detect volumes at startup
volume_info=$(detect_volumes)
system_volume=$(echo "$volume_info" | cut -d'|' -f1)
data_volume=$(echo "$volume_info" | cut -d'|' -f2)

# Display header
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║             MDM Bypass Enhanced               ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════╝${NC}"
echo ""
success "System Volume: $system_volume"
success "Data Volume: $data_volume"
echo ""

# Prompt user for choice
PS3='Please enter your choice: '
options=("Bypass MDM from Recovery" "Reboot & Exit")
select opt in "${options[@]}"; do
	case $opt in
	"Bypass MDM from Recovery")
		echo ""
		echo -e "${YEL}═══════════════════════════════════════${NC}"
		echo -e "${YEL}  Starting MDM Bypass Process${NC}"
		echo -e "${YEL}═══════════════════════════════════════${NC}"
		echo ""

		# FileVault Check (Integrated from decryption research)
		if ! diskutil mount "$data_volume" 2>/dev/null; then
			warn "Data volume is locked (FileVault). Please enter your login password to unlock."
			diskutil apfs unlockVolume "$data_volume" || error_exit "Failed to unlock Data volume."
		fi

		# Normalize data volume name if needed
		if [ "$data_volume" != "Data" ]; then
			info "Renaming data volume to 'Data' for consistency..."
			if diskutil rename "$data_volume" "Data" 2>/dev/null; then
				success "Data volume renamed successfully"
				data_volume="Data"
			else
				warn "Could not rename data volume, continuing with: $data_volume"
			fi
		fi

		# Validate critical paths
		info "Validating system paths..."
		system_path="/Volumes/$system_volume"
		data_path="/Volumes/$data_volume"
		dscl_path="$data_path/private/var/db/dslocal/nodes/Default"

		if [ ! -d "$system_path" ] || [ ! -d "$data_path" ] || [ ! -d "$dscl_path" ]; then
			error_exit "System paths validation failed."
		fi
		success "All system paths validated"
		echo ""

		# Create Temporary User (Restored Original interactive logic)
		echo -e "${CYAN}Creating Temporary Admin User${NC}"
		echo -e "${NC}Press Enter to use defaults (recommended)${NC}"

		read -p "Enter Temporary Fullname (Default is 'Apple'): " realName
		realName="${realName:=Apple}"

		while true; do
			read -p "Enter Temporary Username (Default is 'Apple'): " username
			username="${username:=Apple}"
			if validation_msg=$(validate_username "$username"); then
				break
			else
				warn "$validation_msg"
			fi
		done

		if check_user_exists "$dscl_path" "$username"; then
			warn "User '$username' already exists."
			read -p "Use a different username? (y/n): " response
			if [[ "$response" =~ ^[Yy]$ ]]; then
				while true; do
					read -p "Enter a different username: " username
					validate_username "$username" && ! check_user_exists "$dscl_path" "$username" && break
				done
			fi
		fi

		while true; do
			read -p "Enter Temporary Password (Default is '1234'): " passw
			passw="${passw:=1234}"
			if validation_msg=$(validate_password "$passw"); then
				break
			else
				warn "$validation_msg"
			fi
		done

		# User Creation (Restored Original detail)
		available_uid=$(find_available_uid "$dscl_path")
		info "Creating user account: $username (UID: $available_uid)"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" || error_exit "Failed to create user account"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UserShell "/bin/zsh"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" RealName "$realName"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" UniqueID "$available_uid"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" PrimaryGroupID "20"
		mkdir -p "$data_path/Users/$username"
		dscl -f "$dscl_path" localhost -create "/Local/Default/Users/$username" NFSHomeDirectory "/Users/$username"
		dscl -f "$dscl_path" localhost -passwd "/Local/Default/Users/$username" "$passw"
		dscl -f "$dscl_path" localhost -append "/Local/Default/Groups/admin" GroupMembership "$username"
		
		touch "$data_path/private/var/db/.AppleSetupDone"
		success "User account created successfully"
		echo ""

		# Block MDM domains (Enhanced with IPv6 and full list)
		info "Blocking MDM enrollment domains..."
		hosts_file="$system_path/etc/hosts"
		domains=("deviceenrollment.apple.com" "mdmenrollment.apple.com" "iprofiles.apple.com" "gdmf.apple.com" "acmdm.apple.com" "albert.apple.com")
		for domain in "${domains[@]}"; do
			grep -q "0.0.0.0 $domain" "$hosts_file" 2>/dev/null || echo "0.0.0.0 $domain" >>"$hosts_file"
			grep -q ":: $domain" "$hosts_file" 2>/dev/null || echo ":: $domain" >>"$hosts_file"
		done
		chflags uchg "$hosts_file" 2>/dev/null
		success "MDM domains blocked and hosts file locked"
		echo ""

		# Configuration Modifications (Enhanced Logic)
		info "Configuring MDM bypass settings..."
		config_path="$system_path/var/db/ConfigurationProfiles/Settings"
		mkdir -p "$config_path" 2>/dev/null

		# Remove positive activation records
		rm -rf "$config_path"/.cloudConfigHasActivationRecord 2>/dev/null
		rm -rf "$config_path"/.cloudConfigRecordFound 2>/dev/null

		# Create and lock negative markers
		markers=(
			".cloudConfigProfileInstalled"
			".cloudConfigRecordNotFound"
			".cloudConfigNoActivationRecord"
			".cloudConfigUserSkippedEnrollment"
			".CloudConfigDelete"
		)
		for marker in "${markers[@]}"; do
			chflags nouchg "$config_path/$marker" 2>/dev/null
			touch "$config_path/$marker" 2>/dev/null
			chflags uchg "$config_path/$marker" 2>/dev/null
		done

		# Force Disable Flag
		disable_flag="$system_path/var/db/.com.apple.mdmclient.daemon.forced_disable"
		chflags nouchg "$disable_flag" 2>/dev/null
		touch "$disable_flag" 2>/dev/null
		chflags uchg "$disable_flag" 2>/dev/null

		# Direct Plist Modification
		managed_client_plist="$config_path/com.apple.ManagedClient.plist"
		[ ! -f "$managed_client_plist" ] && echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict></dict></plist>' > "$managed_client_plist"
		for key in "CloudConfigRecordFound" "CloudConfigHasActivationRecord" "CloudConfigProfileInstalled"; do
			/usr/libexec/PlistBuddy -c "Set :$key false" "$managed_client_plist" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :$key bool false" "$managed_client_plist"
		done
		chflags uchg "$managed_client_plist" 2>/dev/null
		success "Configuration markers and Plist modifications applied"

		# Service Disablement (Integrated from additional service research)
		info "Disabling MDM service agents..."
		USER_IDS=$(dscl -f "$dscl_path" localhost -list /Local/Default/Users UniqueID 2>/dev/null | awk '$2>=501 {print $2}')
		for USER_ID in $USER_IDS; do
			launchctl disable "gui/${USER_ID}/com.apple.ManagedClientAgent.enrollagent" 2>/dev/null || true
			launchctl bootout  "gui/${USER_ID}/com.apple.ManagedClientAgent.enrollagent" 2>/dev/null || true
			launchctl disable "user/${USER_ID}/com.apple.ManagedClientAgent.enrollagent" 2>/dev/null || true
			launchctl bootout  "user/${USER_ID}/com.apple.ManagedClientAgent.enrollagent" 2>/dev/null || true
		done
		services=("com.apple.ManagedClient.cloudconfigurationd" "com.apple.ManagedClient.daemon" "com.apple.ManagedClient.enroll")
		for service in "${services[@]}"; do
			launchctl disable "system/$service" 2>/dev/null || true
			launchctl bootout  "system/$service" 2>/dev/null || true
		done
		success "All MDM services suppressed"

		echo ""
		echo -e "${GRN}╔═══════════════════════════════════════════════╗${NC}"
		echo -e "${GRN}║       MDM Bypass Completed Successfully!     ║${NC}"
		echo -e "${GRN}╚═══════════════════════════════════════════════╝${NC}"
		echo ""
		echo -e "${CYAN}Next steps:${NC}"
		echo -e "  1. Close this terminal window"
		echo -e "  2. Reboot your Mac"
		echo -e "  3. Login with username: ${YEL}$username${NC} and password: ${YEL}$passw${NC}"
		echo ""
		break
		;;
	"Reboot & Exit")
		echo ""
		info "Rebooting system..."
		reboot
		break
		;;
	*)
		echo -e "${RED}Invalid option $REPLY${NC}"
		;;
	esac
done
