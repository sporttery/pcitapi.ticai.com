local page = getPage(ngx.var.arg_page)
local limit = getLimit(ngx.var.arg_limit)
local limitStr = " limit " .. tostring((page - 1) * limit) .. "," ..
                     tostring(limit)
local orderBy = " order by prize_flag asc,insert_timestamp desc "
local whereStr = " where station_Id = 'test'"
local sql = "select count(*) as count from Tb_Win_Ticket " .. whereStr
local count = tonumber(dbQuery(sql)[1].count)
-- ngx.log(ngx.ERR,"共有记录数：",count)
sql =
    "select  id,insert_Timestamp,msg,prize_Flag,prize_value,prize_Unit_Id,prize_Timestamp,station_Id,ticket_idmsg from Tb_Win_Ticket "
sql = sql .. whereStr .. orderBy .. limitStr
res = dbQuery(sql)
local rtn_data = {}
rtn_data.code = 0
rtn_data.msg = ""
rtn_data.count = count
rtn_data.page = page
if not res then
    ngx.log(ngx.ERR, "没有查到数据：", sql)
else
    rtn_data.data = {}
    for i, row in ipairs(res) do table.insert(rtn_data.data, row) end
end
ngx.say(cjson.encode(rtn_data))
