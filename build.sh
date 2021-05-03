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

# ROM BUILD VARIABLES
rom_manifest="git://github.com/AospExtended/manifest.git"
rom_manifest_branch="11.x"
rom_make_args="aex"
rom_make_lunch="aosp_"
rom_make_type="-user"

# DEVICE BUILD VARIABLES
builder_github="https://github.com/Apon77Lab/android_.repo_local_manifests.git"
builder_github_branch="aex"
builder_target_device="mido"
builder_target_brand="xiaomi"
builder_ccache_only="false" # current: disabled
builder_temp_upload="false" # upload to drive
builder_extract_vendor="false" # current: disabled
builder_lastest_rom="" # Latest zip

# Build.sh VARIABLES
buildsh_working_dir="${CIRRUS_WORKING_DIR}/../rom" # Where the rom is builded
buildsh_dump_rom="${CIRRUS_WORKING_DIR}/../dump_rom"
buildsh_rclone_config=$(echo "${rclone_config}" | head -1)
buildsh_rclone_config="${buildsh_rclone_config:1:-1}"

# GLOBAL VARIABLES
ccache_exec=$(which ccache)
export CCACHE_DIR="/tmp/ccache"
export CCACHE_EXEC="${ccache_exec}"
export USE_CCACHE="1"

# Enter the working dir
cd "${CIRRUS_WORKING_DIR}" || { echo "Dir not found..."; exit 1; }

# GIT VARIABLES
bot_git_branch=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/')

# Set bot function
bot_send() {
        curl -s "https://api.telegram.org/bot${telegram_bot_api}/sendmessage" -d "text=${bot_git_branch} ${1}" -d "chat_id=${telegram_chat_id}" -d "parse_mode=HTML"
}

# Set the upload function
upload_target()
{
  if ${builder_temp_upload}; then
    basename_toup=$(basename "${1}")
    # 14 days, 10 GB limit
    curl --upload-file "${1}" https://transfer.sh/"${basename_toup}"
  else
	# 'junk' is where zip will be saved
    rclone copy "${1}" "${buildsh_rclone_config}":junk -P
  fi
}

# Set compress function with pigz for faster compression
compress_ccache()
{
  tar --use-compress-program="pigz -k -${2} " -cf "${1}".tar.gz "${1}"
}

# Write rclone config found from env variable, so that cloud storage can be used to upload ccache
mkdir -p ~/.config/rclone
echo "${rclone_config}" > ~/.config/rclone/rclone.conf

# Working ROM dir
mkdir -p "${buildsh_working_dir}"

# Enter the working dir
cd "${buildsh_working_dir}" || { echo "Dir not found..."; exit 1; }

bot_send "Sync start!"

# Repo init command, that -device,-mips,-darwin,-notdefault part will save you more time and storage to sync, add more according to your rom and choice.
# Optimization is welcomed! Let's make it quit, and with depth=1 so that no unnecessary things.
repo init -q --no-repo-verify --depth=1 -u ${rom_manifest} -b ${rom_manifest_branch} -g default,-device,-mips,-darwin,-notdefault

# Clone local manifest! So that no need to manually git clone repos or change hals, you can use normal git clone or rm and re clone, they will cost little more time, and you may get timeout! Let's make it quit and depth=1 too.
git clone "${builder_github}" --depth 1 -b "${builder_github_branch}" .repo/local_manifests

# Sync source with -q, no need unnecessary messages, you can remove -q if want! try with -j30 first, if fails, it will try again with -j8
repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j 30 || repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j 8

bot_send "Sync done!"

# Extract vendor blobs direct from latest zip
# Based on Lineage and other source
# https://wiki.lineageos.org/extracting_blobs_from_zips.html
if ${builder_extract_vendor}; then
  # Create the system_dump directory.
  mkdir -p "${buildsh_dump_rom}"/
  
  # Enter the system_dump directory.
  cd "${buildsh_dump_rom}"/ || { echo "Dir not found..."; exit 1; }

  # Download sdat2img
  aria2c https://raw.githubusercontent.com/xpirt/sdat2img/master/sdat2img.py -x16 -s50

  # Download the build zip.
  aria2c "${builder_lastest_rom}" -x16 -s50

  basename_rom=$(basename ./*.zip)

  if [ ! -f "${basename_rom}" ]; then
    echo "Vendor blobs zip file not found..."
	exit 1
  fi

  # Extract the system and vendor data from the LineageOS archive.
  unzip "${basename_rom}".zip system.transfer.list system.new.dat*
  unzip "${basename_rom}".zip vendor.transfer.list vendor.new.dat* 

  # The vendor and system data files are compress, so decompress them before we use them.
  if [ -f "system.new.dat.br" ];then
    brotli --decompress --output=system.new.dat system.new.dat.br
  fi
  if [ -f "vendor.new.dat.br" ];then
    brotli --decompress --output=vendor.new.dat vendor.new.dat.br
  fi

  # Convert dat files to img files that can be mounted.
  python sdat2img.py system.transfer.list system.new.dat system.img
  python sdat2img.py vendor.transfer.list vendor.new.dat vendor.img

  # Mount system/
  mkdir system/
  sudo mount system.img system/

  # Mount system/vendor/
  sudo rm system/vendor
  sudo mkdir system/vendor
  sudo mount vendor.img system/vendor/

  # Go to device-tree
  cd "${buildsh_working_dir}"/device/${builder_target_brand}/${builder_target_device}/ || { echo "Dir not found..."; exit 1; }

  # Finally extract device blobs
  ./extract-files.sh "${buildsh_dump_rom}"/

  # Back the working dir
  cd "${buildsh_working_dir}" || { echo "Dir not found..."; exit 1; }

fi

# Normal build steps
source build/envsetup.sh
lunch ${rom_make_lunch}${builder_target_device}${rom_make_type}

# Set ccache options
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
  make -j10 ${rom_make_args} & sleep 85m
  kill %1
else
  bot_send "Building ROM Started!"
  make -j10 ${rom_make_args}
  upload_target "${buildsh_working_dir}"/out/target/product/${builder_target_device}/*.zip
fi

ccache -s # Let's print ccache statistics finally

cd "${CIRRUS_WORKING_DIR}"/../ || { echo "Dir not found..."; exit 1; }

# Compress ccache with same name
compress_ccache ccache 1

# Upload ccache
rclone copy ccache.tar.gz "${buildsh_rclone_config}":ccache/ci2 -P # 'ccache/ci2' is where ccache will be saved