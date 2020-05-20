local delay_get_data = 3 --3秒
local delay_get_award = 30 --30秒
local cron_get_data, cron_get_award
--定时任务的函数

cron_get_data = function(premature)
    if not premature then
        -- os.execute("curl -s -m 3 'http://pcitapi.ticai.com/api/getData'")
        local myfile = io.popen("curl -s -m 3 'http://pcitapi.ticai.com/api/getData'","r")
        myfile:close()
        ngx.timer.at(delay_get_data, cron_get_data)
    end
end
cron_get_award = function(premature)
    if not premature then
        -- os.execute("curl -s -m 3 'http://pcitapi.ticai.com/api/getAwardResult'")
        local myfile = io.popen("curl -s -m 3 'http://pcitapi.ticai.com/api/getAwardResult'","r")
        myfile:close()
        ngx.timer.at(delay_get_award, cron_get_award)
    end
end

local ok, err = ngx.timer.at(30, cron_get_data)
if not ok then
    ngx.log(ngx.ERR, "failed to create the timer: ", err)
    return
end

ok, err = ngx.timer.at(30, cron_get_award)
if not ok then
    ngx.log(ngx.ERR, "failed to create the timer: ", err)
    return
end
