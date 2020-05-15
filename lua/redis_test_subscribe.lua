local redis = require "resty.redis"
local cjson = require("cjson")  
-- 平台公共的配置文件常量
local config = require ("config_constant")


local red = redis:new()

red:set_timeouts(10000, 10000, 10000) -- 1 sec

local ok, err = red:connect(config.redis.host,config.redis.port)
if not ok then
    ngx.say("1: failed to connect: ", err)
    return
end

local res, err = red:subscribe("dog")
if not res then
    ngx.say("1: failed to subscribe: ", err)
    return
end

ngx.say("1: subscribe: ", cjson.encode(res))


res, err = red:read_reply()
if not res then
    ngx.say("1: failed to read reply: ", err)
    return
end

ngx.say("1: receive: ", cjson.encode(res))

red:close()