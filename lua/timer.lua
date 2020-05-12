config = {
    redis = {host = '127.0.0.1', port = 6379},

    db = {
        -- host = "120.78.95.34",
        -- port = 3306,
        -- user = "gugule",
        -- password = "%)BMlEj634*I2&Uj",
        -- database = "gugule"
        host = "127.0.0.1",
        port = 3306,
        user = "root",
        password = "123456",
        database = "gugule"
    }
}
cjson = require("cjson")
mysql = require("resty.mysql")
redis = require("resty.redis")

__DEBUG = false
__cache = {}

myDebug = function(...) if __DEBUG then ngx.log(ngx.ERR, ...) end end

myError = function(...) ngx.log(ngx.ERR, ...) end

close_db = function()
    if not db then return end
    db:close()
end

get_db = function()

    db, err = mysql:new()
    if not db then
        myError("new mysql error : ", err)
        return nil
    end

    db:set_timeout(60000)

    res, err, errno, sqlstate = db:connect(config.db)

    if not res then
        myError("connect to mysql error : ", err, " , errno : ", errno,
                " , sqlstate : ", sqlstate, " ,config: ",
                cjson.encode(config.db))
        close_db(db)
        return nil
    end
    return db
end

after_db = function(res, db)
    set_keepalive_time = __cache["db_keepalive"]
    if set_keepalive_time and os.time() - set_keepalive_time < 60 then -- 在缓存范围内
        return res
    end
    __cache["db_keepalive"] = os.time()
    db:set_keepalive(1000 * 60, 100)
    return res
end
get_red = function()

    red = redis:new()

    local ok, err = red:connect(config.redis.host, config.redis.port)
    if not ok then
        myError("failed to connect: ", err, " , config:",
                cjson.encode(config.redis))
        return nil
    end
    return red
end

after_red = function(res, red)
    set_keepalive_time = __cache["red_keepalive"]
    if set_keepalive_time and os.time() - set_keepalive_time < 60 then -- 在缓存范围内
        return res
    end
    __cache["red_keepalive"] = os.time()
    red:set_keepalive(1000 * 60, 100)
    return res
end

redGet = function(key)
    myDebug("redis:get ", key)
    red = get_red()
    res = red:get(key)
    return after_red(res, red)
end

redSet = function(key, val)
    myDebug("redis:set ", key, " ", val)
    red = get_red()
    res = red:set(key, val)
    return after_red(res, red)
end

redDel = function(key)
    myDebug("redis:del ", key)
    red = get_red()
    res = red:del(key)
    return after_red(res, red)
end

dbQuery = function(sql)
    myDebug("mysql: sql ", sql)
    db = get_db()
    res, err, errno, sqlstate = db:query(sql)
    if not res then
        myError("connect to mysql error : ", err, " , errno : ", errno,
                " , sqlstate : ", sqlstate, " ,config: ",
                cjson.encode(config.db), " sql:", sql)
    end
    return after_db(res, db)
end
getWorkStatus = function(v)
    key = "WORK_STATUS_" .. v
    status = redGet(key)
    if not status or status ~= "START" then status = "STOP" end
    return status
end

setWorkStatus = function(v, val)
    key = "WORK_STATUS_" .. v
    return redSet(key, val)
end

getAwardStatus = function(v)
    key = "AWARD_STATUS_" .. v
    status = redGet(key)
    if not status or type(status) == "userdata" or tostring(status) == 'nil' then
        status = "IDLE"
        -- redSet(key,status)
    end
    return status
end

setAwardStatus = function(v, val)
    key = "AWARD_STATUS_" .. v
    return redSet(key, val)
end

addAwardTicket = function(terminal_no, ticket)
    myDebug("redis:rpush AWARD_NO_", terminal_no, " ", ticket)
    red = get_red()
    res = red:rpush("AWARD_NO_" .. terminal_no, ticket)
    return after_red(res, red)
end

getAwardList = function(v)
    myDebug("redis:lrange AWARD_NO_", v, " 0 -1")
    red = get_red()
    res = red:lrange("AWARD_NO_" .. v, 0, -1)
    return after_red(res, red)
end

getAwardResult = function(v) return redGet("AWARD_RESULT_" .. v) end

getOnlineList = function(noCache)
    if not noCache then
        res = __cache["onlinelist"]
        if res and os.time() - res.time < 60 then return res.data end
    end
    myDebug("redis:lrange ONLINE_LIST 0 -1")
    red = get_red()
    res = red:lrange("ONLINE_LIST", 0, -1)
    __cache["onlinelist"] = {}
    __cache["onlinelist"].data = res
    __cache["onlinelist"].time = os.time()

    return after_red(res, red)
end

split = function(input, delimiter)
    input = tostring(input)
    delimiter = tostring(delimiter)
    if (delimiter == '') then return false end
    local pos, arr = 0, {}
    -- for each divider found
    for st, sp in function() return string.find(input, delimiter, pos, true) end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

getPage = function(arg_page)
    local page = arg_page or "1"
    page = tonumber(page)

    if not page then page = 1 end
    return page;
