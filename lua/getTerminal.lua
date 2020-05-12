
local terminal_no = ngx.var.arg_terminal_no
local reloadOnlineList = ngx.var.arg_reloadOnlineList
local rtn_data={}
rtn_data.code=0
if terminal_no then
    rtn_data.msg = "成功"
    data={}
    arr = split(terminal_no,",")
    for i,v in ipairs(arr) do
        data[v]=getAwardStatus(v)
    end
    rtn_data.data = data
else
    online_list = getOnlineList(reloadOnlineList)
    if online_list and type(online_list) ~= "userdata" and #online_list > 0 then
        data={}
        for i,v in ipairs(online_list) do
            data[i]={}
            data[i].terminal_no = v
            data[i].work_status = getWorkStatus(v)
            data[i].index = i
            data[i].award_status = getAwardStatus(v)
        end
        rtn_data.msg = "成功"
        rtn_data.data = data
        rtn_data.count = #online_list
    else
        rtn_data.msg = "没有终端机在线，请先运行redis服务，再开启终端机。"
        rtn_data.code = -3
    end
end
ngx.say(cjson.encode(rtn_data))