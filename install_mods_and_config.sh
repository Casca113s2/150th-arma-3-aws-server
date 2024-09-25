#!/bin/bash

# Define the device and mount point
mount_point="/mnt/ebs_volume"

# Create Arma3Profile
mkdir $mount_point/steam/".local/share/Arma 3 - Other Profiles/Administrator"
cd $mount_point/steam/".local/share/Arma 3 - Other Profiles/Administrator"

cat > Administrator.Arma3Profile <<EOF
class DifficultyPresets
{
	class CustomDifficulty
	{
		class Options
		{
			reducedDamage=0;
			groupIndicators=0;
			friendlyTags=0;
			enemyTags=0;
			detectedMines=0;
			commands=1;
			waypoints=0;
			weaponInfo=2;
			stanceIndicator=2;
			staminaBar=2;
			weaponCrosshair=0;
			visionAid=0;
			thirdPersonView=0;
			cameraShake=1;
			scoreTable=0;
			deathMessages=1;
			vonID=1;
			mapContentFriendly=0;
			mapContentEnemy=0;
			mapContentMines=0;
			autoReport=0;
			multipleSaves=0;
			tacticalPing=0;
		};
		aiLevelPreset=3;
	};
	class CustomAiLevel
	{
		skillAI=1;
		precisionAI=0.2;
	};
};
difficulty="custom";
singleVoice=0;
maxSamplesPlayed=96;
activeKeys[]={};
sceneComplexity=400000;
shadowZDistance=100;
viewDistance=2000;
preferredObjectViewDistance=800;
pipViewDistance=500;
terrainGrid=25;
volumeCD=10;
volumeFX=10;
volumeSpeech=10;
volumeVoN=10;
vonRecThreshold=0.029999999;
volumeMapDucking=1;
volumeUI=1;
EOF

# Create InstallMods.py
cd $mount_point/steam/steamcmd

cat >InstallMods.py <<EOF2
#!/usr/bin/python3

import os
import os.path
import re
import shutil
import time

from datetime import datetime
from urllib import request

# region Configuration
STEAM_CMD = "/mnt/ebs_volume/steam/steamcmd/steamcmd.sh"  # steamcmd.sh directory
STEAM_USER = ""  # Note account already login to steamcmd and cached

A3_SERVER_ID = "233780"
A3_SERVER_DIR = (
    "/mnt/ebs_volume/steam/steamcmd/arma3"  # arma3 server directory and mods should be here
)
A3_WORKSHOP_ID = "107410"

A3_WORKSHOP_DIR = "{}/steamapps/workshop/content/{}".format(
    A3_SERVER_DIR, A3_WORKSHOP_ID
)
A3_MODS_DIR = "/mnt/ebs_volume/steam/steamcmd/arma3"

MODS = {
    "@SWU Immersion Sound Pack": "946763963",
    "@3CB Factions": "1673456286",
    "@A3 Thermal Improvement": "2041057379",
    "@ace": "463939057",
    "@ACE 3 Extension (Animations and Actions)": "766491311",
    "@Advanced Rappelling": "713709341",
    "@Advanced Sling Loading": "615007497",
    "@Advanced Towing": "639837898",
    "@Androids": "2550788811",
    "@BackpackOnChest": "820924072",
    "@BettIR (Legacy v0.2.1)": "2260572637",
    "@CBA_A3": "450814997",
    "@CUP Terrains - Core": "583496184",
    "@DUI - Squad Radar": "1638341685",
    "@Enhanced Movement": "333310405",
    "@Enhanced Weather + Clouds Mod v2.1": "1465275935",
    "@Global Ops Terrains": "2917444360",
    "@Improved Melee System": "2291129343",
    "@Korsac": "3043043427",
    "@Lybor": "3013515917",
    "@NIArms All in One - RHS Compatibility.": "1400574293",
    "@NIArms All In One (V14 Onwards)": "2595680138",
    "@NIArms All in One- ACE Compatibility": "1400566170",
    "@Pook Boat Pack": "1529074643",
    "@RHSAFRF": "843425103",
    "@RHSGREF": "843593391",
    "@RHSPKL": "1978754337",
    "@RHSSAF": "843632231",
    "@RHSUSAF": "843577117",
    "@Sa'hatra": "3019928771",
    "@Sullen Skies - Korsac": "3043678553",
    "@Task Force Arrowhead Radio (BETA!!!)": "894678801",
    "@TFAR Animations - Deprecated": "2141020863",
    "@USP Gear - ACE": "2056229605",
    "@USP Gear - IHPS": "2588603554",
    "@USP Gear & Uniforms AIO": "1795825073",
    "@VME PLA Mod": "1562282342",
    "@Weather Plus": "2735613231",
    "@WebKnight's Zombies and Creatures": "2789152015",
    "@Zeus Enhanced": "1779063631",
    "@Zeus Immersion Sounds": "2461386136",
    "@Zombies and Demons": "501966277",
    "@Zombies and Demons ACE integration": "1606871585",
}

PATTERN = re.compile(r"workshopAnnouncement.*?<p id=\"(\d+)\">", re.DOTALL)
WORKSHOP_CHANGELOG_URL = "https://steamcommunity.com/sharedfiles/filedetails/changelog"
# endregion


# region Functions
def log(msg):
    print("")
    print("{{0:=<{}}}".format(len(msg)).format(""))
    print(msg)
    print("{{0:=<{}}}".format(len(msg)).format(""))


