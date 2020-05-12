local terminal_no = ngx.var.arg_terminal_no
local arr = split(terminal_no, ",")
local page = getPage(ngx.var.arg_page)
local limit = getLimit(ngx.var.arg_limit)
local rtn_data = {}
rtn_data.code = 0
rtn_data.msg = "成功"
rtn_data.count = 0
count = 0
min = (page - 1) * limit
max = page * limit
if #arr > 0 then
    tdata = {}
    for i, v in ipairs(arr) do
        awardList = getAwardList(v)
        -- ngx.log(ngx.ERR, "v=", v, " list=", cjson.encode(awardList))
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
