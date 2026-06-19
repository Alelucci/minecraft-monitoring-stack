#!/bin/bash

# Script to quickly access the server's command line

server_container=$(docker ps -a --filter name=server | awk 'NF>1{print $NF}'|tail -n +2)

docker exec -it $server_container rcon-cli 