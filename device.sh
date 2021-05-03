#!/bin/bash
#
# Copyright 2021 Caio99BR
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

cd ${CIRRUS_ROM_DIR} || { echo "Dir not found..."; exit 1; }

# Clone local manifest! So that no need to manually git clone repos or change hals, you can use normal git clone or rm and re clone, they will cost little more time, and you may get timeout! Let's make it quit and depth=1 too.
git clone https://github.com/Apon77Lab/android_.repo_local_manifests.git --depth 1 -b aex .repo/local_manifests