#!/bin/bash

#-------------------------------------------------#
# Download steamcmd and create/run webpanel
#-------------------------------------------------#

# Define mount point
mount_point="/mnt/ebs_volume"

#Install NodeJS
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
NVM_DIR="$mount_point/steam/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm install 20
nvm use 20

# Check if steamcmd exist
if [ ! -d "$mount_point/steamcmd" ]; then
  # Create a new directory for SteamCMD to avoid cluttering the home directory.
  mkdir ~/steamcmd && cd ~/steamcmd

  # Download the SteamCMD for Linux tarball and extract the tarball.
  curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

  # Create the directories used to store the profile files and Arma3.cfg file.
  mkdir -p ~/".local/share/Arma 3" && mkdir -p ~/".local/share/Arma 3 - Other Profiles"
fi

#-------------------------------------------------#
# Create/Run webpanel for Arma 3
#-------------------------------------------------#

#Create and run arma-server-web-admin on the first run
if [ ! -d "$mount_point/steam/arma-server-web-admin" ]; then
  #Clone arma-server-web-admin repo
  cd ~
  git clone https://github.com/Dahlgren/arma-server-web-admin.git && cd ~/arma-server-web-admin

  # Create config.js
  cat > config.js <<EOF2
module.exports = {
    game: 'arma3_x64', // arma3, arma2oa, arma2, arma1, cwa, ofpresistance, ofp
    path: '$mount_point/steam/steamcmd/arma3',
    port: 9989,
    host: '0.0.0.0', // Can be either an IP or a Hostname
    type: 'linux', // Can be either linux, windows or wine
    additionalConfigurationOptions: '', // Additional configuration options appended to server.cfg file
    parameters: [ // Additional startup parameters used by all servers
        '-cfg="basic.cfg"', //Push you own config file here
        '-maxMem=28671',
        '-autoInit',
        '-enableHT',
        '-name="Administrator"',
        '-limitFPS=120',
    ],
    serverMods: [ // Mods used exclusively by server and not shared with clients
    ],
    admins: [], // add steam IDs here to enable #login without password
    auth: { // If both username and password is set, HTTP Basic Auth will be used. You may use an array to specify more than one user.
        username: 'admin', // Username for HTTP Basic Auth
        password: '1235', // Password for HTTP Basic Auth
    },
    prefix: "", // Prefix to all server names
    suffix: "", // Suffix to all server names
    logFormat: "dev", // expressjs/morgan log format
};
EOF2

  # Install package
  npm i
elif [ -d ~/steamcmd/arma3 ]; then #if arma3 already install and setup then run the web panel
  # Access web panel folder
  cd ~/arma-server-web-admin
  
  # Start web panel
  nohup node app.js
fi