function generate_plate(table, column)
    local chars = 'QWERTYUIOPASDFGHJKLZXCVBNM'
    local nums = '0123456789'
    
    local plate = string.gsub(ENV.plate_format or 'DDLLLDDD', '[DL]', function(letter)
        local all = letter == 'D' and nums or chars
        local index = math.random(#all)
        return all:sub(index, index)
    end)

    -- Check if the plate already exists on the database
    if #SQL.silent(sprint('SELECT 1 FROM %s WHERE %s=?', table, column), { plate }) > 0 then
        return generate_plate(table, column)
    end

    return plate
end