local page = getPage(ngx.var.arg_page)
local limit = getLimit(ngx.var.arg_limit)
local field = ngx.var.arg_field
local order = ngx.var.arg_order
local limitStr = " limit " .. tostring((page - 1) * limit) .. "," ..
                     tostring(limit)
--local orderBy = " order by prize_flag asc,case when prize_timestamp = null then insert_timestamp else prize_timestamp end desc , ticket_idmsg asc "
local orderBy = " order by update_time desc , ticket_idmsg asc "
if field and order then
    orderBy = " order by " .. field .." " .. order
end

local mysqlUtil = require "mysql_factory"

-- local whereStr = " where station_Id = 'test'"
local whereStr = " where 1 = 1"

local sql = "select count(*) as count from Tb_Win_Ticket_V2 " .. whereStr


local count = tonumber(mysqlUtil:query(sql, config.db)[1].count)
-- ngx.log(ngx.ERR,"共有记录数：",count)
sql =
    "select  id,insert_Timestamp,msg,prize_Flag,prize_value,prize_Unit_Id,prize_Timestamp,station_Id,ticket_idmsg from Tb_Win_Ticket_V2 "
sql = sql .. whereStr .. orderBy .. limitStr

-- ngx.say(sql)
-- ngx.say("\n")

local mysqlUtil = require "mysql_factory"

local rtn_data = {}
rtn_data.code = 0
rtn_data.msg = ""
rtn_data.count = count
rtn_data.page = page
-- ngx.say(sql);
local res, errmsg, errno, sqlstate = mysqlUtil:query(sql, config.db);
if not res then
    rtn_data.msg = "select error : " .. errmsg .. " , errno : " .. errno ..
                       " ,  sql : " .. sql
    rtn_data.data = {}
else
    -- ngx.say(cjson.encode(res));
    rtn_data.data = {}
    for i, row in ipairs(res) do table.insert(rtn_data.data, row) end
end

ngx.say(cjson.encode(rtn_data))
