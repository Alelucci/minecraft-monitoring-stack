# 🎮 Minecraft Server Monitoring Stack

A self-hosted Minecraft server infrastructure with player data persistence and full observability, built with Docker Compose.

---

## 📋 Overview

This project runs a Minecraft server alongside a complete monitoring stack, demonstrating container orchestration, data persistence, and infrastructure observability practices.

The stack includes:

- **Minecraft Server** — the game server itself
- **MySQL** — stores player-related data
- **phpMyAdmin** — web interface for managing the MySQL database
- **Minecraft Exporter** — exposes server metrics in Prometheus format, made by [heathcliff26](https://github.com/heathcliff26/minecraft-exporter)
- **Prometheus** — collects and stores metrics over time
- **Grafana** — visualizes metrics through dashboards that were also made by [heathcliff26](https://github.com/heathcliff26/minecraft-exporter)

---

## 🏗️ Architecture

``` 
                              :25565
                              |
                    ┌─────────|─────────┐
                    │  Minecraft Server │
                    └─────────┬─────────┘
                              │
              ┌───────────────┼────────────────┐
              │                                │
      ┌───────▼────────┐            ┌──────────▼──────────┐
      │      MySQL     │            │ Minecraft Exporter  │
      │ (player data)  │            │  (metrics)          │
      └───────┬────────┘            └─────────┬───────────┘
              │                               │
      ┌───────▼────────┐            ┌─────────▼─────────┐
      │   phpMyAdmin   │            │    Prometheus     │
      │  (DB interface)│            │  (metrics store)  │
      └───────|────────┘            └─────────┬─────────┘
              |                               │
              :8060                 ┌─────────▼──────────┐
                                    │      Grafana       │
                                    │   (dashboards)     │
                                    └─────────|──────────┘
                                              |
                                              :3000
```

---

## 🛠️ Technologies

| Tool | Purpose |
|------|---------|
| [Minecraft Server](https://hub.docker.com/r/itzg/minecraft-server) | Game server |
| [MySQL](https://hub.docker.com/_/mysql) | Player data storage |
| [phpMyAdmin](https://hub.docker.com/r/phpmyadmin/phpmyadmin) | Database management UI |
| [Prometheus](https://hub.docker.com/r/prom/prometheus) | Metrics collection and storage |
| [Grafana](https://hub.docker.com/r/grafana/grafana) | Metrics visualization |
| [Exporter](https://hub.docker.com/r/heathcliff26/minecraft-exporter) | Metrics extractor and exposer |
---

## 🚀 Getting Started

### Prerequisites

- Docker Engine 24+
- Docker Compose v2

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Alelucci/minecraft-monitoring-stack.git
cd minecraft-monitoring-stack
```

2. Start the stack:
```bash
docker compose up -d
```

3. Check that all containers are running:
```bash
docker compose ps
```
If its the first run of the compose the exporter container may be shutting down or restarting, it will fix itself after at least one player joined the minecraft world and after a restart using
```bash
docker compose down
docker compose up -d
```
using 
```bash
docker compose restart
```
may not work because the minecraft_world volume needs to be updated and re-binded

### Access the services

| Service | URL | Notes |
|---------|-----|-------|
| Minecraft Server | `<host>:25565` | Connect via Minecraft client |
| phpMyAdmin | http://localhost:8060 | DB credentials in compose file variables (default: root/changeme, user1/changeme1) |
| Grafana | http://localhost:3000 | Default login: admin / admin |

---

## 📁 Project Structure

```
minecraft-monitoring-stack/
├── config/
│   │
│   ├── dashboards/
│   │   ├── json_files/
│   │   │   ├── dashboard-1781799335297.json        # server's data dashboard
│   │   │   └── dashboard-1781799359688.json        # player's data dashboard
│   │   └── dashboards.yaml                         # dashboardes structure
│   │
│   ├── mysql/
│   │   ├── mysql_credentials.cnf                   # credestials used by scripts to access database
│   │   └── players_table.sql                       # mysql command to create table "players"
│   │
│   ├── exporter.yaml                               # metrics exporter extra configs
│   ├── prometheus.yaml                             # prometheus metrics scrape config
│   └── server_source.yaml                          # grafana-prometheus data source
│
├── world/                                          # empty folder that will be populated with minecraft/world
│
├── backup.sh                                       # bash script for total or world-only local backup
├── banned-ips.json                                 # minecraft/banned-ips.json file
├── banned-players.json                             # minecraft/banned-players.json file
├── compose.yml                                     # docker compose project
├── mc_cli.sh                                       # bash script to open the server's command line
├── mc_follow.sh                                    # bash script to follow the server's logs in real time
├── ops.json                                        # minecraft/ops.json file
├── players_data_to_db.sh                           # bash script to copy some player's data to mysql db
├── reset.sh                                        # bash script to reset everything except dashboards and bash scripts
├── server.properties                               # minecraft/server.properties file
├── usercache.json                                  # minecraft/usercache.json file
└── whitelist.json                                  # minecraft/whitelist.json file
```

---

## 📦 Data Persistence

- **Minecraft world data** — stored in a Docker volume named "minecraft_world" to persist across container restarts
- **MySQL player data** — stored in a separate volume named "db_data", independent from the game server lifecycle
- **Grafana dashboards/config** — persisted via volume "grafana_storage" to survive container recreation

---

## 📈 Monitoring

The Minecraft Exporter exposes game server metrics (players online, TPS, memory usage) at a `/metrics` endpoint, scraped by Prometheus every 15 seconds. Grafana queries Prometheus to render real-time dashboards on server health and player activity.

---

## 🧠 What I learned

- Multi-container orchestration with service dependencies in Docker Compose
- Managing stateful data with named volumes across multiple services
- Exposing application metrics in Prometheus format via a dedicated exporter
- Building Grafana dashboards backed by Prometheus as a data source
- Structuring a database layer (MySQL + phpMyAdmin) alongside an application service

---

## 🔮 Possible improvements

- Automated MySQL and world data backups
- Grafana alerting for server downtime or low TPS
- Expand MySQL schema to track more player statistics
- Setup a .env file for easier compose environmental variables management

---

## 📄 License

MIT License
