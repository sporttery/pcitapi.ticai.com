local terminal_no = ngx.var.arg_terminal_no
local ticket = ngx.var.arg_ticket
local rtn_data = {}
rtn_data.code = 0
if terminal_no and ticket and string.len(ticket) == 31 and string.len(terminal_no) > 0 then
    rtn_data.msg = addAwardTicket(terminal_no, ticket)
    rtn_data.data={}
    rtn_data.data.terminal_no=terminal_no
    rtn_data.data.ticket=ticket
else
    rtn_data.msg = "错误的参数"
end
ngx.say(cjson.encode(rtn_data))

