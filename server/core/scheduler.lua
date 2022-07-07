-------------------------------------------------------------------------------------------
--  The scheduler is used to deliver something that requires complex logic when the player
--  is offline, so we just wait until the player is online again, filtering by the player_id
--  and deleting by an auto increment id
-------------------------------------------------------------------------------------------
AddEventHandler('hydrus:database-ready', function()
    if not SQL.hasTable('hydrus_scheduler') then
        SQL([[CREATE TABLE hydrus_scheduler (
            id BIGINT NOT NULL AUTO_INCREMENT,
            player_id VARCHAR(100) NOT NULL,
            command VARCHAR(100) NOT NULL,
            args VARCHAR(4096) NOT NULL,
            execute_at BIGINT DEFAULT 0,
            PRIMARY KEY(id)
        )]])
        SQL('CREATE INDEX player_index ON hydrus_scheduler(player_id)')

        local memcache = json.decode(LoadResourceFile(script_name, 'database/scheduler.json') or '{}')

        for item in each(memcache) do
            if item.identifier then
                SQL.insert('hydrus_scheduler', {
                    player_id = item.identifier,
                    command = item.command,
                    args = json.encode(item.args),
                })
            end
        end

        SaveResourceFile(script_name, 'database/scheduler.json', '{}', -1)
    end
end)

Scheduler = {}

function Scheduler.new(identifier, command, ...)
    SQL.insert('hydrus_scheduler', {
        player_id = identifier,
        command = command,
        args = json.encode({ ... }),
    })
end

function Scheduler.find(identifier)
    local rows = SQL('SELECT * FROM hydrus_scheduler WHERE player_id=? AND execute_at<=?', { identifier, os.time() })
    return table.map(rows, function(item)
        item.args = json.decode(item.args)
        return item
    end)
end

function Scheduler.delete(id)
    SQL('DELETE FROM hydrus_scheduler WHERE id=?', { id })
end

exports('schedule', function(player_id, command, args, ttl)
    if type(command) == 'table' then
        command = table.concat(command, ' ')
    end
    return SQL.insert('hydrus_scheduler', {
        player_id = player_id,
        command = command,
        args = json.encode(args),
        execute_at = ttl and (os.time() + ttl) or 0,
    })
end)