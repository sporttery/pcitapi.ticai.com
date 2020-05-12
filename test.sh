#bash
#机器列表
ONLINE_LIST="00001 00002"
if [ $# -eq 1 ] ;then
ONLINE_LIST=$1
fi
#模拟上线机器
for v in $(echo $ONLINE_LIST); do
    echo "正在添加$v 上线"
    redis-cli lrem ONLINE_LIST 0 $v
    redis-cli rpush ONLINE_LIST $v
    sleep 1
done
#判断是否开启
while true; do
    for v in $ONLINE_LIST; do
        if [ "$(redis-cli get WORK_STATUS_$v)" = "START" ]; then #如果已经开启
            echo "${v} 处理开启状态"
            sleep 2
            award_no=$(redis-cli lpop AWARD_NO_$v)
            if [ -n "$award_no" ] ; then #如果拿到奖票
                echo ${v}"已经拿到奖票："${award_no}",开始兑奖"
                redis-cli set AWARD_STATUS_$v "${award_no}"
                sleep 1
                echo "模拟正在兑奖"
                sleep 1
                award_time=$(date +'%F %T')
                award_money=$(expr $RANDOM / 1000 + 10)
                echo "兑奖时间：${award_time},中奖金额：${award_money}"
                # award_result="$award_no => CCPOS|2|$award_time|531611324|该票未中奖"
                award_result=$award_no" => CCPOS|2|"${award_time}"|531611324|该票已在"$award_time"时间进行兑奖，兑奖者为"$v"，中奖金额："$award_money"元。"

                redis-cli set AWARD_RESULT_$v "${award_result}"
                echo "兑奖完成，中奖信息:${award_result}"
                redis-cli set AWARD_STATUS_$v "IDLE"
            else
                echo "${v} 没有获取到兑奖号码"
            fi
        else
            echo "${v} 没有开启"
        fi
    done
    echo "选择0.2秒再运行"
    sleep 2
done
