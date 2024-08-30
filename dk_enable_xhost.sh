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
#ExecStartPre=/bin/sleep 2  # Optional: delay start if needed for desktop readiness

[Install]
WantedBy=default.target
EOF

# Reload systemd, enable and start the service
echo "Enabling and starting xhost-allow.service"
systemctl daemon-reload
systemctl enable dk-xhost-allow.service
systemctl start dk-xhost-allow.service

echo "xhost +local: setup complete."
