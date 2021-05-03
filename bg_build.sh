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

# LOCAL VARIABLES
builder_ccache_only="false" # current: disabled
builder_ccache_url=http://roms.apon77.workers.dev/ccache/ci2/ccache.tar.gz

# GIT VARIABLES
bot_git_branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')

# Set bot function
bot_send() {
        curl -s "https://api.telegram.org/bot${telegram_bot_api}/sendmessage" -d "text=${bot_git_branch} ${1}" -d "chat_id=${telegram_chat_id}" -d "parse_mode=HTML"
}

if ${builder_ccache_only}; then

  bot_send "Skipping CCache download!"
  echo "Skipping CCache download!"

else

  bot_send "Start CCache download!"

  # Working dir
  cd "${CIRRUS_WORKING_DIR}"/../ || { echo "Dir not found..."; exit 1; }

  # Using aria2c for download
  aria2c "${builder_ccache_url}" -x16 -s50

  # Extract ccache
  tar xf ccache.tar.gz 

  # Remove downloaded file
  rm -rf ccache.tar.gz

  bot_send "Download CCache done!"

fi