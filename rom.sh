#!/bin/bash
#
# Copyright 2021 Apon77
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# ROM BUILD VARIABLES
rom_manifest=git://github.com/AospExtended/manifest.git
rom_manifest_branch=11.x

# THIS IS A MESS, BUT ONLY WORK THIS WAY!
bot_send() {
        curl -s "https://api.telegram.org/bot${telegram_bot_api}/sendmessage" -d "text=${1}" -d "chat_id=${telegram_chat_id}" -d "parse_mode=HTML"
}

# Working ROM dir
mkdir -p ${CIRRUS_ROM_DIR}
cd ${CIRRUS_ROM_DIR} || { echo "Dir not found..."; exit 1; }

# Repo init command, that -device,-mips,-darwin,-notdefault part will save you more time and storage to sync, add more according to your rom and choice.
# Optimization is welcomed! Let's make it quit, and with depth=1 so that no unnecessary things.
repo init -q --no-repo-verify --depth=1 -u ${rom_manifest} -b ${rom_manifest_branch} -g default,-device,-mips,-darwin,-notdefault
