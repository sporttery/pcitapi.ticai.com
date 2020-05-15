local online_list={}
if not __terminal_config then
    __terminal_config = loadTerminalConfig(ngx.var.document_root .. "/config.json")
end

for k,v in pairs(__terminal_config) do
    if v.work_status == "START" then
        table.insert( online_list,k )
    end
end

local redis_factory = require('redis_factory')(config.redis) -- import config when construct
local ok, redis = redis_factory:spawn('redis')
local mysqlUtil = require "mysql_factory"

local sql =
    "select ticket_idmsg from Tb_Win_Ticket where prize_flag = 0 and station_Id = 'test' order by insert_Timestamp asc ,ticket_idmsg asc"
local rtn_data={}
rtn_data.code=0
if online_list and type(online_list) ~= "userdata" and #online_list > 0 then
    local res = mysqlUtil:query(sql, config.db)
    if not res then
        rtn_data.code=-1
        rtn_data.msg = "查询失败，请查看日志" .. sql
        ngx.say(cjson.encode(rtn_data));
        ngx.exit(ngx.HTTP_OK);
    end
    -- ngx.say(cjson.encode(res))
    rtn_data.data = res
    rtn_data.count = #res
    local idx = 1
    local dataCount = #res;
    local ticket_arr = {}
    local terminal_arr = {}
    for i, row in ipairs(res) do
        local terminal_no = online_list[idx];
        if not terminal_no then
            idx = 1
            terminal_no = online_list[idx];
        end
        idx = idx + 1
        ticket_arr[i] = row.ticket_idmsg
        terminal_arr[i] = terminal_no
    end
    -- data={}
    -- data["terminal_arr"]=terminal_arr
    -- data["ticket_arr"]=ticket_arr
    -- ngx.say(cjson.encode(data))
    -- ngx.exit(ngx.HTTP_OK)
    terminal_no_arr = {}
    -- rpush("AWARD_NO_" .. terminal_no, ticket)
    for i, terminal_no in ipairs(terminal_arr) do
        if type(terminal_no_arr[terminal_no]) == "table" then
            table.insert(terminal_no_arr[terminal_no], ticket_arr[i])
        else
            terminal_no_arr[terminal_no] = {}
            table.insert(terminal_no_arr[terminal_no], ticket_arr[i])
        end
    end
    -- ngx.say(cjson.encode(terminal_no_arr))
    -- ngx.exit(ngx.HTTP_OK)
    local success_arr={}
    for k, v in pairs(terminal_no_arr) do
        local len = #v
        local res = redis:rpush("AWARD_NO_" .. k, unpack(v))
        if res == len then
            table.insert(v, res)
            for i,ticket in ipairs(v) do
                table.insert(success_arr, ticket)
            end
        else
            table.insert(v, "失败"..res)
        end
    end
    sql = "update Tb_Win_Ticket set prize_flag = -1 where ticket_idmsg in ('"..table.concat(success_arr,"','").."')"
    count = mysqlUtil:query(sql, config.db).affected_rows
    rtn_data.successCount = count
    rtn_data.successData = success_arr
    rtn_data.msg="成功"
    
    ngx.say(cjson.encode(rtn_data))
    redis_factory:destruct()
else
    rtn_data.msg = "没有开启的终端机，请先开启终端机。"
    rtn_data.code = -3
    ngx.say(cjson.encode(rtn_data))
end