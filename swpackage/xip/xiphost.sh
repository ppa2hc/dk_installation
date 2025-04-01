#!/bin/bash

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Start dreamOS SW Update  !!!!!!!!!!!!!"
echo "------------------------------------------------------------------------------------------------------------------------------------"

# source the installation env
source /home/.dk/dk_swupdate/dk_swupdate_env.sh

echo "Env Variables:"
echo "DK_USER: $DK_USER"
echo "ARCH: $ARCH"
echo "HOME_DIR: $HOME_DIR"
echo "DOCKER_SHARE_PARAM: $DOCKER_SHARE_PARAM"
echo "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
echo "DOCKER_AUDIO_PARAM: $DOCKER_AUDIO_PARAM"
echo "LOG_LIMIT_PARAM: $LOG_LIMIT_PARAM"
echo "DOCKER_HUB_NAMESPACE: $DOCKER_HUB_NAMESPACE"
echo "dk_ara_demo: $dk_ara_demo"
echo "dk_ivi_value: $dk_ivi_value"

echo "Create dk directoties ..."
mkdir -p /home/$DK_USER/.dk/dk_manager/vssmapping /home/$DK_USER/.dk/dk_vssgeneration
cd /home/$DK_USER/.dk

echo "Create dk_network ..."
docker network create dk_network

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Install required utils"
echo "Installing git ..."
# Check if git is available
if command -v git >/dev/null 2>&1; then
    echo "Git is already installed."
else
    echo "Git is not installed. Installing using apt-get..."

    # Update package lists
    apt-get update

    # Install git without prompting for confirmation
    apt-get install -y git

    # Verify installation
    if command -v git >/dev/null 2>&1; then
        echo "Git has been installed successfully."
    else
        echo "There was an error installing Git."
        exit 1
    fi
fi

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Install installation repo"
DK_INSTALLATION_DIR="$HOME_DIR/.dk/dk_installation"
if [ ! -d "$DK_INSTALLATION_DIR" ]; then
    # Folder does not exist, do something
    echo "Folder $DK_INSTALLATION_DIR does not exist. Downloading ..."
    git clone https://github.com/ppa2hc/dk_installation.git
else
    echo "Folder $DK_INSTALLATION_DIR already exists."
fi

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Install APP Python SDK"
APP_PY_SDK_DIR="$HOME_DIR/.dk/dk_app_python_template"
if [ ! -d "$APP_PY_SDK_DIR" ]; then
    # Folder does not exist, do something
    echo "Folder $APP_PY_SDK_DIR does not exist. Downloading ..."
    git clone https://github.com/ppa2hc/dk_app_python_template.git
else
    echo "Folder $APP_PY_SDK_DIR already exists."
fi

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Install base image for velocitas py app ..."
docker pull $DOCKER_HUB_NAMESPACE/dk_app_python_template:baseimage

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Install dk_manager ..."
docker pull $DOCKER_HUB_NAMESPACE/dk_manager:latest
docker stop dk_manager; docker rm dk_manager; docker run -d -it --name dk_manager $LOG_LIMIT_PARAM $DOCKER_SHARE_PARAM  -v $HOME_DIR/.dk:/app/.dk --restart unless-stopped -e USER=$DK_USER -e DOCKER_HUB_NAMESPACE=$DOCKER_HUB_NAMESPACE -e ARCH=$ARCH $DOCKER_HUB_NAMESPACE/dk_manager:latest

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Install vss_generation ..."
docker pull $DOCKER_HUB_NAMESPACE/dk_vssgeneration_image:vss4.0
docker rm vssgen;docker run -it --name vssgen -v $HOME_DIR/.dk/dk_vssgeneration/:/app/dk_vssgeneration -v $HOME_DIR/.dk/dk_manager/vssmapping/vssmapping_overlay.vspec:/app/.dk/dk_manager/vssmapping/vssmapping_overlay.vspec:ro $LOG_LIMIT_PARAM $DOCKER_HUB_NAMESPACE/dk_vssgeneration_image:vss4.0

echo "Install vss_generation for dksystem..."
docker rm dksystem_vssgen;docker run -it --name dksystem_vssgen -v $HOME_DIR/.dk/dk_vssgeneration/:/app/dk_vssgeneration -v $HOME_DIR/.dk/dk_manager/vssmapping/dksystem_vssmapping_overlay.vspec:/app/.dk/dk_manager/vssmapping/vssmapping_overlay.vspec:ro $LOG_LIMIT_PARAM -e VSS_NAME=dksystem_vss.json -e VEHICLE_GEN=dksystem_vehicle_gen $DOCKER_HUB_NAMESPACE/dk_vssgeneration_image:vss4.0

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Install vehicle data broker ... "
docker pull ghcr.io/eclipse-kuksa/kuksa-databroker:0.4.4
docker stop vehicledatabroker ; docker rm vehicledatabroker ; docker run -d -it --name vehicledatabroker -e KUKSA_DATA_BROKER_METADATA_FILE=/app/.dk/dk_vssgeneration/vss.json -e KUKSA_DATA_BROKER_PORT=55555 -e 50001 -e 3500 -v $HOME_DIR/.dk/dk_vssgeneration/vss.json:/app/.dk/dk_vssgeneration/vss.json --restart unless-stopped --network dk_network -p 55555:55555 $LOG_LIMIT_PARAM ghcr.io/eclipse-kuksa/kuksa-databroker:0.4.4 --insecure --vss /app/.dk/dk_vssgeneration/vss.json

