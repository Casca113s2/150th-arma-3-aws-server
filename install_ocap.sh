#!/bin/bash

# Define mount point
mount_point="/mnt/ebs_volume"

# Get EC2 public IP
ec2_ip=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
if [ -z "$ec2_ip" ]; then
    echo "Failed to retrieve EC2 public IP"
    exit 1
fi
echo "EC2 public IP: $ec2_ip"

# Clone addons repository
cd ~ || {
    echo "Failed to navigate to home directory"
    exit 1
}

if [ ! -d "addon" ]; then
    git clone https://github.com/OCAP2/addon.git
    if [ $? -ne 0 ]; then
        echo "Failed to clone addon repository"
        exit 1
    fi
else
    echo "addon directory already exists"
fi

# Clone web repository
if [ ! -d "web" ]; then
    git clone https://github.com/OCAP2/web.git
    if [ $? -ne 0 ]; then
        echo "Failed to clone web repository"
        exit 1
    fi
else
    echo "web directory already exists"
fi

# Ensure necessary directories exist for web and addon
if [ ! -d "$mount_point/steam/web" ]; then
    mkdir -p "$mount_point/steam/web"
    if [ $? -ne 0 ]; then
        echo "Failed to create web directory"
        exit 1
    fi
fi

if [ ! -d "$mount_point/steam/addon/addons/@ocap" ]; then
    mkdir -p "$mount_point/steam/addon/addons/@ocap"
    if [ $? -ne 0 ]; then
        echo "Failed to create addon directories"
        exit 1
    fi
fi

# Override web setting.json
cat >"$mount_point/steam/web/setting.json" <<EOF
{
    "listen": "0.0.0.0:5001",
    "secret": "150languard",
    "logger": true,
    "customize": {
        "websiteURL": "",
        "websiteLogo": "",
        "websiteLogoSize": "128px",
        "disableKillCount": false
    }
}
EOF
if [ $? -ne 0 ]; then
    echo "Failed to write web setting.json"
    exit 1
fi
echo "web setting.json file created successfully."

# Ensure userconfig directory exists for config.hpp
if [ ! -d "$mount_point/steam/addon/userconfig/ocap" ]; then
    mkdir -p "$mount_point/steam/addon/userconfig/ocap"
    if [ $? -ne 0 ]; then
        echo "Failed to create config.hpp directory"
        exit 1
    fi
fi

# Override config.hpp
cat >"$mount_point/steam/addon/userconfig/ocap/config.hpp" <<EOF
ocap_minPlayerCount = 2; // recording will only begin if this many players are in the server
ocap_minMissionTime = 1; // missions must last at least this many minutes to be saved
ocap_frameCaptureDelay = 1;
ocap_saveMissionEnded = true; // automatically save mission with default settings on the "MPEnded" event handler trigger
ocap_preferACEUnconscious = true; // if true, ACE3 medical unconscious state will be used. if false, will check vanilla A3 system
ocap_excludeClassFromRecord = ["ACE_friesAnchorBar", "GroundWeaponHolder", "WeaponHolderSimulated"]; // excludes specific class names from recordings
ocap_excludeKindFromRecord = []; // use isKindOf checking to exclude one or more hierarchies of objects from recording
ocap_excludeMarkerFromRecord = ["SystemMarker_"]; // excludes markers with any of these strings in their markerName
ocap_trackTimes = true; // continously track times -- set true for missions with accelerated or skipped time
ocap_trackTimeInterval = 5; // track time every X capture frame
ocap_isDebug = false; // extra logging messages
EOF
if [ $? -ne 0 ]; then
    echo "Failed to write config.hpp"
    exit 1
fi
echo "config.hpp file created successfully."

# Build OCAP web panel
cd "$mount_point/steam/web/cmd" || {
    echo "Failed to navigate to web cmd directory"
    exit 1
}
go build -o ../ocap-webserver
if [ $? -ne 0 ]; then
    echo "Failed to build OCAP webserver"
    exit 1
fi
echo "OCAP webserver built successfully."

# Run OCAP web panel
cd $mount_point/steam/web/ || {
    echo "Failed to navigate to $mount_point/steam/web/ocap-webserver directory"
    exit 1
}
nohup ./ocap-webserver &
if [ $? -ne 0 ]; then
    echo "Failed to start OCAP webserver"
    exit 1
fi
echo "OCAP webserver started successfully."

# Check if @cap exist
if [ ! -d "$mount_point/steam/@ocap" ]; then
    # Download @ocap mod archive
    cd $mount_point/steam/ || {
        echo "Failed to navigate to home directory"
        exit 1
    }
    wget https://github.com/OCAP2/OCAP/releases/download/v2.0/@ocap.7z -O @ocap.7z
    if [ $? -ne 0 ]; then
        echo "Failed to download @ocap mod"
        exit 1
    fi
    echo "@ocap mod downloaded successfully."

    # Extract @ocap mod using 7z
    7z x @ocap.7z -o"$mount_point/steam/"
    if [ $? -ne 0 ]; then
        echo "Failed to extract @ocap mod"
        exit 1
    fi
    echo "@ocap mod extracted successfully."

    # Clean up downloaded archive
    rm @ocap.7z
    if [ $? -ne 0 ]; then
        echo "Failed to remove @ocap.7z"
        exit 1
    fi
    echo "@ocap.7z removed successfully."
fi

if [ -d "$mount_point/steam/@ocap" ]; then
    # Create OcapReplaySaver2.cfg.json
    cat >"$mount_point/steam/@ocap/OcapReplaySaver2.cfg.json" <<EOF
{
    "httpRequestTimeout": 120,
    "logAndTmpPrefix": "ocap-",
    "logsDir": "./OCAPLOG",
    "newServerGameType": "TvT",
    "newUrl": "http://$ec2_ip:5001/api/v1/operations/add",
    "newUrlRequestSecret": "150languard",
    "traceLog": 0
}
EOF
    if [ $? -ne 0 ]; then
        echo "Failed to write OcapReplaySaver2.cfg.json"
        exit 1
    fi
    echo "OcapReplaySaver2.cfg.json file created successfully."
fi

# Check if the steamcmd arma3 directory exists
if [ -d "$mount_point/steam/steamcmd/arma3" ]; then
    echo "Directory $mount_point/steam/steamcmd/arma3 exists. Proceeding with file copying..."

    # Ensure @ocap source directory exists
    if [ -d "$mount_point/steam/@ocap" ]; then
        # Copy @ocap directory to addons (override if files exist)
        cp -r "$mount_point/steam/@ocap" "$mount_point/steam/steamcmd/arma3"
        if [ $? -eq 0 ]; then
            echo "Successfully copied @ocap to $mount_point/steam/steamcmd/arma3"
        else
            echo "Failed to copy @ocap"
            exit 1
        fi
    else
        echo "@ocap source directory $mount_point/steam/addon/addons/@ocap does not exist"
        exit 1
    fi

    # Ensure userconfig source directory exists
    if [ -d "$mount_point/steam/addon/userconfig" ]; then
        # Copy userconfig directory to addons (override if files exist)
        cp -r "$mount_point/steam/addon/userconfig" "$mount_point/steam/steamcmd/arma3"
        if [ $? -eq 0 ]; then
            echo "Successfully copied userconfig to $mount_point/steam/steamcmd/arma3"
        else
            echo "Failed to copy userconfig"
            exit 1
        fi
    else
        echo "userconfig source directory $mount_point/steam/addon/userconfig does not exist"
        exit 1
    fi
fi
