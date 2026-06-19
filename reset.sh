#!/bin/bash

# Script to reset everything to initial status except bash scripts and dashboards

# Stop and removal of all the container in the compose and the networks used
docker compose down

# Removal of all the volumes used by the compose
current_folder= $(echo $PWD | awk -F '/' 'NF>1{print $NF}')
docker volume ls -q | grep "$current_folder" | xargs docker volume rm
rm -rf ./world/*

# Reset of singular files
echo "[]" > banned-ips.json
echo "[]" > banned-players.json
echo "[]" > ops.json
echo "[]" > usercache.json
echo "[]" > whitelist.json

echo "#Minecraft server properties
#Thu Jun 18 10:53:53 UTC 2026
accepts-transfers=false
allow-flight=false
broadcast-console-to-ops=true
broadcast-rcon-to-ops=true
bug-report-link=
chat-spam-threshold-seconds=10
command-spam-threshold-seconds=10
difficulty=easy
enable-code-of-conduct=false
enable-jmx-monitoring=false
enable-query=false
enable-rcon=true
enable-status=true
enforce-secure-profile=true
enforce-whitelist=false
entity-broadcast-range-percentage=100
force-gamemode=false
function-permission-level=2
gamemode=survival
generate-structures=true
generator-settings={}
hardcore=false
hide-online-players=false
initial-disabled-packs=
initial-enabled-packs=vanilla
level-name=world
level-seed=
level-type=minecraft\:normal
log-ips=true
management-server-allowed-origins=
management-server-enabled=false
management-server-host=localhost
management-server-port=0
management-server-secret=A63kndHQEv9rGM7x5tLk8vIDTdCrFCoamqXyxIcI
management-server-tls-enabled=true
management-server-tls-keystore=
management-server-tls-keystore-password=
max-chained-neighbor-updates=1000000
max-players=20
max-tick-time=60000
max-world-size=29999984
motd=A Minecraft Server
network-compression-threshold=256
online-mode=true
op-permission-level=4
pause-when-empty-seconds=60
player-idle-timeout=0
prevent-proxy-connections=false
query.port=25565
rate-limit=0
rcon.password=7558cbc3f527d3215bd23655
rcon.port=25575
region-file-compression=deflate
require-resource-pack=false
resource-pack=
resource-pack-id=
resource-pack-prompt=
resource-pack-sha1=
server-ip=
server-port=25565
simulation-distance=10
spawn-protection=16
status-heartbeat-interval=0
sync-chunk-writes=true
text-filtering-config=
text-filtering-version=0
use-native-transport=true
view-distance=10
white-list=false
" > server.properties

echo "# Prometheus configuration file to read the exporter's data

global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'minecraft-exporter'
    static_configs:
      - targets: ['exporter:8080']
" > ./config/prometheus.yml

echo '# Log level of the application
logLevel: "info"

# Port for the metrics server
port: 8080
# Interval in which remote_write is invoked when enabled
interval: "5m"
# Name of the instance, used to label metrics. Defaults to hostname when empty
instance: ""
# Indicate if the number of metrics should be reduced (Useful when using grafana cloud)
reduceMetrics: false
# Set the server type (vanilla, forge, paper, neoforge), used for RCON collection
server: "vanilla"
# Enable dynmap metrics collection
dynmap: false
# Directory where the minecraft world is saved
world: "/world"

# Configure RCON
rcon:
  # Enable rcon, when false this part of the config will be ignored
  enable: false
  # The IP/Address of the Server (e.g localhost, example.org, 127.0.0.1)
  host: "main_server"
  # RCON port configured in the server settings
  port: 0
  # Password used for RCON
  password: ""

# Configure remote_write behaviour
remote:
  # Enable remote write, when false this part of the config will be ignored
  enable: false
  # URL to prometheus remote_write endpoint
  url: ""
  # Overwrite the instance label for remote write.
  instance: ""
  # Name of job under which metrics will be pushed
  jobName: "minecraft-exporter"
  # Username and password for Basic Authentication. Leave empty when not required
  username: ""
  password: ""
  ' > ./config/exporter.yaml

echo '#These are the credentials used by the scripts to access the static database, please remember to update them if changes occur

[client]
user = "user1"
password = "changeme1"
database= "world"
' > ./config/mysql_credentials.cnf

echo 'services:

  main_server:
    image: itzg/minecraft-server
    tty: true
    stdin_open: true
    environment:
      EULA: "TRUE"
      MEMORY: 1G
    volumes:
      - minecraft_world:/data/world
      - ./server.properties:/data/server.properties
      - ./banned-ips.json:/data/banned-ips.json
      - ./banned-players.json:/data/banned-players.json
      - ./usercache.json:/data/usercache.json
      - ./whitelist.json:/data/whitelist.json
      - ./ops.json:/data/ops.json
    ports:
      - "25565:25565"

  db:
    image: mysql:latest
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: changeme
      MYSQL_DATABASE: world
      MYSQL_USER: user1
      MYSQL_PASSWORD: changeme1

    volumes:
      - db_data:/var/lib/mysql

  db_interface:
    image: phpmyadmin:latest
    depends_on:
      - db
    ports: 
      - "8060:80"

  exporter:
    image: heathcliff26/minecraft-exporter:latest
    user: root
    restart: always
    volumes:
      - minecraft_world:/world
      - ./config/exporter.yaml:/config/config.yaml
    command: ["-config", "/config/config.yaml"]
    depends_on:
      main_server:
        condition: service_healthy
        restart: true
    #ports: 
    #  - "8081:80"
    
  puller:
    image: prom/prometheus:latest
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    depends_on:
      - exporter
    #ports:
    #  - "9090:9090"

  monitor:
    image: grafana/grafana:latest
    user: root
    depends_on:
      - puller
    volumes:
      - grafana_storage:/var/lib/grafana 
      - ./config/server_source.yaml:/etc/grafana/provisioning/datasources/My_Minecraft_server.yaml
      - ./config/dashboards:/etc/grafana/provisioning/dashboards
    ports:
      - "3000:3000"

volumes:
  db_data:
  grafana_storage:
  minecraft_world:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: ./world
' > compose.yml

echo "datasources:
  - name: My_Minecraft_server
    type: prometheus
    access: proxy
    url: http://puller:9090
    isDefault: true
    editable: true
" > ./config/server_source.yaml

echo "apiVersion: 1

providers:
  - name: 'My_Minecraft_server'
    orgId: 1
    folder: 'My_Minecraft_server' # Cartella in cui appariranno su Grafana
    type: file
    disableDeletion: true
    editable: false
    options:
      path: /etc/grafana/provisioning/dashboards/json_files
" > ./config/dashboards/dashboards.yaml