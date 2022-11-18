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

function SQL.has_table(name)
    return SQL.tables[name] ~= nil
end

SQL.hasTable = SQL.has_table

function SQL.first_table(...)
    for table in each({ ... }) do
        if SQL.has_table(table) then
            return table
        end
    end
end

SQL.firstTable = SQL.first_table

function SQL.has_column(table, column)
    return SQL.tables[table] and SQL.tables[table][column]
end

SQL.hasColumn = SQL.has_column

function SQL.first_column(table, ...)
    for column in each({ ... }) do
        if SQL.has_column(table, column) then
            return column
        end
    end
end

SQL.firstColumn = SQL.first_column

local handlers = {}

function SQL.on_insert(table, fn)
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
    logger('SQL: [%s] -> %s', sql, json.encode(params))
    return SQL.silent(sql, params)
end

function SQL.silent(sql, params)
    if SQL.driver then
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

function SQL.scalar(sql, params)
    local row = SQL(sql, params)[1] or {}
    return ({next(row)})[2]
end

function SQL.insert(table_name, data, operation)
    local columns = {}
    local params = {}

    local context = { table = table_name, data = data }
    if handlers[table_name] then
        handlers[table_name](context)
    end

    for k,v in pairs(context.data) do
        if SQL.has_column(table_name, k) then
            table.insert(columns, SQL.escape(k))
            table.insert(params, v)
        end
    end

    local marks = (',?'):rep(#columns):sub(2)

    local code = string.format('%s INTO %s (%s) VALUES (%s)', operation or 'INSERT', SQL.escape(context.table), table.concat(columns, ','), marks)

    return SQL(code, params)
end

function SQL.replace(table_name, data)
    return SQL.insert(table_name, data, 'REPLACE')
end