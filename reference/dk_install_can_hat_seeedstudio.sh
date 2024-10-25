#!/bin/bash

# Check if the script is run with sudo/root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Step 1: Open config.txt file and add the overlay if not already added
CONFIG_FILE="/boot/config.txt"
OVERLAY_LINE="dtoverlay=seeed-can-fd-hat-v2"

if grep -q "$OVERLAY_LINE" "$CONFIG_FILE"; then
    echo "CAN-FD HAT overlay is already present in $CONFIG_FILE"
else
    echo "Adding CAN-FD HAT overlay to $CONFIG_FILE"
    echo "$OVERLAY_LINE" >> "$CONFIG_FILE"
    echo "CAN-FD HAT overlay added."
fi

# Step 2: Reboot the system to apply changes
#echo "Rebooting the system to apply changes..."
#sudo reboot
