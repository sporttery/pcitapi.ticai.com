local terminal_no = ngx.var.arg_terminal_no
local ticket = ngx.var.arg_ticket
local redis_factory = require('redis_factory')(config.redis) -- import config when construct
local ok, redis = redis_factory:spawn('redis')
local mysqlUtil = require "mysql_factory"

local rtn_data = {}
rtn_data.code = 0
rtn_data.count = 0
rtn_data.data = {}

local function setAwardResult(award_result,terminal_no)
    data = {}
    if award_result then
        award_no = split(award_result, " ")[1];
        award_result_arr = split(award_result, "|");
        award_result_info = award_result_arr[#award_result_arr]
        award_time = award_result_arr[3]
        award_money = award_result_info:match("中奖金额：(%d+)元")
        prize_flag = 1
        if not award_money then
            prize_flag = 4
            award_money = -1
        else
            award_money = award_money .. "00"
        end
        sql = "update Tb_Win_Ticket set msg='" .. award_result_info ..
                "', prize_flag=" .. prize_flag .. ",prize_value=" .. award_money ..
                ",prize_timestamp='" .. award_time .. "',PRIZE_UNIT_ID='" .. terminal_no ..
                "' where ticket_idmsg='" .. award_no .. "';"
        -- count = mysqlUtil:query(sql, config.db).affected_rows
        res,err = mysqlUtil:query(sql, config.db)
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
        if count > 0 then
            rtn_data.count = rtn_data.count  + 1
            data.msg = "成功"
            delRes = redis:del("AWARD_RESULT_" .. terminal_no)
            data.delRes = delRes
        end
    else
        data = {}
        data.msg = "成功"
        data.info="db"
        rtn_data.count = rtn_data.count  + 1
    end
    table.insert(rtn_data.data, data)
end


function getAwardResult(terminal_arr)
    local keys={}
    for i,terminal_no in ipairs(terminal_arr) do
        table.insert( keys, "AWARD_RESULT_" .. terminal_no )
    end
    local award_results = redis:mget(unpack(keys))
    for i,v in ipairs(award_results) do
        terminal_no = terminal_arr[i]
        award_result = v
        if award_result and type(award_result) ~= "userdata" and
        string.len(award_result) > 35 then
            setAwardResult(award_result,terminal_no)
        else
            setAwardResult(nil,terminal_no)
        end
    end
end

terminal_arr = {}
if not terminal_no then
    if not __terminal_config then
        __terminal_config = loadTerminalConfig(ngx.var.document_root .. "/config.json")
    end
    for k,v in pairs(__terminal_config) do
        if v.work_status == "START" then
            table.insert(terminal_arr,k)
        end
    end
    
else
    table.insert(terminal_arr,terminal_no)
end
if #terminal_arr > 0 then
    getAwardResult(terminal_arr)
    redis_factory:destruct()
else
    rtn_data.code=-3;
    rtn_data.msg = "没有开启的终端机，请先开启终端机。";
end

ngx.say(cjson.encode(rtn_data))

