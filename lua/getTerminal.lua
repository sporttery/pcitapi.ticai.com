local terminal_no = ngx.var.arg_terminal_no
local reloadOnlineList = ngx.var.arg_reloadOnlineList
local rtn_data = {}
local redis_factory = require('redis_factory')(config.redis) -- import config when construct
local ok, redis = redis_factory:spawn('redis')

if not __terminal_config or reloadOnlineList then
    __terminal_config = loadTerminalConfig(ngx.var.document_root .. "/config.json")
end

local terminalList
if terminal_no then
    terminalList = {}
    arr = split(terminal_no, ",")
    for i,v in ipairs(arr) do
        if __terminal_config[v] then
            terminalList[v] = __terminal_config[v]
        end
    end
else
    terminalList = clone(__terminal_config)
end
terminal_no_arr = {}
for k, v in pairs(terminalList) do
    table.insert(terminal_no_arr, "WORK_STATUS_" .. k)
    table.insert(terminal_no_arr, "AWARD_STATUS_" .. k)
end
local status_arr = redis:mget(unpack(terminal_no_arr))
rtn_data.status_arr = status_arr
local idx = 1
terminalData = {}
for k, v in pairs(terminalList) do
    local terminal = {}
    terminal.terminal_no = k
    terminal.pwd1 = v.pwd1
    terminal.pwd2 = v.pwd2
    terminal.IP = v.IP or "--"
    if type(status_arr[idx]) == "userdata" then 
        status_arr[idx] = "STOP" 
    end
    terminal.work_status = status_arr[idx]
    idx = idx + 1
    if type(status_arr[idx]) == "userdata" then 
        status_arr[idx] = "IDLE" 
    end
    terminal.award_status = status_arr[idx]
    idx = idx + 1
    __terminal_config[k].work_status = terminal.work_status
    __terminal_config[k].award_status = terminal.award_status
    __terminal_config[k].terminal_no = terminal.terminal_no
    table.insert(terminalData, terminal)
end

table.sort(terminalData , function(a , b)
    return tostring(a.terminal_no) < tostring(b.terminal_no)
end) 

redis_factory:destruct() -- important, better call this method on your main function return


rtn_data.code = 0
rtn_data.msg = "成功"
rtn_data.data = terminalData
rtn_data.count = #terminalData
rtn_data.config = __terminal_config
ngx.say(cjson.encode(rtn_data))
