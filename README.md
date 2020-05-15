# pcitapi.ticai.com

# 自動兌獎掃碼控制端
    需要安装 redis,openresty
    addAwardTicket.lua 添加票号给终端机兑奖
    changeTerminalWorkStatus.lua 修改终端机的工作状态
    getAwardResult.lua 获取兑奖结果
    getData.lua 从远端数据库获取要兑奖的数据写入redis
    getTerminal.lua 获取终端机列表及工作状态
    getWaitingTicket.lua 获取等待兑奖的列表
    getWinTicket.lua 获取远端数据库里的兑奖表数据
    mysql_test.lua 测试远端数据库连接
    redis_test.lua 测试 redis连接
    test.lua 测试逻辑脚本
    www.pcitapi.ticai.com.conf 配置脚本 ，include www.pcitapi.ticai.com.conf 放入nginx.conf中
    index.html 控制端界面
    index.js 控制端脚本
    award_scan_test_redis_v1.2 模拟彩票机出票
    crontab.sh 定时任务脚本
    
# 自动兑奖彩票机端 见 ticai 项目