end

getLimit = function(arg_limit)
    local limit = arg_limit or "10"
    limit = tonumber(limit)

    if not limit then limit = 10 end
    return limit
end

task_query_win_ticket_delay = 3
task_query_redis_delay = 1
sql_get_all_ticket =
    "select id,ticket_idmsg from Tb_Win_Ticket where prize_flag = 0 order by insert_Timestamp asc"

local task_query_win_ticket, task_query_redis
task_query_win_ticket = function(premature)
    if not premature then
        myDebug("》》》》》TICKET 运行中 ")
        online_list = getOnlineList()
        if online_list and type(online_list) ~= "userdata" and #online_list > 0 then
            res = dbQuery(sql_get_all_ticket)
            if not res then
                G_err = "查询出错了，查看日志" .. sql_get_all_ticket
                myError(G_err)
                return
            end
            local idx = 1
            for i, row in ipairs(res) do
                local v = online_list[idx];
                if not v then
                    idx = 1
                    v = online_list[idx];
                end
                idx = idx + 1
                if getWorkStatus(v) == "START" then
                    local count = addAwardTicket(v, row.ticket_idmsg)
                    if count > 0 then
                        local sql =
                            "update Tb_Win_Ticket set prize_flag = -1 where id = '" ..
                                row.id .. "'"
                        res1 = dbQuery(sql)
                        if not res then
                            G_err = "更新出错了，查看日志" .. sql
                            myError(G_err)
                            return
                        end
                    end
                end
            end
        else
            myError(
                "没有终端机在线，请先运行redis服务，再开启终端机。");
        end
        myDebug("《《《《《《 TICKET 运行结束 ")
        ngx.timer.at(task_query_win_ticket_delay, task_query_win_ticket)
    end
end

task_query_redis = function(premature)
    if not premature then
        myDebug("》》》》》REDIS 运行中 ")
        online_list = getOnlineList()
        if online_list and type(online_list) ~= "userdata" and #online_list > 0 then
            for i, v in ipairs(online_list) do
                award_result = getAwardResult(v)
                -- ngx.log(ngx.ERR, " award_result:", award_result, " key:", key,
                --         ",type(award_result) ", type(award_result),
                --         " ,tostring(award_result) ", tostring(award_result))
                if award_result and type(award_result) ~= "userdata" and
                    string.len(award_result) > 35 then
                    myError("获取开奖结果 彩票机：", v, " 结果：",
                            award_result)
                    -- 3605850000052190201659707032542 => CCPOS|2|2020-05-09 14:31:27|531611324|该票已在2020-05-09 14:22:55时间进行兑奖，兑奖者为4601070000，中奖金额：10元。(611324)
                    -- 3605850000007920299365683891763 => CCPOS|2|2020-05-10 10:05:33|191606|彩票未中奖(191606)
                    local award_no = split(award_result, " ")[1];
                    local award_result_arr = split(award_result, "|");
                    local award_result_info =
                        award_result_arr[#award_result_arr]
                    award_time = award_result_arr[3]
                    award_money = award_result_info:match(
                                      "中奖金额：(%d+)元")
                    prize_flag = 1
                    if not award_money then
                        prize_flag = 4
                        award_money = -1
                    else
                        award_money = award_money .. "00"
                    end
                    local sql = "update Tb_Win_Ticket set msg='" ..
                                    award_result_info .. "', prize_flag=" ..
                                    prize_flag .. ",prize_value=" .. award_money ..
                                    ",prize_timestamp='" .. award_time ..
                                    "',PRIZE_UNIT_ID='" .. v ..
                                    "' where ticket_idmsg='" .. award_no .. "';"
                    res = dbQuery(sql)
                    if not res then
                        G_err = "更新出错了，查看日志" .. sql
                        myError(G_err)
                        return
                    end
                    redDel("AWARD_RESULT_" .. v)
                end
            end
        else
            myError(
                "没有终端机在线，请先运行redis服务，再开启终端机。");
        end
        myDebug("《《《《《《 REDIS 运行结束 ")
        ngx.timer.at(task_query_redis_delay, task_query_redis)
    end
end

use_timer = false
if 0 == ngx.worker.id() then

    -- 启动时初始化
    local ok_task_query_win_ticket, err_task_query_win_ticket =
        ngx.timer.at(10, task_query_win_ticket)
    if not ok_task_query_win_ticket then
        myError("failed to create timer task_query_win_ticket#",
                err_task_query_win_ticket)
        return
    end
    myError(os.date("%Y-%m-%d %H:%M:%S", ngx.time()) ..
                " : task_query_win_ticket  timer success")

    local ok_task_query_redis, err_task_query_redis =
        ngx.timer.at(5, task_query_redis)
    if not ok_task_query_redis then
        myError("failed to create timer task_query_redis#", err_task_query_redis)
        return
    end
    myError(os.date("%Y-%m-%d %H:%M:%S", ngx.time()) ..
                " : task_query_redis  timer success")
    use_timer = true

end
