
local redis = require "resty.redis"
local red = redis:new()

local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
	ngx.say("failed to connect: ", err)
	return
end



--用于接收前端数据的对象
local args=nil
--获取前端的请求方式 并获取传递的参数   
local request_method = ngx.var.request_method
--判断是get请求还是post请求并分别拿出相应的数据
if"GET" == request_method then
        args = ngx.req.get_uri_args()
elseif "POST" == request_method then
        ngx.req.read_body()
        args = ngx.req.get_post_args()
        --兼容请求使用post请求，但是传参以get方式传造成的无法获取到数据的bug
        if (args == nil or args.data == null) then
                args = ngx.req.get_uri_args()
        end
end

--获取前端传递的key
local key = args.key
local value
local action=args.action
if not action then
	action = "get"
else 
	value = args.value or ""
end

ngx.say(package.path.."</br>");
ngx.say(package.cpath.."</br>");

if action == "get" then
	--在redis中获取key对应的值
	local va = red:get(key)
	--响应前端
	ngx.say('{"action":"get","key":"'..key..'","result":"'..va..'"}')
elseif action == "lrange" then
	local va = red:lrange(key,0,-1)
	if va then
		for i,v in ipairs(va) do
			ngx.say('{"action":"lrange","key":"'..key..'","result['..i..']":"'..v..'"}</br>')
		end
	else
		ngx.say('{"action":"lrange","key":"'..key..'","result":"null"}')
	end
else
	local va = red:set(key,value)
	ngx.say('{"action":"set","key":"'..key..'","value":"'..value..'","result":"'..va..'"}')
end
red:set_keepalive(10000, 100)