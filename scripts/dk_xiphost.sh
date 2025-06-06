#!/bin/bash

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

# Function to get disk total and available size for a given path
update_disk_usage() {
    local path="${1:-/}"  # Default to root if no argument given

    # Get df output line for the path
    local df_output
    df_output=$(df -h "$path" | tail -1)

    # Extract total size (2nd column) and available size (4th column)
    local total_size available_size
    total_size=$(echo "$df_output" | awk '{print $2}')
    available_size=$(echo "$df_output" | awk '{print $4}')

    # echo "Disk usage for path: $path"
    # echo "  Total Size: $total_size"
    # echo "  Available Size: $available_size"

    /home/.dk/dk_swupdate/dk_kuksa_client.sh setValue Vehicle.AboutSystem.DiskCapacity "$total_size"
    /home/.dk/dk_swupdate/dk_kuksa_client.sh setValue Vehicle.AboutSystem.DiskAvailable "$available_size"
}

while true; do
    # Wait before the next check (e.g., 10 seconds)
    sleep 5

    ##########################################################################################
    ###############  Update Disk Capacity Information ########################################
    ##########################################################################################
    update_disk_usage "/"  # Check root


    ##########################################################################################
    ###############  Vehicle.SwUpdate.XipHost.UpdateTrigger ##################################
    ##########################################################################################
    # Use command substitution to capture the output of the child script.
    result=$(/home/.dk/dk_swupdate/dk_kuksa_client.sh getValue Vehicle.SwUpdate.XipHost.UpdateTrigger)
    # Capture the exit code from the child script.
    exit_code=$?
    # Print the output and the exit code.
    echo "XipHost.UpdateTrigger: The child script returned: '$result'"
    # Execute SW update if true
    if [ $exit_code -eq 0 ]; then
        echo "XipHost.UpdateTrigger: Child script succeeded."
        if [[ $result == *'true'* ]]; then

            ##########################################################################################
            ###############  Vehicle.SwUpdate.PatchUpdateTrigger #####################################
            ##########################################################################################
            # Use command substitution to capture the output of the child script.
            result_1=$(/home/.dk/dk_swupdate/dk_kuksa_client.sh getValue Vehicle.SwUpdate.PatchUpdateTrigger)
            # Capture the exit code from the child script.
            exit_code_1=$?
            # Print the output and the exit code.
            echo "PatchUpdateTrigger: The child script returned: '$result_1'"
            # Execute SW update if true
            if [ $exit_code_1 -eq 0 ]; then
                echo "PatchUpdateTrigger: Child script succeeded."
                if [[ $result_1 == *'true'* ]]; then
                    echo "PatchUpdateTrigger is true, executing update command..."
                    # Execute your update command here:
                    /home/.dk/dk_swupdate/dk_kuksa_client.sh setValue Vehicle.SwUpdate.XipHost.UpdateTrigger False
                    /home/.dk/dk_swupdate/dk_kuksa_client.sh setValue Vehicle.SwUpdate.XipHost.PercentageDone 100
                    echo "PatchUpdateTrigger: It is not allowed to update host in PatchUpdateTrigger.... So skip this xiphost update."
                    continue
                else
                    echo "PatchUpdateTrigger is false. Proceeding UpdateTrigger ..."
                fi
            else
                echo "PatchUpdateTrigger: Child script failed with exit code: $exit_code_1"
            fi

            ##########################################################################################
            ##############################  Updating xip host ########################################
            ##########################################################################################
            echo "XipHost.UpdateTrigger: UpdateTrigger is true, executing update command..."
            # Execute your update command here:
            /home/.dk/dk_swupdate/dk_kuksa_client.sh setValue Vehicle.SwUpdate.XipHost.UpdateTrigger False
            ret=$("$HOME_DIR/.dk/dk_swupdate/dk_installation/swpackage/xip/xiphost.sh")
            e_code=$?
            if [ $e_code -eq 0 ]; then
                /home/.dk/dk_swupdate/dk_kuksa_client.sh setValue Vehicle.SwUpdate.XipHost.PercentageDone 100
            else
                /home/.dk/dk_swupdate/dk_kuksa_client.sh setValue Vehicle.SwUpdate.Status 7
            fi
        else
            echo "UpdateTrigger: UpdateTrigger is false. Checking again..."
        fi
    else
        echo "UpdateTrigger: Child script failed with exit code: $exit_code"
    fi
done

echo "Exiting update check loop."
