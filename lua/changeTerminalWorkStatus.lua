local terminal_no = ngx.var.arg_terminal_no;
local work_status = ngx.var.arg_work_status;

local redis_factory = require('redis_factory')(config.redis) -- import config when construct
local ok, redis = redis_factory:spawn('redis')

local rtn_data = {}
if terminal_no then
    if not __terminal_config then
        __terminal_config = loadTerminalConfig(ngx.var.document_root .. "/config.json")
    end
    local status = redis:hget("TERMINAL_LIST" ,terminal_no)
    local work_status 
    rtn_data.code = 0
    if type(status) == "userdata" or status ~= "ONLINE" then
        rtn_data.code = -2
        rtn_data.msg = "终端机并没上线"
        work_status = "STOP"
    else
        if work_status == "START" then
            work_status = "STOP"
        else
            work_status = "START"
        end
    end
    msg = redis:set("WORK_STATUS_" .. terminal_no, work_status)
    if msg == "OK" then
        if __terminal_config[terminal_no] then
            __terminal_config[terminal_no].work_status = work_status
        end
        if rtn_data.code == 0 then
            rtn_data.msg = work_status .. " 操作成功"
        end
    end
    redis_factory:destruct()
else
    rtn_data.code = -1
    rtn_data.msg = "参数异常"
end

ngx.say(cjson.encode(rtn_data))
