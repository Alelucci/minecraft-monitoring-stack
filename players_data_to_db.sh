#!/bin/bash

# Script to copy some player's data to the static db

# set-up some variables
mysql_credentials=./config/mysql/mysql_credentials.cnf
players_table=./config/mysql/players_table.sql
players_insert=./config/mysql/players_insert.sql
usercache=usercache.json
banned_ips=banned-ips.json
banned_players=banned-players.json
ops=ops.json
whitelist=whitelist.json
db_container=$(docker ps -a --filter name=db- | awk 'NF>1{print $NF}'|tail -n +2)
server_container=$(docker ps -a --filter name=server | awk 'NF>1{print $NF}'|tail -n +2)

function file_ends_with_newline() {
    [[ $(tail -c1 "$1" | wc -l) -gt 0 ]]
}

# Create players table if not exists
echo "Creating players table if not existent..."
docker cp $mysql_credentials $db_container:/mysql_credentials.cnf &>/dev/null
docker cp $players_table $db_container:/players_table.sql &>/dev/null
docker cp $players_insert $db_container:/players_insert.sql &>/dev/null

docker exec $db_container bash -c "mysql --defaults-extra-file=/mysql_credentials.cnf < /players_table.sql"

if ! file_ends_with_newline $usercache;then
    echo "Parsing usercache file"
    sed -i 's/]/]\n/g' $usercache
fi

while read -r line; do
    ip_banned=0
    banned=0
    op=0
    whitelisted=0
    time_since_rest=0
    total_world_time=0
    leave_game=0
    play_time=0
    time_since_death=0

    # Get player data from usercache file
    username=$(echo $line | awk -F'"name":' '{print$2}' | awk -F',' '{print$1}' | sed 's/"//g' )
    echo "Gathering data for user $username..."
    uuid=$(echo $line | awk -F'"uuid":' '{print$2}' | awk -F',' '{print$1}'| sed 's/"//g' )
    expire_date=$(echo $line | awk -F'"expiresOn":' '{print$2}' | awk -F',' '{print$1}'| sed 's/"//g' | sed 's/}//g' | sed 's/]//g' )

    # Get player data from players folder
    player_stats=./world/players/stats/$uuid.json
    if $(find $player_stats &>/dev/null); then
        time_since_rest=$(awk -F'"minecraft:time_since_rest": ' '{print$2}' $player_stats | awk -F',' 'NF {print$1}' )
        total_world_time=$(awk -F'"minecraft:total_world_time": ' '{print$2}' $player_stats | awk -F',' 'NF {print$1}' )
        leave_game=$(awk -F'"minecraft:leave_game": ' '{print$2}' $player_stats | awk -F',' 'NF {print$1}' )
        play_time=$(awk -F'"minecraft:play_time": ' '{print$2}' $player_stats | awk -F',' 'NF {print$1}' )
        time_since_death=$(awk -F'"minecraft:time_since_death": ' '{print$2}' $player_stats | awk -F',' 'NF {print$1}'  )
    fi

    # Get player status from other files
    if grep -w $username $banned_ips &>/dev/null; then ip_banned=1; fi
    if grep -w $username $banned_players &>/dev/null; then banned=1; fi
    if grep -w $username $ops &>/dev/null; then op=1;fi
    if grep -w $username $whitelist &>/dev/null; then whitelisted=1; fi

    # Insert player data in players table
    echo "Copying data to database..."
    docker exec $db_container bash -c "\
        mysql --defaults-extra-file=/mysql_credentials.cnf -e '
            INSERT INTO players VALUES (
                \"$username\",
                \"$uuid\",
                \"$expire_date\",
                \"$time_since_rest\",
                \"$total_world_time\",
                \"$leave_game\",
                \"$play_time\",
                \"$time_since_death\",
                \"$banned\",
                \"$ip_banned\",
                \"$whitelisted\",
                \"$op\"
            ) ON DUPLICATE KEY UPDATE 
                expire_date=\"$expire_date\",
                time_since_rest=\"$time_since_rest\",
                total_world_time=\"$total_world_time\",
                leave_game=\"$leave_game\",
                play_time=\"$play_time\",
                time_since_death=\"$time_since_death\",
                banned=\"$banned\",
                ip_banned=\"$ip_banned\",
                whitelisted=\"$whitelisted\",
                op=\"$op\"
        '
    "
    docker exec $db_container bash -c "rm /mysql_credentials.cnf /players_table.sql /players_insert.sql"

done < $usercache
