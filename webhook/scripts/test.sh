#!/bin/bash
# set -euxo pipefail
cd "$(dirname "$0")"

echo
echo "************************************"
echo "******** WEBHOOK TEST START ********"
echo "************************************"
echo
echo "pwd:$(pwd)"
echo
ls -alF
echo
echo "引数1: $1"
echo "引数2: $2"
echo "引数3: $3"
echo
echo "************************************"
echo "********* WEBHOOK TEST END *********"
echo "************************************"
