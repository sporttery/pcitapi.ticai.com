if ngx.var.use_timer == "true" or use_timer then
    ngx.say("{\"code\":100,\"msg\":\"后台定时任务在执行\"}")
    ngx.exit(ngx.HTTP_OK);
end

online_list = getOnlineList()
local rtn_data={}
rtn_data.code=0
if online_list and type(online_list) ~= "userdata" and #online_list > 0 then
    sql = sql_get_all_ticket
    res = dbQuery(sql)
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
    for i, row in ipairs(res) do
        local v = online_list[idx];
        if not v then
            idx = 1
            v = online_list[idx];
        end
        idx = idx + 1
        
        if getWorkStatus(v) == "START" then
            local count = addAwardTicket( v, row.ticket_idmsg)
            if count > 0 then
                sql = "update Tb_Win_Ticket set prize_flag = -1 where id = '" ..
                          row.id .. "'"
                res1 = dbQuery(sql)
                -- ngx.log(ngx.ERR,"v=",v,",award=",row.ticket_idmsg,",res1=",res1, ",type(res1),",type(res1))
                if not res1 then
                    rtn_data.code=-2
                    rtn_data.msg = "更新失败，请查看日志" .. sql
                    ngx.say(cjson.encode(rtn_data));
                    ngx.exit(ngx.HTTP_OK);
                end
            end
        end
    end
    rtn_data.msg="成功"
    
    ngx.say(cjson.encode(rtn_data))
else
    rtn_data.msg = "没有终端机在线，请先运行redis服务，再开启终端机。"
    rtn_data.code = -3
    ngx.say(cjson.encode(rtn_data))
end
