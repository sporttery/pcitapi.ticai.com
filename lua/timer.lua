local delay = 30 --30秒
local delay_get_data = 3 --3秒
local delay_get_award = 30 --30秒
local cron_a, cron_get_data, cron_get_award
--定时任务的函数
cron_a = function(premature)
    if not premature then --如果执行函数时没有传参，则该任务会一直被触发执行
        __terminal_config = loadTerminalConfig("/var/www/pcitapi.ticai.com/config.json")
        for k, v in pairs(__terminal_config) do
            if not v.work_status and v.autoStart == "on" then
                os.execute(
                    "curl -s -m 3 'http://pcitapi.ticai.com/api/changeTerminalWorkStatus?terminal_no=" ..
                        k .. "&work_status=START'"
                )
            end
        end
    end
end
cron_get_data = function(premature)
    if not premature then
        os.execute("curl -s -m 3 'http://pcitapi.ticai.com/api/getData'")
        ngx.timer.at(delay_get_data, cron_get_data)
    end
end
cron_get_award = function(premature)
    if not premature then
        os.execute("curl -s -m 3 'http://pcitapi.ticai.com/api/getAwardResult'")
        ngx.timer.at(delay_get_award, cron_get_award)
    end
end
--隔delay参数值的时间，就执行一次cron_a函数
local ok, err = ngx.timer.at(delay, cron_a)
if not ok then
    ngx.log(ngx.ERR, "failed to create the timer: ", err)
    return
end

local ok, err = ngx.timer.at(30, cron_get_data)
if not ok then
    ngx.log(ngx.ERR, "failed to create the timer: ", err)
    return
end

local ok, err = ngx.timer.at(30, cron_get_award)
if not ok then
    ngx.log(ngx.ERR, "failed to create the timer: ", err)
    return
end
