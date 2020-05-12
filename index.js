
var terminalTable, winTicketTable, waitingTicketTable, workList = [],
    workListEl = {},
    waitingTicketList = {},
    terminalArr = [];
var waitingTicketTableFlag, table, loadTerminalAwardStatusFlag;
function getData() {
    layui.$.get("/api/getData", function (d) {
        if (d.code == 100) {
            console.log(d.msg);
            getData = function () { }
            return;
        }
        if (d.data && d.data.length > 0) {
            loadTerminalAwardStatusDelay = 1000
        } else {
            loadTerminalAwardStatusDelay = 2000
        }
        setTimeout(getData, getDataDelay);
    })
}
setTimeout(getData, getDataDelay);
//修改彩票机的工作状态
function changeTerminalWorkStatus(terminal_no) {
    layui.$.get("/api/changeTerminalWorkStatus?terminal_no=" + terminal_no,
        function (d, index) {
            if (d.code == 0) {
                workList = [];
                workListEl = {};
                terminalTable.reload();
            }
        });
}
//手工添加兑奖传入后台
function doAddAwardTicket(ticket, terminal_no) {
    layui.$.get("/api/addAwardTicket?terminal_no=" + terminal_no + "&ticket=" + ticket,
        function (d) {
            console.log(d)
        })
}
function addAwardTicketAll() {
    if (workList.length == 0) {
        alert("没有工作中的机器");
        return;
    }
    checkboxData = table.checkStatus('winTicket')
    if (checkboxData.data.length > 0) {
        var k = 0;
        for (var i = 0; i < checkboxData.data.length; i++) {
            var terminal_no = workList[k++];
            if (!terminal_no) {
                k = 0;
                terminal_no = workList[k++];
            }
            doAddAwardTicket(checkboxData.data[i].ticket_idmsg, terminal_no);
        }
        waitingTicketTable.reload();
        winTicketTable.reload();
    } else {
        alert("请先至少选择一条记录");
    }

}
//手工添加兑奖终端机选择
function addAwardTicket(ticket, terminal_no) {
    if (!terminal_no) {
        var html = ['<div style="padding: 50px; line-height: 22px; background-color: #393D49; color: #fff; font-weight: 300;">'];
        html.push("选择彩票机：<select id=\"_sel_terminal_no\">");
        html.push('<option value="0">请选择</option>');
        for (var i = 0; i < terminalArr.length; i++) {
            text = "暂停状态"
            if (terminalArr[i]["work_status"] == "START") {
                text = "开启状态"
            }
            html.push('<option value="' + terminalArr[i].terminal_no + '">' + terminalArr[i].terminal_no + '&nbsp;&nbsp;&nbsp;' + text + '</option>')
        }
        html.push('</select><br/></html>');
        layer.open({
            type: 1,
            title: false //不显示标题栏
            ,
            closeBtn: false,
            area: '360px;',
            shade: 0.8,
            id: 'LAY_layuipro' //设定一个id，防止重复弹出
            ,
            btn: ['确认', '取消'],
            btnAlign: 'c',
            moveType: 1 //拖拽模式，0或者1
            ,
            content: html.join(""),
            success: function (layero) {
                var btn = layero.find('.layui-layer-btn');
                btn.find('.layui-layer-btn0').attr({
                    href: 'javascript:void(0)',
                    onclick: 'addAwardTicket("' + ticket + '",1)'
                });
            }
        });
    } else if (terminal_no == 1) {
        var terminal_no = layui.$("#_sel_terminal_no").val();
        if (terminal_no != "0") {
            doAddAwardTicket(ticket, terminal_no);
        } else {
            alert("terminal_no 没有选择");
        }
    } else {
        alert("参数错误");
    }
}
function reloadTable(table) {
    table.config.url = table.config.url.replace(/reloadOnlineList=1/g, '') + 'reloadOnlineList=1';
    table.reload();
}
//定时刷新兑奖结果
function getAwardResult(terminal_no) {
    layui.$.get("/api/getAwardResult?terminal_no=" + terminal_no,
        function (d) {
            if (d.code == 100) {
                getAwardResultMsg = d.msg
                console.log(getAwardResultMsg);
                getAwardResult = function () {
                    console.log("getAwardResult:" + getAwardResultMsg)
                    winTicketTable.reload();
                    waitingTicketTable.reload();
                    setTimeout(() => {
                        winTicketTable.reload();
                        waitingTicketTable.reload();
                    }, 500);
                }
                return;
            }
            if (d.code != 0) {
                console(d.msg);
            } else {
                for (var i = 0; i < d.data.length; i++) {
                    data = d.data[i];
                    if (waitingTicketList[data.award_no]) {
                        waitingTicketList[data.award_no].find("td:last").text(data.info)
                    }
                }
                if (d.data.length > 0) {
                    waitingTicketTable.reload();
                    winTicketTable.reload();
                }
            }
        }).fail(function () {
            getAwardResult(terminal_no);
        });
}

