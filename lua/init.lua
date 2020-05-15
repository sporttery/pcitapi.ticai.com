cjson = require("cjson")
-- 平台公共的配置文件常量
config = require("config_constant")

split = function(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == '') then return false end
    local pos, arr = 0, {}
    -- for each divider found
    for st, sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

getPage = function(arg_page)
    local page = arg_page or "1"
    page = tonumber(page)

    if not page then page = 1 end
    return page;
end

getLimit = function(arg_limit)
    local limit = arg_limit or "10"
    limit = tonumber(limit)

    if not limit then limit = 10 end
    return limit
end

clone = function(object)
    local lookup_table = {}
    local function copyObj(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end

        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[copyObj(key)] = copyObj(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return copyObj(object)
end

__terminal_config = nil
loadTerminalConfig = function(configPath)
    file = io.open(configPath, "r")
    __terminal_config = cjson.decode(file:read("all"))
    file:close()
    return __terminal_config
end


