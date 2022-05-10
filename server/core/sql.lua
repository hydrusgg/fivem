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

for driver in each(SQL.drivers) do
    if GetResourceState(driver[1]) == 'started' then
        SQL.driver = driver[2]
        logger('Using driver %s', driver[1])
        break
    end
end

function SQL.__call(self, sql, params)
    if SQL.driver then
        local p = promise.new()
        SQL.driver(p, sql, params or {})
        return Citizen.Await(p) or error('Unexpected sql result from '..script)
    end
    error('Missing compatible SQL driver')
end

function SQL.escape(seq)
    return '`' .. seq .. '`'
end

function SQL.insert(table_name, data)
    local columns = {}
    local params = {}

    for k,v in pairs(data) do
        table.insert(columns, SQL.escape(k))
        table.insert(params, v)
    end

    local marks = (',?'):rep(#columns):sub(2)

    local code = string.format("INSERT INTO %s (%s) VALUES (%s)", SQL.escape(table_name), table.concat(columns, ','), marks)

    return SQL(code, params)
end