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

# THIS IS A MESS, BUT ONLY WORK THIS WAY!
bot_send() {
        curl -s "https://api.telegram.org/bot${telegram_bot_api}/sendmessage" -d "text=${1}" -d "chat_id=${telegram_chat_id}" -d "parse_mode=HTML"
}

cd ${CIRRUS_TMP_DIR}/ || { echo "Dir not found..."; exit 1; }

# Compress function with pigz for faster compression
compress_ccache()
{
  tar --use-compress-program="pigz -k -${2} " -cf "${1}".tar.gz "${1}"
}

# Compress ccache with same name
compress_ccache ccache 1

# Upload ccache
rclone copy ccache.tar.gz "${RCLONE_CONFIG_HEAD}":ccache/ci2 -P # 'ccache/ci2' is where ccache will be saved