//加载彩票机的兑奖状态
function loadTerminalAwardStatus(fail) {
    if (workList.length > 0) {
        terminal_no = workList.join(",");
        layui.$.get("/api/getTerminal?terminal_no=" + terminal_no,
            function (d) {
                var arrs = [];
                for (var key in d.data) {
                    val = d.data[key];
                    if (val == "IDLE") {
                        text = "空闲";
                        color = "green";
                    } else {
                        text = "正在兑奖 <b style='color:red'>票号：" + val + "</b>";
                        color = "blue";
                        if (waitingTicketList[val]) {
                            waitingTicketList[val].toggleClass("red");
                            //1秒后删除此行
                            setTimeout(function () {
                                if (waitingTicketList[val]) {
                                    waitingTicketList[val].remove();
                                    delete waitingTicketList[val];
                                }
                            }, 1000)
                        }
                        arrs.push(key);
                    }
                    el = workListEl[key];
                    if (!el) {
                        el = layui.$("#award_status_" + key);
                        workListEl[key] = el;
                    }
                    el.css("color", color).html(text)
                }
                if (arrs.length > 0) {
                    //如果有正在兑奖状态,2秒后刷新中奖结果
                    setTimeout(getAwardResult, 2000, arrs.join(","));
                    //2秒重新加载待兑奖列表
                    // setTimeout(function () { 
                    //   waitingTicketTable.reload(); 
                    // }, loadWaitingTicketDelay);
                }
            }).fail(function () {
                loadTerminalAwardStatus(1);
                return;
            });
    }
    if (fail === 1) {
        console.log("这个是错误重试调用的方法，只执行一次");
    } else {
        clearTimeout(loadTerminalAwardStatusFlag)
        loadTerminalAwardStatusFlag = setTimeout(loadTerminalAwardStatus, loadTerminalAwardStatusDelay);
    }
}
loadTerminalAwardStatusFlag = setTimeout(loadTerminalAwardStatus, loadTerminalAwardStatusDelay);
//定时刷新彩票机的兑奖状态
// setInterval(loadTerminalAwardStatus, loadTerminalAwardStatusDelay);
//定时刷新待兑奖列表
// setInterval(function () { waitingTicketTable.reload() }, loadWaitingTicketDelay);
//定时获取中奖状态
// setInterval(getAwardResult, 300, workList.join(","));

