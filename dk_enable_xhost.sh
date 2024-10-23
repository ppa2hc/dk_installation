#!/bin/bash

# Check if the script is run with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

# Get the username of the non-root user running sudo
USERNAME=$SUDO_USER

# Create systemd service file
SERVICE_PATH="/etc/systemd/system/dk-xhost-allow.service"
echo "Creating systemd service at $SERVICE_PATH"

cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=Allow local connections to X server
After=display-manager.service graphical.target

[Service]
Type=oneshot
ExecStart=/usr/bin/xhost +local:
User=$USERNAME
Environment=DISPLAY=:0

[Install]
WantedBy=default.target
EOF

# Reload systemd, enable and start the service
echo "Enabling and starting dk-xhost-allow.service"
systemctl daemon-reload
if ! systemctl enable dk-xhost-allow.service; then
    echo "Failed to enable dk-xhost-allow.service, but continuing with the rest of the script."
fi

if ! systemctl start dk-xhost-allow.service; then
    echo "Failed to start dk-xhost-allow.service, but continuing with the rest of the script."
fi

# Function to create xhost-allow.sh script
create_xhost_script() {
    echo "Creating /home/$USERNAME/xhost-allow.sh script..."
    cat <<EOF > /home/$USERNAME/xhost-allow.sh
#!/bin/bash
# Allow local connections to X server
DISPLAY=:0
export DISPLAY
xhost +local:
EOF
    chmod +x /home/$USERNAME/xhost-allow.sh
    chown $USERNAME:$USERNAME /home/$USERNAME/xhost-allow.sh
    echo "xhost-allow.sh script created and made executable."
}

# Function to add the script to autostart using a .desktop file
create_autostart_entry() {
    echo "Creating autostart .desktop entry..."
    mkdir -p /home/$USERNAME/.config/autostart
    cat <<EOF > /home/$USERNAME/.config/autostart/xhost-allow.desktop
[Desktop Entry]
Type=Application
Exec=/home/$USERNAME/xhost-allow.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=Xhost Allow
Name=Xhost Allow
Comment[en_US]=Allow local X server connections
Comment=Allow local X server connections
EOF
    chown $USERNAME:$USERNAME /home/$USERNAME/.config/autostart/xhost-allow.desktop
    echo "Autostart .desktop entry created."
}

# Check if the OS is Ubuntu 24.x
OS_VERSION=$(lsb_release -rs)
if [[ "$OS_VERSION" == 24.* ]]; then
    echo "below script only runs on Ubuntu 24.x. Detected version: $OS_VERSION."

    # Proceed with creating the xhost-allow.sh script
    create_xhost_script

    # Proceed with creating the autostart entry to run the script on desktop startup
    create_autostart_entry
fi

echo "Setup completed xhost. Please reboot to apply the changes."
