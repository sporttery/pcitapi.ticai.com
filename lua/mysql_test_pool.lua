-- 平台公共的配置文件常量
local config = require ("config_constant")

-- mysql连接池
local mysqlUtil = require "mysql_factory"

local cjson = require("cjson")

local request_method = ngx.var.request_method
local args = nil
-- 获取参数的值
if "GET" == request_method then
    args = ngx.req.get_uri_args()
elseif "POST" == request_method then
    ngx.req.read_body()
    args = ngx.req.get_post_args()
    if (args == nil or args.data == null) then args = ngx.req.get_uri_args() end
end

-- 前端传递的id
local id = args.id

-- 组装sql语句
local sql_get_all_ticket =
    "select id,ticket_idmsg from Tb_Win_Ticket where station_Id = 'test' order by insert_Timestamp asc limit 10"

ngx.say(cjson.encode(config.db));
-- 执行sql语句
res, errmsg, errno, sqlstate = mysqlUtil:query(sql_get_all_ticket, config.db);
if not res then
    ngx.say("select error : ", err, " , errno : ", errno, " , sqlstate : ",
            sqlstate)
else
        ngx.say(cjson.encode(res));

end


