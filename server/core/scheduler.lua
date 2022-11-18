-------------------------------------------------------------------------------------------
--  The scheduler is used to deliver something that requires complex logic when the player
--  is offline, so we just wait until the player is online again, filtering by the player_id
--  and deleting by an auto increment id
-------------------------------------------------------------------------------------------
AddEventHandler('hydrus:database-ready', function()
    if not SQL.has_table('hydrus_scheduler') then
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

local lock = {}

function Scheduler.batch(player_id, source)
    if lock[player_id] then
        return
    end
    lock[player_id] = true

    local all = Scheduler.find(player_id)
    if #all > 0 then
        for _, data in ipairs(all) do
            if type(data.args) == 'table' then
                local func = Commands[data.command]
                local ok, err = pcall(func, table.unpack(data.args))
                print_if(not ok, 'Error on schedule: %s %s\n%s', data.command, json.encode(data.args), err)
                Scheduler.delete(data.id)
            else
                printf('Scheduled command %d args isnt a table', data.id)
            end
        end
    end
    pcall(notify_credits, player_id, source)
    lock[player_id] = nil
end

exports('schedule', function(player_id, command, args, ttl)
    if type(command) == 'table' then
        return SQL.insert('hydrus_scheduler', {
            player_id = player_id,
            command = table.remove(command, 1),
            args = json.encode(command),
            execute_at = args and (os.time() + args) or 0,
        })
    end
    return SQL.insert('hydrus_scheduler', {
        player_id = player_id,
        command = command,
        args = json.encode(args),
        execute_at = ttl and (os.time() + ttl) or 0,
    })
end)