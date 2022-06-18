SQL = {}
setmetatable(SQL, SQL)

SQL.drivers = {
    {'oxmysql', function(promise, sql, params)
        promise:resolve(exports.oxmysql:query_async(sql, params))
    end},
    {'ghmattimysql', function(promise, sql, params)
        exports.ghmattimysql:execute(sql, params, function(result)
            promise:resolve(result)
        end)
    end},
    {'GHMattiMySQL', function(promise, sql, params)
        exports.GHMattiMySQL:QueryResultAsync(sql, params, function(result)
            promise:resolve(result)
        end)
    end},
    {'mysql-async', function(promise, sql, params)
        exports['mysql-async']:mysql_fetch_all(sql, params, function(result)
            promise:resolve(result)
        end)
    end}
}

SQL.tables = {}
SQL.columns = {}

function SQL.hasTable(name)
    return SQL.tables[name] ~= nil
end

function SQL.firstTable(...)
    for table in each({ ... }) do
        if SQL.hasTable(table) then
            return table
        end
    end
end

function SQL.hasColumn(table, column)
    if not tables[table] then
        return false
    elseif not SQL.columns[table] then
        SQL.columns = table.reverse(SQL([[
            SELECT column_name AS name FROM information_schema.columns WHERE 
            table_schema = DATABASE() AND table_name=?
        ]], { table }))
    end
    return SQL.columns[table][column] ~= nil
end

function SQL.firstColumn(table, ...)
    for column in each({ ... }) do
        if SQL.hasColumn(table, column) then
            return column
        end
    end
end

local handlers = {}

function SQL.onInsert(table, fn)
    handlers[table] = fn
end

for driver in each(SQL.drivers) do
    if GetResourceState(driver[1]) == 'started' then
        SQL.driver = driver[2]
        logger('Using driver %s', driver[1])
        break
    end
end

function SQL.__call(self, sql, params)
    if SQL.driver then
        logger("SQL: [%s] -> %s", sql, json.encode(params))

        local p = promise.new()
        SQL.driver(p, sql, params or {})
        return Citizen.Await(p) or error('Unexpected sql result from '..script)
    end
    error('Missing compatible SQL driver')
end

function SQL.escape(seq)
    local safe = seq:gsub('`', '')
    return string.format('`%s`', safe)
end

function SQL.insert(table_name, data)
    local columns = {}
    local params = {}

    local context = { table = table_name, data = data }
    if handlers[table_name] then
        handlers[table_name](context)
    end

    for k,v in pairs(context.data) do
        table.insert(columns, SQL.escape(k))
        table.insert(params, v)
    end

    local marks = (',?'):rep(#columns):sub(2)

    local code = string.format("INSERT INTO %s (%s) VALUES (%s)", SQL.escape(context.table), table.concat(columns, ','), marks)

    return SQL(code, params)
end