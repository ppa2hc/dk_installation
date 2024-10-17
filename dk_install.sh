#!/bin/bash

# Determine the user who ran the command
if [ -n "$SUDO_USER" ]; then
    # Command was run with sudo
    DK_USER=$SUDO_USER
else
    # Command was not run with sudo, fall back to current user
    DK_USER=$USER
fi

# Get the current directory path
CURRENT_DIR=$(pwd)

# Add current user to sudo group of docker
# Check if the docker group exists
if getent group docker > /dev/null 2>&1; then
    echo "Docker: Docker group exists, proceeding..."
else
    echo "Docker: Docker group does not exist. Creating docker group..."
    sudo groupadd docker
fi
# Add the user to the docker group
if sudo usermod -aG docker "$DK_USER"; then
    echo "Docker: User '$DK_USER' has been added to the docker group."
else
    echo "Docker: Failed to add user '$DK_USER' to the docker group."
    exit 1
fi
# Inform the user that they need to log out and back in for the changes to take effect
echo "Docker: Please log out and log back in for the group changes to take effect."

# Detect the system architecture
ARCH_DETECT=$(uname -m)
# Set ARCH variable based on the detected architecture
if [[ "$ARCH_DETECT" == "x86_64" ]]; then
    ARCH="amd64"
elif [[ "$ARCH_DETECT" == "aarch64" ]]; then
    ARCH="arm64"
else
    ARCH="unknown"
fi

# Set Env Variables
HOME_DIR="/home/$DK_USER"
DOCKER_SHARE_PARAM="-v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker"
DOCKER_AUDIO_PARAM="--device /dev/snd --group-add audio -e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native -v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native -v $HOME_DIR/.config/pulse/cookie:/root/.config/pulse/cookie"
LOG_LIMIT_PARAM="--log-opt max-size=10m --log-opt max-file=3"
DOCKER_HUB_NAMESPACE="phongbosch"

echo "Env Variables:"
echo "DK_USER: $DK_USER"
echo "ARCH: $ARCH"
echo "HOME_DIR: $HOME_DIR"
echo "DOCKER_SHARE_PARAM: $DOCKER_SHARE_PARAM"
echo "DOCKER_AUDIO_PARAM: $DOCKER_AUDIO_PARAM"
echo "LOG_LIMIT_PARAM: $LOG_LIMIT_PARAM"
echo "DOCKER_HUB_NAMESPACE: $DOCKER_HUB_NAMESPACE"

echo "Create dk directoties ..."
mkdir -p /home/$DK_USER/.dk/dk_manager/ /home/$DK_USER/.dk/dk_vssgeneration
cd /home/$DK_USER/.dk

echo "Create dk_network ..."
docker network create dk_network

echo "Install installation repo"
DK_INSTALLATION_DIR="$HOME_DIR/.dk/dk_installation"
if [ ! -d "$DK_INSTALLATION_DIR" ]; then
    # Folder does not exist, do something
    echo "Folder $DK_INSTALLATION_DIR does not exist. Downloading ..."
    git clone https://github.com/ppa2hc/dk_installation.git
else
    echo "Folder $DK_INSTALLATION_DIR already exists."
fi

echo "Install APP SDK"
APP_SDK_DIR="$HOME_DIR/.dk/dk_app_python_template"
if [ ! -d "$APP_SDK_DIR" ]; then
    # Folder does not exist, do something
    echo "Folder $APP_SDK_DIR does not exist. Downloading ..."
    git clone https://github.com/ppa2hc/dk_app_python_template.git
else
    echo "Folder $APP_SDK_DIR already exists."
fi

echo "Install base image for velocitas app ..."
docker pull $DOCKER_HUB_NAMESPACE/dk_app_python_template:baseimage

echo "Install dk_manager ..."
docker pull $DOCKER_HUB_NAMESPACE/dk_manager:latest
docker stop dk_manager; docker rm dk_manager; docker run -d -it --name dk_manager $LOG_LIMIT_PARAM $DOCKER_SHARE_PARAM  -v $HOME_DIR/.dk:/app/.dk --restart unless-stopped -e USER=$DK_USER -e DOCKER_HUB_NAMESPACE=$DOCKER_HUB_NAMESPACE -e ARCH=$ARCH $DOCKER_HUB_NAMESPACE/dk_manager:latest

echo "Install vss_generation ..."
docker pull $DOCKER_HUB_NAMESPACE/dk_vssgeneration_image:vss4.0
docker rm vssgen;docker run -it --name vssgen -v $HOME_DIR/.dk/dk_vssgeneration/:/app/dk_vssgeneration -v $HOME_DIR/.dk/dk_manager/vssmapping/vssmapping_overlay.vspec:/app/.dk/dk_manager/vssmapping/vssmapping_overlay.vspec:ro $LOG_LIMIT_PARAM $DOCKER_HUB_NAMESPACE/dk_vssgeneration_image:vss4.0

echo "Install vehicle data broker ... "
docker pull ghcr.io/eclipse-kuksa/kuksa-databroker:0.4.4
docker stop vehicledatabroker ; docker rm vehicledatabroker ; docker run -d -it --name vehicledatabroker -e KUKSA_DATA_BROKER_METADATA_FILE=/app/.dk/dk_vssgeneration/vss.json -e KUKSA_DATA_BROKER_PORT=55555 -e 50001 -e 3500 -v $HOME_DIR/.dk/dk_vssgeneration/vss.json:/app/.dk/dk_vssgeneration/vss.json --restart unless-stopped --network dk_network -p 55555:55555 $LOG_LIMIT_PARAM ghcr.io/eclipse-kuksa/kuksa-databroker:0.4.4 --insecure --vss /app/.dk/dk_vssgeneration/vss.json

echo "Install App/service installation service ... "
docker pull $DOCKER_HUB_NAMESPACE/dk_appinstallservice:latest

# Install dk_ivi
dk_ivi_value=""
# Loop through all input arguments
for arg in "$@"; do
    # Check if the argument starts with dk_ivi=
    if [[ "$arg" == dk_ivi=* ]]; then
        # Extract the value after the equal sign
        dk_ivi_value="${arg#*=}"
    fi
done

if [[ "$dk_ivi_value" == "true" ]]; then
    echo "enable xhost local"
	$CURRENT_DIR/dk_enable_xhost.sh
    echo "Instal dk_ivi ..."
	docker stop dk_ivi; docker rm dk_ivi ; docker run -d -it --name dk_ivi -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=:0 --device /dev/dri:/dev/dri --restart unless-stopped $LOG_LIMIT_PARAM $DOCKER_SHARE_PARAM -v $HOME_DIR/.dk/dk_manager/prototypes:/app/.dk/dk_manager/prototypes $DOCKER_HUB_NAMESPACE/dk_ivi:latest
    # Add your actions here
else
    echo "To Install dk_ivi, run './dk_install dk_ivi=true'"
fi

echo "To Install dreamKIT services, run './dk_install_services dk_services_[name]=true'"
echo "[name]: tts, coffee"
echo "e.g., ./dk_install_services dk_services_tts=true"

echo "------------------------------------------------------------------"
echo "Please reboot your system for dreamSW to take effect !!!!!!!!!!!!!"
echo "------------------------------------------------------------------"
