award_result =
    "3605850000052190201659707032542 => CCPOS|2|2020-05-09 14:31:27|531611324|该票未中奖"
    -- "3605850000052190201659707032542 => CCPOS|2|2020-05-09 14:31:27|531611324|该票已在2020-05-09 14:22:55时间进行兑奖，兑奖者为4601070000，中奖金额：10元。"

function split(input, delimiter)
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
print("当前时间：" .. os.date("%Y-%m-%d %H:%M:%S", os.time()))
award_no = split(award_result, " ")[1];
award_result_arr = split(award_result, "|");
award_result_info = award_result_arr[#award_result_arr]
award_time = award_result_arr[3]
award_money = award_result_info:match("中奖金额：(%d+)元")
prize_flag = 1
v = "4601070000"
if not award_money then
    prize_flag = 2
    award_money = -1
end
print(award_result);
print(award_no);
print(award_result_info);
print(award_time);
print(award_money);

local sql = "update Tb_Win_Ticket set msg='" .. award_result_info ..
                "', prize_flag=" .. prize_flag .. ",prize_value=" .. award_money ..
                "00,prize_timestamp='" .. award_time .. "',PRIZE_UNIT_ID='" .. v ..
                "' where ticket_idmsg='" .. award_no .. "';"

print(sql);



