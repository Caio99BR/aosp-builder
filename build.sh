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
# TODO2: Optimize with AdrianDC/advanced_development_shell_tools
# TODO3: Add variable to check files

# GLOBAL VARIABLES
ccache_exec=$(which ccache)
export CCACHE_DIR=/tmp/ccache
export CCACHE_EXEC=${ccache_exec}
export USE_CCACHE=1

# THIS IS A MESS, BUT ONLY WORK THIS WAY!
bot_send() {
        curl -s "https://api.telegram.org/bot${telegram_bot_api}/sendmessage" -d "text=${1}" -d "chat_id=${telegram_chat_id}" -d "parse_mode=HTML"
}

# Depends on where source got synced
cd ${CIRRUS_ROM_DIR} || { echo "Dir not found..."; exit 1; }

upload_target()
{
  if ${builder_temp_upload}; then
    basename_toup=$(basename "${1}")
    # 14 days, 10 GB limit
    curl --upload-file "${1}" https://transfer.sh/"${basename_toup}"
  else
	# 'junk' is where zip will be saved
    rclone copy "${1}" "${RCLONE_CONFIG_HEAD}":junk -P
  fi
}

# Normal build steps
. build/envsetup.sh
lunch aosp_${builder_target_device}-user
ccache -M 20G # It took only 6.4GB for mido
ccache -o compression=true # Will save times and data to download and upload ccache, also negligible performance issue
ccache -z # Clear old stats, so monitor script will provide real ccache statistics

# Let's compile by parts! Coz of ram issue!
make -j10 api-stubs-docs
make -j10 system-api-stubs-docs
make -j10 test-api-stubs-docs
if ${builder_ccache_only}; then
  # Build for 85m then kill the process
  # This is for build the ccache and upload
  bot_send "Building CCache Started!"
  make -j10 ${ROM_MAKE_ARGS} & sleep 85m
  kill %1
else
  bot_send "Building ROM Started!"
  make -j10 ${ROM_MAKE_ARGS}
  upload_target ${CIRRUS_ROM_DIR}/out/target/product/${builder_target_device}/*.zip
fi

ccache -s # Let's print ccache statistics finally
