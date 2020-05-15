-- 用于接收前端数据的对象
local args = nil
-- 获取前端的请求方式 并获取传递的参数   
local request_method = ngx.var.request_method
-- 判断是get请求还是post请求并分别拿出相应的数据
if "GET" == request_method then
    args = ngx.req.get_uri_args()
elseif "POST" == request_method then
    ngx.req.read_body()
    args = ngx.req.get_post_args()
end
local rtn_data = {}
rtn_data.args = args
local terminal_no = args.terminal_no
local ticket = args.ticket

rtn_data.code = 0
if terminal_no and ticket then
    local redis_factory = require('redis_factory')(config.redis) -- import config when construct
    local ok, redis = redis_factory:spawn('redis')
    local ticket_arr = split(ticket, ",");
    local terminal_arr = split(terminal_no, ",");
    rtn_data.ticket_arr = ticket_arr
    rtn_data.terminal_arr = terminal_arr
    rtn_data.ticket = ticket
    rtn_data.terminal_no = terminal_no
    terminal_no_arr = {}
    -- rpush("AWARD_NO_" .. terminal_no, ticket)
    for i, v in ipairs(terminal_arr) do
        if type(terminal_no_arr[v]) == "table" then
            table.insert(terminal_no_arr[v], ticket_arr[i])
        else
            terminal_no_arr[v] = {}
            table.insert(terminal_no_arr[v], ticket_arr[i])
        end
    end
    rtn_data.terminal_no_arr = terminal_no_arr

    for k, v in pairs(terminal_no_arr) do
        local res = redis:rpush("AWARD_NO_" .. k, unpack(v))
        table.insert(v, res)
    end
    rtn_data.msg = "OK"
    rtn_data.data = terminal_no_arr
    redis_factory:destruct()
else
    rtn_data.msg = "参数错误"
end
ngx.say(cjson.encode(rtn_data))

