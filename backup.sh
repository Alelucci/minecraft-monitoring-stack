#!/bin/bash

# Script to backup the minecraft server or world only

if [ $# -ne 1 ]; then
    echo "Usage: $0 total OR world"
fi

if [ "$1" = "world" ]; then
    origin_folder=/data/world
    dest_folder=$(date +%Y-%m-%d)_world_backup
elif [ "$1" = "total" ]; then
    origin_folder=/data
    dest_folder=$(date +%Y-%m-%d)_total_backup
else
    echo "Usage: $0 total OR world"
    exit 1
fi

server_container=$(docker ps -a --filter name=server | awk 'NF>1{print $NF}'|tail -n +2)

if ! which zip ; then apt install zip -y; fi

docker cp $server_container:$origin_folder ./$dest_folder
zip -r $dest_folder.zip $dest_folder &>/dev/null
rm -rf $dest_folder