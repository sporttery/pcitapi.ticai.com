local terminal_no = ngx.var.arg_terminal_no;
local rtn_data={}
if terminal_no then
    local status = getWorkStatus(terminal_no)
    if status == "START" then
        status="STOP"
    else
        status="START"
    end
    rtn_data.msg=setWorkStatus(terminal_no,status)
    rtn_data.code=0
else
    rtn_data.code=-1
    rtn_data.msg="参数异常"
end

ngx.say(cjson.encode(rtn_data))