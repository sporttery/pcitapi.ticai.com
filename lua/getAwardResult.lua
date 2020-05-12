if ngx.var.use_timer == "true" or use_timer then
    ngx.say("{\"code\":100,\"msg\":\"后台定时任务在执行\"}")
    ngx.exit(ngx.HTTP_OK);
end
local terminal_no = ngx.var.arg_terminal_no
local arr
if terminal_no and string.len(terminal_no) > 0 then
    arr = split(terminal_no,",")
else
    arr = getOnlineList()
end
local rtn_data={}
rtn_data.code=0
if arr and type(arr) ~= "userdata" and #arr > 0 then
    rtn_data.data={}
    for i,v in ipairs(arr) do
        award_result = getAwardResult(v)
        if award_result and type(award_result) ~= "userdata" and string.len(award_result) > 35 then
            award_no = split(award_result, " ")[1];
            award_result_arr = split(award_result, "|");
            award_result_info = award_result_arr[#award_result_arr]
            award_time = award_result_arr[3]
            award_money = award_result_info:match("中奖金额：(%d+)元")
            prize_flag = 1
            if not award_money then
                prize_flag = 2
                award_money = -1
            else
                award_money = award_money .. "00"
            end
            sql = "update Tb_Win_Ticket set msg='" .. award_result_info ..
                    "', prize_flag=" .. prize_flag .. ",prize_value=" .. award_money ..
                    ",prize_timestamp='" .. award_time .. "',PRIZE_UNIT_ID='" .. v ..
                    "' where ticket_idmsg='" .. award_no .. "';"
            count = dbQuery(sql).affected_rows
            data={}
            data.award_no=award_no
            data.info=award_result_info
            data.prize_flag=prize_flag
            data.prize_value=award_money
            data.prize_timestamp=award_time
            data.PRIZE_UNIT_ID=v
            if count >0 then
                data.msg = "成功"
            else
                data.msg="更新失败"
            end
            table.insert( rtn_data.data,data )
        end
    end
else
    rtn_data.code=-1
    rtn_data.msg="没有发现在线终端机"
end
ngx.say(cjson.encode(rtn_data))