local terminal_no = ngx.var.arg_terminal_no
local arr = split(terminal_no, ",")
local page = getPage(ngx.var.arg_page)
local limit = getLimit(ngx.var.arg_limit)
local redis_factory = require('redis_factory')(config.redis) -- import config when construct
local ok, redis = redis_factory:spawn('redis')

local rtn_data = {}
rtn_data.code = 0
rtn_data.msg = "成功"
rtn_data.count = 0
count = 0
-- min = (page - 1) * limit
-- max = page * limit
min = 0
max = 100000
if #arr > 0 then
    tdata = {}
    for i, v in ipairs(arr) do
        awardList = redis:lrange("AWARD_NO_" .. v, 0, -1)
        if awardList and #awardList > 0 then
            rtn_data.count = rtn_data.count + #awardList
            for i1, v1 in ipairs(awardList) do
                count = count + 1
                if count > min and count <= max then
                    data = {}
                    data.terminal_no = v
                    data.index = count
                    data.awardNo = v1
                    data.result = ""
                    -- data.awardStatus = getAwardStatus(v1)
                    table.insert(tdata, data)
                end
            end
        end
    end
    if #tdata > 0 then rtn_data.data = tdata end
end
ngx.say(cjson.encode(rtn_data))
redis_factory:destruct() -- important, better call this method on your main function return