echo "Install dksystem vehicle data broker ... "
docker pull ghcr.io/eclipse-kuksa/kuksa-databroker:0.4.4
docker stop dksystem_vehicledatabroker ; docker rm dksystem_vehicledatabroker ; docker run -d -it --name dksystem_vehicledatabroker -e KUKSA_DATA_BROKER_METADATA_FILE=/app/.dk/dk_vssgeneration/vss.json -e KUKSA_DATA_BROKER_PORT=55555 -e 50001 -e 3500 -v $HOME_DIR/.dk/dk_vssgeneration/dksystem_vss.json:/app/.dk/dk_vssgeneration/vss.json --restart unless-stopped --network dk_network -p 55569:55555 $LOG_LIMIT_PARAM ghcr.io/eclipse-kuksa/kuksa-databroker:0.4.4 --insecure --vss /app/.dk/dk_vssgeneration/vss.json

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
# Install dk_ara_demo
if [[ "$dk_ara_demo" == "true" ]]; then
    echo "Install APP CPP SDK"
    APP_CPP_SDK_DIR="$HOME_DIR/.dk/dk_app_cpp_template"
    if [ ! -d "$APP_CPP_SDK_DIR" ]; then
        # Folder does not exist, do something
        echo "Folder $APP_CPP_SDK_DIR does not exist. Downloading ..."
        git clone https://github.com/ppa2hc/dk_app_cpp_template.git
    else
        echo "Folder $APP_CPP_SDK_DIR already exists."
    fi

    echo "Install base image for adaptive AR cpp app ..."
    docker pull $DOCKER_HUB_NAMESPACE/dk_app_cpp_template:latest

    echo "Install kuksa.val for vss ara::provider demo"
    docker pull ghcr.io/eclipse/kuksa.val/kuksa-val:0.2.5
    docker stop kuksa_val_server ; docker rm kuksa_val_server ; docker run -d --name kuksa_val_server --restart unless-stopped -it -p 50051:50051 -p 8090:8090 $LOG_LIMIT_PARAM -e LOG_LEVEL=ALL -e KUKSAVAL_OPTARGS="--insecure" ghcr.io/eclipse/kuksa.val/kuksa-val:0.2.5
fi

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Install App/service installation service ... "
docker pull $DOCKER_HUB_NAMESPACE/dk_appinstallservice:latest

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Install OS SW Update service ... "
docker pull ghcr.io/eclipse/kuksa.val/kuksa-client:0.4.2

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
# Install dk_ivi
if [[ "$dk_ivi_value" == "true" ]]; then
    echo "Instal dk_ivi ..."
    docker pull $DOCKER_HUB_NAMESPACE/dk_ivi:latest

    echo "Checking for NVIDIA Target Board..."
    if [ -f "/etc/nv_tegra_release" ]; then
        echo "NVIDIA Jetson board detected."
        docker stop dk_ivi; docker rm dk_ivi ; docker run -d -it --name dk_ivi -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=:0 -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR -e QT_QUICK_BACKEND=software --restart unless-stopped $LOG_LIMIT_PARAM $DOCKER_SHARE_PARAM -v $HOME_DIR/.dk:/app/.dk -e DKCODE=dreamKIT -e DK_USER=$DK_USER -e DK_DOCKER_HUB_NAMESPACE=$DOCKER_HUB_NAMESPACE -e DK_ARCH=$ARCH -e DK_CONTAINER_ROOT="/app/.dk/" $DOCKER_HUB_NAMESPACE/dk_ivi:latest
    else
        echo "Not NVIDIA board."
        docker stop dk_ivi; docker rm dk_ivi ; docker run -d -it --name dk_ivi -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY=:0 -e XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR --device /dev/dri:/dev/dri --restart unless-stopped $LOG_LIMIT_PARAM $DOCKER_SHARE_PARAM -v $HOME_DIR/.dk:/app/.dk -e DKCODE=dreamKIT -e DK_USER=$DK_USER -e DK_DOCKER_HUB_NAMESPACE=$DOCKER_HUB_NAMESPACE -e DK_ARCH=$ARCH -e DK_CONTAINER_ROOT="/app/.dk/" $DOCKER_HUB_NAMESPACE/dk_ivi:latest
    fi
else
    echo "To Install dk_ivi, run './dk_install dk_ivi=true'"
fi

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Remove Only Dangling Images (No Tags)"
docker image prune -f

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------------------"

echo "------------------------------------------------------------------------------------------------------------------------------------"
echo "Please reboot your system for dreamSW to take effect !!!!!!!!!!!!!"
echo "------------------------------------------------------------------------------------------------------------------------------------"