//彩票机列表加载完后加载待兑奖列表
function afterTerminalLoad(res, curr, count) {
    waitingTicketTable = table.render({
        elem: '#waitingTicket',
        url: '/api/getWaitingTicket?terminal_no=' + workList.join(","),
        cellMinWidth: 80,
        page: true,
        title: "待兑奖",
        text: {
            none: '暂无相关数据'
        },
        done: function (res, curr, count) {
            waitingTicketList = {};
            div = layui.$("div[lay-id=waitingTicket]");
            if (res.data && res.data.length > 0) {
                for (var i = 0; i < res.data.length; i++) {
                    waitingTicketList[res.data[i]['awardNo']] = div.find("tr:eq(" + (i + 1) + ")");
                }
            }

        },
        cols: [[{
            field: 'index',
            width: "20%",
            title: '序号'
        },
        {
            field: 'terminal_no',
            width: "30%",
            title: '终端号',
            sort: true
        },
        {
            field: 'awardNo',
            title: '票号密码',
            minWidth: 300
        },
        {
            field: 'result',
            title: '备注',
            minWidth: 300
        }

        ]]
    });

}
layui.use('table',
    function () {
        table = layui.table;
        terminalTable = table.render({
            elem: '#terminal',
            url: '/api/getTerminal?',
            cellMinWidth: 30
            ,
            page: true,
            title: "终端机列表",
            text: {
                none: '暂无相关数据'
            },
            done: function (res, curr, count) {
                //如果是异步请求数据方式，res即为你接口返回的信息。
                //如果是直接赋值的方式，res即为：{data: [], count: 99} data为当前页数据、count为数据总长度
                // console.log(res);
                //得到当前页码
                // console.log(curr); 
                //得到数据总量
                // console.log(count);
                if (res.data && res.data.length > 0) {
                    terminalArr = res.data;
                    afterTerminalLoad(res, curr, count);
                } else {
                    //如果没有获取到彩票机列表，500秒后再重新加载一次
                    setTimeout(function () {
                        terminalTable.reload()
                    },
                        500)
                }
            },
            cols: [[{
                field: 'index',
                width: "10%",
                title: '序号'
            },
            {
                field: 'terminal_no',
                width: "20%",
                title: '彩票机编号',
                sort: true
            },
            {
                field: 'award_status',
                width: "50%",
                title: '兑奖状态',
                templet: function (d) {
                    if (d.award_status == "IDLE") {
                        text = "空闲";
                        color = "green";
                    } else {
                        text = "正在兑奖 <b style='color:red'>票号：" + d.award_status + "</b>";
                        color = "blue";
                    }
                    return '<span id="award_status_' + d.terminal_no + '" style="color:' + color + '">' + text + '</span>'
                }
            },
            {
                field: 'work_status',
                width: "20%",
                title: '工作状态',
                templet: function (d) {
                    if (d.work_status == "START") {
                        text = "运行"; color = "green"; action = "关闭"; Aclass = "layui-btn  layui-btn-sm  layui-btn-danger"; workList.push(d.terminal_no);
                    } else {
                        text = "停止"; Îcolor = "red"; action = "开启"; Aclass = "layui-btn  layui-btn-sm  layui-btn-normal"
                    }
                    return '当前状态：<span style="color:' + color + '">' + text + '</span>&nbsp;&nbsp;<button type="button"  class="' + Aclass + '" onclick="changeTerminalWorkStatus(\'' + d.terminal_no + '\',' + d.index + ')">' + action + '</button>'
                }
            }]]
        });
        //id,insert_Timestamp,msg,prize_Flag,prize_value,prize_Unit_Id,prize_Timestamp,station_Id,ticket_idmsg 
        
        winTicketTable = table.render({
            elem: '#winTicket',
            url: '/api/getWinTicket?',
            cellMinWidth: 80,
            page: true,
            title: "奖票表",
            text: {
                none: '暂无相关数据'
            },
            done: function (res, curr, count) {
                console.log(res);
            },
            loading: true,
            cols: [[{
                fixed: 'left',
                type: "checkbox"
            }, {
                field: 'id',
                width: 80,
                title: 'ID'
            },
            {
                field: 'ticket_idmsg',
                width: 290,
                title: '票号密码'
            }, {
                field: 'insert_Timestamp',
                width: 165,
                title: '入库时间',
                sort: true
            },
            {
                field: 'prize_Timestamp',
                width: 165,
                title: '兑奖时间',
                sort: true
            },
            {
                field: 'prize_Flag',
                title: '兑奖状态',
                width: 80,
                minWidth: 40,
                sort: true,
                templet: function (d) {
                    text = "未知"
                    if (d.prize_Flag == 0) {
                        text = "未兑奖"
                    } else if (d.prize_Flag == 1) {
                        text = "已中奖"
                    } else if (d.prize_Flag == 4) {
                        text = "未中奖"
                    } else if (d.prize_Flag == 2) {
                        text = "中大奖"
                    } else if (d.prize_Flag == -1) {
                        text = "已取数"
                    }
                    return text;
                }
            },
            {
                field: 'prize_value',
                width: 110,
                title: '中奖金额',
                minWidth: 40,
                sort: true
            },
            {
                field: 'prize_Unit_Id',
                width: 150,
                title: '兑奖机器',
                sort: true
            },
            {
                field: 'station_Id',
                width: 80,
                title: '站点'
            },

            {
                field: 'msg',
                title: '兑奖信息'
            },

            {
                title: '操作',
                fixed: 'right',
                width: 178,
                align: 'center',
                templet: function (d) {
                    return '<a href="javascript:void(0)" class="layui-btn  layui-btn-sm " onclick="addAwardTicket(\'' + d.ticket_idmsg + '\')">重新兑奖</a>'
                }
            }]]
        });

    });