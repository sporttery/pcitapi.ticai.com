local redis = require "resty.redis"
-- local redis = require "redis"
local cjson = require("cjson")  

-- luarocks install luasql-mysql MYSQL_DIR=/usr/local/Cellar/mysql@5.7/5.7.29 MYSQL_INCDIR=/usr/local/Cellar/mysql@5.7/5.7.29/include/mysql
-- luarocks install luasql-redis
-- luarocks install redis-lua
local red = redis:new()

red:set_timeouts(10000, 10000, 10000) -- 1 sec

local ok, err = red:connect("127.0.0.1",6379)
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