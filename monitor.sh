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

# Wait 2 minutes, lunch is starting
sleep 2m

while : # Loop to check ccache and machine status every 1 minute
do
  ccache -s
  echo ''
  top -b -i -n 1
  sleep 1m
done
