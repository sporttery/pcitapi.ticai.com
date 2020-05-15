local mysql = require("resty.mysql")  
 
local mysql_pool = {}  
  
--[[  
    先从连接池取连接,如果没有再建立连接.  
    返回:  
        false,出错信息.  
        true,数据库连接  
--]]  
function mysql_pool:get_connect(cfg)  
    if ngx.ctx[mysql_pool] then  
        return true, ngx.ctx[mysql_pool]  
    end  
  
    local client, errmsg = mysql:new()  
    if not client then  
        return false, "mysql.socket_failed: " .. (errmsg or "nil")  
    end  
  
    client:set_timeout(1000*30)  
  
    -- local options = {  
    --     host = "127.0.0.1",
    --     port = 3306,
    --     user = "root",
    --     password = "123456",
    --     database = "gugule"
    -- }  
  
    local result, errmsg, errno, sqlstate = client:connect(cfg)  
    if not result then  
        return false, "mysql.cant_connect: " .. (errmsg or "nil") .. ", errno:" .. (errno or "nil") ..  
                ", sql_state:" .. (sqlstate or "nil")  
    end  
  
    local query = "SET NAMES " .. "utf8"  
    local result, errmsg, errno, sqlstate = client:query(query)  
    if not result then  
        return false, "mysql.query_failed: " .. (errmsg or "nil") .. ", errno:" .. (errno or "nil") ..  
                ", sql_state:" .. (sqlstate or "nil")  
    end  
  
    ngx.ctx[mysql_pool] = client  
  
    -- 测试，验证连接池重复使用情况  
    --[[ comments by leon1509  
    local count, err = client:get_reused_times()  
    ngx.say("xxx reused times" .. count);  
    --]]  
  
    return true, ngx.ctx[mysql_pool]  
end  
  
--[[  
    把连接返回到连接池  
    用set_keepalive代替close() 将开启连接池特性,可以为每个nginx工作进程，指定连接最大空闲时间，和连接池最大连接数  
 --]]  
function mysql_pool:close()  
    if ngx.ctx[mysql_pool] then  
        -- 连接池机制，不调用 close 而是 keeplive 下次会直接继续使用  
        -- lua_code_cache 为 on 时才有效  
        -- 60000 ： pool_max_idle_time ， 100：connections  
        ngx.ctx[mysql_pool]:set_keepalive(60000, 80)  
        -- 调用了 set_keepalive，不能直接再次调用 query，会报错  
        ngx.ctx[mysql_pool] = nil  
    end  
end  
  
--[[  
    查询  
    有结果数据集时返回结果数据集  
    无数据数据集时返回查询影响  
    返回:  
        false,出错信息,sqlstate结构.  
        true,结果集,sqlstate结构.  
--]]  
function mysql_pool:query(sql, cfg)  
    local ret, client = self:get_connect(cfg)  
    if not ret then  
        return false, client, nil  
    end  
  
    local result, errmsg, errno, sqlstate = client:query(sql)  
  
    while errmsg == "again" do  
        result, errmsg, errno, sqlstate = client:read_result()  
    end  
  
    self:close()  
  
    if not result then  
        errmsg = "mysql.query_failed:" .. (errno or "nil") .. (errmsg or "nil")  
        return false, errmsg, sqlstate  
    end  
  
    return result, errmsg, errno, sqlstate 
end  
  
return mysql_pool