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

# Set the bot for this background script
bot_send() {
        curl -s "https://api.telegram.org/bot${telegram_bot_api}/sendmessage" -d "text=${1}" -d "chat_id=${telegram_chat_id}" -d "parse_mode=HTML"
}

bot_send "Start CCache download!"

# Current ccache
ccache_url=http://roms.apon77.workers.dev/ccache/ci2/ccache.tar.gz

# Working dir
cd "${CIRRUS_WORKING_DIR}"/../ || { echo "Dir not found..."; exit 1; }

# Using aria2c for download
aria2c "${ccache_url}" -x16 -s50

# Extract ccache
tar xf ccache.tar.gz 

# Remove downloaded file
rm -rf ccache.tar.gz

bot_send "Download CCache done!"