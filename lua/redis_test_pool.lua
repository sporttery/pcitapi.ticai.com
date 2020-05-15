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
    -- 兼容请求使用post请求，但是传参以get方式传造成的无法获取到数据的bug
    if (args == nil or args.data == null) then args = ngx.req.get_uri_args() end
end
local cjson = require("cjson")
-- 平台公共的配置文件常量
local config = require ("config_constant")

local redis_factory = require('redis_factory')(config.redis) -- import config when construct
local ok, redis = redis_factory:spawn('redis')

-- 获取前端传递的key
local key = args.key
local value
local action = args.action
if not action then
    action = "get"
else
    value = args.value or ""
end
if not key then
    redis:set("foo", ngx.var.document_root)
    key = "foo"
end
-- ngx.say(package.path.."</br>");
-- ngx.say(package.cpath.."</br>");

if action == "get" then
    -- 在redis中获取key对应的值
    local va = redis:get(key)
    -- 响应前端
    ngx.say('{"action":"get","key":"' .. key .. '","result":"' .. va .. '"}')
elseif action == "lrange" then
    local va = redis:lrange(key, 0, -1)
    if va then
        for i, v in ipairs(va) do
            ngx.say('{"action":"lrange","key":"' .. key .. '","result[' .. i ..
                        ']":"' .. v .. '"}</br>')
        end
    else
        ngx.say('{"action":"lrange","key":"' .. key .. '","result":"null"}')
    end
else
    local va = redis:set(key, value)
    ngx.say('{"action":"set","key":"' .. key .. '","value":"' .. value ..
                '","result":"' .. va .. '"}')
end

local val = redis:mget("SUB_AWARD_RESULT_2", "SUB_AWARD_RESULT",
                       "SUB_AWARD_STATUS", "SUB_AWARD_STATUS_1")
ngx.say(cjson.encode(val))

val = redis:mset("AKey","A","BKey","B","CKey","C")
ngx.say(cjson.encode(val))

redis_factory:destruct() -- important, better call this method on your main function return
