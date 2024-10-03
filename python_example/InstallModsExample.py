#!/usr/bin/python3

# MIT License
#
# Copyright (c) 2017 Marcel de Vries
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os
import os.path
import re
import shutil
import time

from datetime import datetime
from urllib import request

# region Configuration
STEAM_CMD = "/mnt/ebs_volume/steamcmd/steamcmd.sh"  # steamcmd.sh directory
STEAM_USER = ""
STEAM_PASS = ""

A3_SERVER_ID = "233780"
A3_SERVER_DIR = "/home/steam/arma3/install"  # arma3 server directory?? /mnt/ebs_volume/steamcmd/arma3
A3_WORKSHOP_ID = "107410" 

A3_WORKSHOP_DIR = "{}/steamapps/workshop/content/{}".format(
    A3_SERVER_DIR, A3_WORKSHOP_ID
)
A3_MODS_DIR = "/home/steam/arma3/mods"  # 3

MODS = {
    "@swu_immersion_sound_pack":                            "946763963",
    "@3cb_factions":                                        "1673456286",
    "@a3_thermal_improvement":                              "2041057379",
    "@ace":                                                 "463939057",
    "@ace_3_extension_(animations_and_actions)":            "766491311",
    "@advanced_rappelling":                                 "713709341",
    "@advanced_sling_loading":                              "615007497",
    "@advanced_towing":                                     "639837898",
    "@androids":                                            "2550788811",
    "@backpackonchest":                                     "820924072",
    "@bettir_(legacy_v0.2.1)":                              "2260572637",
    "@cba_a3":                                              "450814997",
    "@cup_terrains_-_core":                                 "583496184",
    "@dui_-_squad_radar":                                   "1638341685",
    "@enhanced_movement":                                   "333310405",
    "@enhanced_weather_+_clouds_mod_v2.1":                  "1465275935",
    "@global_ops_terrains":                                 "2917444360",
    "@improved_melee_system":                               "2291129343",
    "@korsac":                                              "3043043427",
    "@lybor":                                               "3013515917",
    "@niarms_all_in_one_-_rhs_compatibility.":              "1400574293",
    "@niarms_all_in_one_(v14_onwards)":                     "2595680138",
    "@niarms_all_in_one-_ace_compatibility":                "1400566170",
    "@pook_boat_pack":                                      "1529074643",
    "@rhsafrf":                                             "843425103",
    "@rhsgref":                                             "843593391",
    "@rhspkl":                                              "1978754337",
    "@rhssaf":                                              "843632231",
    "@rhsusaf":                                             "843577117",
    "@sa'hatra":                                            "3019928771",
    "@sullen_skies_-_korsac":                               "3043678553",
    "@task_force_arrowhead_radio_(beta!!!)":                "894678801",
    "@tfar_animations_-_deprecated":                        "2141020863",
    "@usp_gear_-_ace":                                      "2056229605",
    "@usp_gear_-_ihps":                                     "2588603554",
    "@usp_gear_&_uniforms_aio":                             "1795825073",
    "@vme_pla_mod":                                         "1562282342",
    "@weather_plus":                                        "2735613231",
    "@webknight's_zombies_and_creatures":                   "2789152015",
    "@zeus_enhanced":                                       "1779063631",
    "@zeus_immersion_sounds":                               "2461386136",
    "@zombies_and_demons":                                  "501966277",
    "@zombies_and_demons_ace_integration":                  "1606871585"
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
    steam_cmd_params = " +login {} {}".format(STEAM_USER, STEAM_PASS)
    steam_cmd_params += " +force_install_dir {}".format(A3_SERVER_DIR)
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

            steam_cmd_params = " +login {} {}".format(STEAM_USER, STEAM_PASS)
            steam_cmd_params += " +force_install_dir {}".format(A3_SERVER_DIR)
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
        "(cd {} && find . -depth -exec rename -v 's/(.*)\/([^\/]*)/$1\/\L$2/' {{}} \;)".format(
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


# endregion

log("Updating A3 server ({})".format(A3_SERVER_ID))
update_server()

log("Updating mods")
update_mods()

log("Converting uppercase files/folders to lowercase...")
lowercase_workshop_dir()

log("Creating symlinks...")
create_mod_symlinks()