def call_steamcmd(params):
    os.system("{} {}".format(STEAM_CMD, params))
    print("")


def update_server():
    steam_cmd_params = " +force_install_dir {}".format(A3_SERVER_DIR)
    steam_cmd_params += " +login {}".format(STEAM_USER)
    steam_cmd_params += " +app_update {} validate".format(A3_SERVER_ID)
    steam_cmd_params += " +quit"

    call_steamcmd(steam_cmd_params)


def mod_needs_update(mod_id, path):
    if os.path.isdir(path):
        response = request.urlopen(
            "{}/{}".format(WORKSHOP_CHANGELOG_URL, mod_id)
        ).read()
        response = response.decode("utf-8")
        match = PATTERN.search(response)

        if match:
            updated_at = datetime.fromtimestamp(int(match.group(1)))
            created_at = datetime.fromtimestamp(os.path.getctime(path))

            return updated_at >= created_at

    return False


def update_mods():
    for mod_name, mod_id in MODS.items():
        path = "{}/{}".format(A3_WORKSHOP_DIR, mod_id)

        # Check if mod needs to be updated
        if os.path.isdir(path):

            if mod_needs_update(mod_id, path):
                # Delete existing folder so that we can verify whether the
                # download succeeded
                shutil.rmtree(path)
            else:
                print(
                    'No update required for "{}" ({})... SKIPPING'.format(
                        mod_name, mod_id
                    )
                )
                continue

        # Keep trying until the download actually succeeded
        tries = 0
        while os.path.isdir(path) == False and tries < 10:
            log('Updating "{}" ({}) | {}'.format(mod_name, mod_id, tries + 1))
            steam_cmd_params = " +force_install_dir {}".format(A3_SERVER_DIR)
            steam_cmd_params += " +login {}".format(STEAM_USER)
            steam_cmd_params += " +workshop_download_item {} {} validate".format(
                A3_WORKSHOP_ID, mod_id
            )
            steam_cmd_params += " +quit"

            call_steamcmd(steam_cmd_params)

            # Sleep for a bit so that we can kill the script if needed
            time.sleep(5)

            tries = tries + 1

        if tries >= 10:
            log("!! Updating {} failed after {} tries !!".format(mod_name, tries))


def lowercase_workshop_dir():
    os.system(
        "(cd {} && find . -depth -exec rename -v 's/(.*)\/([^\/]*)/\$1\/\L\$2/' {{}} \;)".format(
            A3_WORKSHOP_DIR
        )
    )


def create_mod_symlinks():
    for mod_name, mod_id in MODS.items():
        link_path = "{}/{}".format(A3_MODS_DIR, mod_name)
        real_path = "{}/{}".format(A3_WORKSHOP_DIR, mod_id)

        if os.path.isdir(real_path):
            if not os.path.islink(link_path):
                os.symlink(real_path, link_path)
                print("Creating symlink '{}'...".format(link_path))
        else:
            print("Mod '{}' does not exist! ({})".format(mod_name, real_path))


def create_basic_cfg():
    basic_cfg_content = """
///////////// MILDLY_INTERESTED & KARMAKUT SETTINGS

// These options are created by default
language="English";
adapter=-1;
3D_Performance=1.000000;
Resolution_W=800;
Resolution_H=600;
Resolution_Bpp=32;
terrainGrid=25;
viewDistance = 2000;


// These options are important for performance tuning

MaxBandwidth = 2147483647;      // 2.1 gbit //or comment out, setting doesn't do anything
MinBandwidth = 249000000;                // 249 mbit/6 zeros //not really relevant, do not set higher than your actual available bandwidth, also tested with 256000000 (256mbit/6 zeros)
MaxMsgSend = 64;                //IMPORTANT setting, also tested with 48 but that comes with increased lag whenever a player connects, setting this to 128 or more has resulted in the server yellow chaining and not recovering on 16AA and Karmakut servers.
MaxSizeGuaranteed = 512;
MaxSizeNonguaranteed = 1024;
MinErrorToSend = 0.001;
MinErrorToSendNear = 0.01;


MaxCustomFileSize = 1024000;                    // (bytes) Users with custom face or custom sound larger than this size are kicked when trying to connect.
//class sockets{ maxPacketSize = 1400;};
"""
    cfg_path = os.path.join(A3_SERVER_DIR, "basic.cfg")

    with open(cfg_path, "w") as cfg_file:
        cfg_file.write(basic_cfg_content)
        print("basic.cfg created at {}".format(cfg_path))


# endregion

log("Updating A3 server ({})".format(A3_SERVER_ID))
update_server()

log("Updating mods")
update_mods()

log("Converting uppercase files/folders to lowercase...")
lowercase_workshop_dir()

log("Creating symlinks...")
create_mod_symlinks()

log("Creating basic.cfg...")
create_basic_cfg()
EOF2

# Set owner to steam
sudo chown -R steam:steam $mount_point/steam/".local/share/Arma 3/Administrator.Arma3Profile"
sudo chown -R steam:steam $mount_point/steam/steamcmd/InstallMods.py

# Set permissions
sudo chmod 755 $mount_point/steam/".local/share/Arma 3/Administrator.Arma3Profile"
sudo chmod 755 $mount_point/steam/steamcmd/InstallMods.py
