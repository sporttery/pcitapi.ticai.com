cjson = require("cjson")
-- 平台公共的配置文件常量
config = require("config_constant")

split = function(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == "") then
        return false
    end
    local pos, arr = 0, {}
    -- for each divider found
    for st, sp in function()
        return string.find(input, delimiter, pos, true)
    end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

getPage = function(arg_page)
    local page = arg_page or "1"
    page = tonumber(page)

    if not page then
        page = 1
    end
    return page
end

getLimit = function(arg_limit)
    local limit = arg_limit or "10"
    limit = tonumber(limit)

    if not limit then
        limit = 10
    end
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
    local redis_factory = require("redis_factory")(config.redis) -- import config when construct
    local ok, redis = redis_factory:spawn("redis")
    local terminal_no_arr = {}
    for k, v in pairs(__terminal_config) do
        table.insert(terminal_no_arr, "PWD1_" .. k)
        table.insert(terminal_no_arr, v.pwd1)
        table.insert(terminal_no_arr, "PWD2_" .. k)
        table.insert(terminal_no_arr, v.pwd2)
        if v.autoStart and v.autoStart == "on" then
            local status = redis:hget("TERMINAL_LIST" ,k)
            local work_status 
            if type(status) == "userdata" or status ~= "ONLINE" then
                work_status = "STOP"
            else
                work_status = "START"
            end
            table.insert(terminal_no_arr, "WORK_STATUS_" .. k)
            table.insert(terminal_no_arr, work_status)
            __terminal_config[k]["WORK_STATUS"] = work_status
        end
    end
    redis:mset(unpack(terminal_no_arr))
    redis_factory:destruct()
    return __terminal_config
end

saveAwardResult = function(award_result, terminal_no)
    local data = {}
    local redis_factory = require("redis_factory")(config.redis) -- import config when construct
    local ok, redis = redis_factory:spawn("redis")
    local mysqlUtil = require "mysql_factory"
    award_no = split(award_result, " ")[1]
    award_result_arr = split(award_result, "|")
    award_result_info = award_result_arr[#award_result_arr]
    award_time = award_result_arr[3]
    award_money = award_result_info:match("中奖金额：(%d+)元")
    PRIZE_UNIT_ID = terminal_no
    prize_flag = 1
    if not award_money then
        prize_flag = 4
        award_money = -1
    else
        -- award_result_info="该票已在2020-06-09 11:52:50时间进行兑奖，兑奖者为4601070000，中奖金额：20元。(611324)"
        award_time = award_result_info:match("该票已在(.+)时间")
        -- PRIZE_UNIT_ID = award_result_info:match("兑奖者为(%d+)，")
        award_money = award_money .. "00"
    end
    sql =
        "update Tb_Win_Ticket_V2 set msg='" ..
        award_result_info ..
            "', prize_flag=" ..
                prize_flag ..
                    ",prize_value=" ..
                        award_money ..
                            ",prize_timestamp='" ..
                                award_time ..
                                    "',PRIZE_UNIT_ID='" .. PRIZE_UNIT_ID .. "' where ticket_idmsg='" .. award_no .. "';"
    
    res, err = mysqlUtil:query(sql, config.db)
    count = 0

    if res then
        count = res.affected_rows
    else
        data.msg = err
    end
    data.dbres = res
    data.dberr = err
    data.award_no = award_no
    data.info = award_result_info
    data.prize_flag = prize_flag
    data.prize_value = award_money
    data.prize_timestamp = award_time
    data.PRIZE_UNIT_ID = terminal_no
    data.count = count
    if count > 0 then
        data.msg = "成功"
        delRes = redis:del("AWARD_RESULT_" .. terminal_no)
        setRes = redis:set("AWARD_STATUS_" .. terminal_no,"IDLE")
        data.delRes = delRes
        data.setRes = setRes
    end
    return data;
end
