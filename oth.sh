#!/bin/bash

# Function to display info messages
info() {
    echo -e "\e[32m$1\e[0m"
}

# Function to display warning messages
warning() {
    echo -e "\e[33m$1\e[0m"
}

# Function to display error messages
error() {
    echo -e "\e[31m$1\e[0m"
}

# Function to check if a domain is valid
check_domain() {
    if [[ "$1" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to display a progress message
progress() {
    echo -n -e "\e[34m$1...\e[0m"
}

# Prompt for license key and domain
read -p "Please enter your license key: " LICENSE_KEY
read -p "Please enter your domain: " DOMAIN

# Validate domain
if ! check_domain "$DOMAIN"; then
    error "Invalid domain format. Please enter a valid domain."
    exit 1
fi

PACKAGE_NAME="Wemx Client Theme"
RESOURCE_NAME="oth"
DOWNLOAD_API_URL="https://overtimehosting.shop/api/v1/licenses/public/download"
TARGET_DIR="/var/www/wemx"

# Display welcome message
info "
======================================
|||             oth.sh             |||
|||          By damo © 2024        |||
======================================
"

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    error "You are not logged in as a root user. It is recommended to run the script as root."
    exit 1
fi

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    error "The directory $TARGET_DIR does not exist. Please create it and try again."
    exit 1
fi

# Get the download URL
progress "Attempting to connect"
RESPONSE=$(curl -s -X POST $DOWNLOAD_API_URL \
    -H "Content-Type: application/json" \
    -d '{
    "license": "'"$LICENSE_KEY"'",
    "domain": "'"$DOMAIN"'",
    "packages": "'"ClientTheme"'",
    "resource_name": "'"othclienttheme"'"
}')

# Debugging: Print the raw response
echo "Raw response: $RESPONSE"

# Check if the response contains success
SUCCESS=$(echo $RESPONSE | jq -r .success)

if [ "$SUCCESS" != "true" ]; then
    error "Failed to get download URL: $(echo $RESPONSE | jq -r .message)"
    exit 1
fi

DOWNLOAD_URL=$(echo $RESPONSE | jq -r .download_url)
echo "Done."

# Download the ZIP file
progress "Downloading ZIP file"
ZIP_FILE="/tmp/${RESOURCE_NAME}.zip"
curl -L -o "$ZIP_FILE" "$DOWNLOAD_URL"

# Check if the file was downloaded
if [ ! -f "$ZIP_FILE" ]; then
    error "Failed to download the zip file."
    exit 1
fi
echo "Done."

# Extract the ZIP file
progress "Extracting ZIP file"
unzip -o "$ZIP_FILE" -d "$TARGET_DIR"
if [ $? -ne 0 ]; then
    error "Failed to extract the zip file."
    exit 1
fi
echo "Done."

# Cleanup
rm "$ZIP_FILE"

info "Installation of oth has been complete. Please check if there are any errors."
