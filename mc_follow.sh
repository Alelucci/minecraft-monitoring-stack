#!/bin/bash

# Script to quickly follow the server's logs

server_container=$(docker ps -a --filter name=server | awk 'NF>1{print $NF}'|tail -n +2)

docker logs --follow $server_container

echo "
---------- End $server_container logs ----------
"