CREATE TABLE IF NOT EXISTS players (
    username VARCHAR(100), 
    uuid VARCHAR(100), 
    expire_date VARCHAR(100), 
    time_since_rest INT, 
    total_world_time INT, 
    leave_game INT, 
    play_time INT, 
    time_since_death INT, 
    banned BOOLEAN DEFAULT 0, 
    ip_banned BOOLEAN DEFAULT 0, 
    whitelisted BOOLEAN DEFAULT 0, 
    op BOOLEAN DEFAULT 0, 
    UNIQUE(username), 
    UNIQUE(uuid)
);
