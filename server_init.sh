#!/bin/bash

#-------------------------------------------------#
# Install required libraries, tools, and packages
#-------------------------------------------------#

# Add lib32gcc-s1
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y lib32gcc-s1

#Install Python3
sudo apt-get install python3

#Install Git
sudo apt install -y git-all

#Install rename
sudo apt install -y rename

#-------------------------------------------------#
# Mount EBS to machine and create user name steam
#-------------------------------------------------#

# Define the device and mount point
device=$(lsblk -b -o NAME,SIZE | awk 'NR>1 && $2 >= 100000000000 {print $1}') # Adjust the amount to fit mod list required
mount_point="/mnt/ebs_volume"

# Check if the device already has a file system
result=$(sudo file -s /dev/$device)

# If the device has no file system, format it
if [[ "$result" != *ext4* ]]; then
  echo "No file system detected on $device. Creating ext4 file system..."
  sudo mkfs -t ext4 /dev/$device
else
  echo "File system already exists on $device"
fi

# Create the mount point if it doesn't exist
sudo mkdir -p $mount_point

# Mount the device
sudo mount /dev/$device $mount_point
echo "$device has been mounted to $mount_point"

#-------------------------------------------------#
# Create user name steam and set home dir
#-------------------------------------------------#

# Create a new user named 'steam'
sudo adduser --home $mount_point/steam --shell /bin/bash -u 1009 steam # No password here

if [ ! -d "$mount_point/steam"]; then
  # Create the home directory for steam user
  sudo mkdir -p $mount_point/steam

  # Set permissions
  sudo chmod 755 $mount_point/steam

  # Change ownership and switch to steam user
  sudo chown -R steam:steam $mount_point/steam
fi

sudo su -c '/home/ssm-user/steamcmd_webpanel_init.sh' steam
sudo su -c '/home/ssm-user/install_mods_and_config.sh'