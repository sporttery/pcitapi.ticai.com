
var terminalTable, winTicketTable, waitingTicketTable, table, form, $;
var workListEl = {}, all_terminal = [], workList = [];
var waitingTicketEl, winTicketEl;
var getWorkStatusTimer, getWaitingTicketTimer, getAwardResultTimer, jinggaoAudio;
var os = function () {
    var ua = navigator.userAgent,
        isWindowsPhone = /(?:Windows Phone)/.test(ua),
        isSymbian = /(?:SymbianOS)/.test(ua) || isWindowsPhone,
        isAndroid = /(?:Android)/.test(ua),
        isFireFox = /(?:Firefox)/.test(ua),
        isChrome = /(?:Chrome|CriOS)/.test(ua),
        isTablet = /(?:iPad|PlayBook)/.test(ua) || (isAndroid && !/(?:Mobile)/.test(ua)) || (isFireFox && /(?:Tablet)/.test(ua)),
        isPhone = /(?:iPhone)/.test(ua) && !isTablet,
        isPc = !isPhone && !isAndroid && !isSymbian;
    return {
        isTablet: isTablet,
        isPhone: isPhone,
        isAndroid: isAndroid,
        isPc: isPc
    };
}();
function getWorkStatus() {
    var url = "/api/getTerminal?"

    if (workList.length > 0) {
        url += "terminal_no=" + workList.join(",")
    }
    if (all_terminal.length > 0 && workList.length == 0) {
        return;
    }
    $.get(url, function (data) {

        if (workList.length > 0) {
            for (var i = 0; i < data.data.length; i++) {
                var d = data.data[i];
                var terminal_no = d.terminal_no;
                var award_status = d.award_status;
                var el = workListEl[terminal_no];
                var oldAwardNo = el.data("value");
                if (el && oldAwardNo != award_status) {
                    if (award_status == "IDLE") {
                        text = "空闲";
                        color = "green";
                        if (waitingTicketEl[oldAwardNo]) {
                            waitingTicketEl[oldAwardNo].parents("tr").remove();
                            delete waitingTicketEl[oldAwardNo];
                        } else {
                            getWaitingTicket(true);
                        }
                        //getAwardResult(oldAwardNo, terminal_no);
                        if (!winTicketEl[oldAwardNo]) {
                            winTicketTable.reload();
                        }
                    } else {
                        text = "正在兑奖 <b style='color:red'>票号：" + award_status + "</b>";
                        color = "blue";
                        //3秒后检查，是否这个票号还在，如果还在，那说明兑奖出了问题，因为一张票号，不可能3秒了还不兑奖
                        setTimeout(function (opt) {
                            award_status = opt.award_status;
                            terminal_no = opt.terminal_no;
                            var el;
                            if (workListEl[terminal_no]) {
                                el = workListEl[terminal_no];
                            } else {
                                el = $("#award_status_" + terminal_no);
                            }
                            if (el && el.data("value") == award_status) {
                                if (!jinggaoAudio) {
                                    $("body").append('<audio src="/jinggao.mp3" id="jinggaoAudio" autoplay="autoplay">您的浏览器不支持 audio 标签。</audio>');
                                    jinggaoAudio = $("#jinggaoAudio");
                                } else {
                                    jinggaoAudio[0].play();
                                }
                                layer.msg("警告：<h2 style='color:yellow'>"+terminal_no+"</h2>有票3秒都没有完成兑奖<h3 style='color:pink'>"+award_status+"</h3>");
                            }
                        }, 3000, { award_status, terminal_no });
                        if (waitingTicketEl[award_status]) {
                            waitingTicketEl[award_status].toggleClass("red");
                        } else {
                            getWaitingTicket(true);
                        }
                        if (winTicketEl[award_status]) {
                            winTicketEl[award_status].toggleClass("red");
                        } else {
                            winTicketTable.reload();
                        }
                    }
                    el.data("value", award_status).css("color", color).html(text);
                }
            }
        } else {
            if (data.code == 0) {
                all_terminal = data.data;
                initTermnal(data.data);
            } else {
                all_terminal = [];
                initTermnal([]);
            }
        }
        getWorkStatusTimer && clearTimeout(getWorkStatusDelay);
        getWorkStatusTimer = setTimeout(getWorkStatus, getWorkStatusDelay);
    })
}
function getAwardResult(ticket, terminal_no) {
    $.get("/api/getAwardResult?ticket=" + ticket, function (data) {
        if (data.code == 0 && data.data) {
            var err = false;
            for (var i = 0; i < data.data.length; i++) {
                var d = data.data[i];
                var award_no = d.award_no;
                if (d.msg == "成功" || d.msg == "OK") {
                    waitingTicketEl[award_no] && waitingTicketEl[award_no].parents("tr").remove();
                    if (winTicketEl[award_no]) {
                        award_result_info = d.info;
                        prize_flag = d.prize_flag;
                        award_money = d.prize_value;
                        award_time = d.prize_timestamp;
                        terminal_no = d.PRIZE_UNIT_ID;
                        text = "未知";
                        if (prize_flag == 0) {
                            text = "未兑奖";
                        } else if (prize_flag == 1) {
                            text = "已中奖";
                        } else if (prize_flag == 4) {
                            text = "未中奖";
                        } else if (prize_flag == 2) {
                            text = "中大奖";
                        } else if (prize_flag == -1) {
                            text = "已取数";
                        }
                        tr = winTicketEl[award_no].parents("tr");
                        tr.find("td[data-field=prize_Timestamp] .layui-table-cell").text(award_time);
                        tr.find("td[data-field=msg] .layui-table-cell").text(award_result_info);
                        tr.find("td[data-field=prize_value] .layui-table-cell").text(award_money);
                        tr.find("td[data-field=prize_Unit_Id] .layui-table-cell").text(terminal_no);
                        tr.find("td[data-field=prize_Flag] .layui-table-cell").text(text);
                        winTicketEl[award_no].toggleClass("red");
                        delete winTicketEl[award_no];
                    }
                } else {
                    // alert(d.msg + " 请联系管理员");
                    console.log(ticket, d);
                    err = true;
                }
                if (err) {
                    getAwardResultTimer && clearTimeout(getAwardResultTimer)
                    getAwardResultTimer = setTimeout(function () { winTicketTable.reload(); }, 3000);
                }
            }
        }
    });
}
function getWaitingTicket(runOnce) {
    if (!runOnce) {
        getWaitingTicketTimer && clearTimeout(getWaitingTicketTimer);
        getWaitingTicketTimer = setTimeout(getWaitingTicket, getWaitingTicketDelay);
    }
    if (workList.length == 0) {
        initWaitTable([]);
    } else {
        var url = '/api/getWaitingTicket?terminal_no=' + workList.join(",");
        $.get(url, function (data) {
            //判断，需要的时候，才reload
            if (waitingTicketTable && data.code == 0 && data.count > 0) {
                var reload = false;
                for (var i = 0; i < data.data.length; i++) {
                    var d = data.data[i];
                    if (!waitingTicketEl[d['awardNo']]) {
                        reload = true;
                        break;
                    }
                }
                if (reload) {
                    initWaitTable(data);
                }
            } else {
                initWaitTable(data);
            }
        });
    }
}
function initWaitTable(data) {
    waitingTicketTable = table.render({
        elem: '#waitingTicket',
        data: data.data || [],
        page: data.count > 10,
        done: function (res, curr, count) {
            waitingTicketEl = {};
            if (res.data && res.data.length > 0) {
                for (var i = 0; i < res.data.length; i++) {
                    var d = res.data[i];
                    waitingTicketEl[d['awardNo']] = $("#wait_table_" + d.awardNo)
                }
            }

        },
        cols: [[{
            field: 'index',
            width: "5%",
            title: '序号'
        },
        {
            field: 'terminal_no',
            width: "20%",
            title: '终端号'

        },
        {
            field: 'awardNo',
            title: '票号密码',
            width: "75%",
            templet: function (d) {
                return '<span id="wait_table_' + d.awardNo + '">' + d.awardNo + '</span>';
            }
        }

        ]]
    });
}


//手工添加兑奖传入后台
function doAddAwardTicket(ticket, terminal_no) {
    layui.$.post("/api/addAwardTicket", { ticket, terminal_no },
        function (d) {
            if (d.code == 0) {
                waitingTicketTable.reload();
                winTicketTable.reload();
            }
        })
}
function addAwardTicketAll() {
    if (workList.length == 0) {
        layer.msg("没有工作中的机器");
        return;
    }
    checkboxData = table.checkStatus('winTicket')
    if (checkboxData.data.length > 0) {
        var k = 0;
        var ticket_arr = [], terminal_arr = [];
        for (var i = 0; i < checkboxData.data.length; i++) {
            var terminal_no = workList[k++];
            if (!terminal_no) {
                k = 0;
                terminal_no = workList[k++];
            }
            terminal_arr.push(terminal_no);
            ticket_arr.push(checkboxData.data[i].ticket_idmsg);
        }
        doAddAwardTicket(ticket_arr.join(","), terminal_arr.join(","));

    } else {
        layer.msg("请先至少选择一条记录");
    }

}
//手工添加兑奖终端机选择
function addAwardTicket(ticket, terminal_no) {
    if (!terminal_no) {
        terminalArr = all_terminal;
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
            title: false,
            closeBtn: false,
            area: '360px;',
            shade: 0.8,
            id: 'LAY_layuipro',
            btn: ['确认', '取消'],
            btnAlign: 'c',
            moveType: 1,
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
            layer.msg("terminal_no 没有选择");
        }
    } else {
        layer.msg("参数错误");
    }
}

function initWinTicket() {

    winTicketTable = table.render({
        elem: '#winTicket',
        url: '/api/getWinTicket?',
        page: true,
        done: function (res, curr, count) {
            winTicketEl = {}
            for (var i = 0; i < res.data.length; i++) {
                var d = res.data[i];
                winTicketEl[d.ticket_idmsg] = $("#win_ticket_" + d.ticket_idmsg);
            }
        },
        cols: [[{
            fixed: 'left',
            type: "checkbox"
        },
        {
            field: 'ticket_idmsg',
            width: 290,
            title: '票号密码',
            templet: function (d) {
                return '<span id="win_ticket_' + d.ticket_idmsg + '">' + d.ticket_idmsg + '</span>'
            }
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
            width: 120,
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
            title: '兑奖信息',
            sort: true
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

}

function initTermnal(data) {
    terminalTable = table.render({
        elem: '#terminal',
        data: data,
        // page: data.length > 10,
        limit: data.length,
        done: function (res, curr, count) {
            workListEl = {};
            if (res.data && res.data.length > 0) {
                for (var i = 0; i < res.data.length; i++) {
                    var d = res.data[i];
                    if (d.work_status == "START") {
                        workListEl[d.terminal_no] = $("#award_status_" + d.terminal_no);
                        workList.push(d.terminal_no);
                    }
                }
            }
            getWaitingTicket();
        },
        cols: [[{
            width: "5%",
            type: 'numbers',
            title: '序号'
        },
        {
            field: 'terminal_no',
            width: "10%",
            title: '编号',
            sort: true
        },
        {
            field: 'IP',
            width: "6%",
            title: 'IP',
            sort: true,
            templet: function (d) {
                return '<a href="/showscreen.html?ip='+d.IP+'" target="_blank">'+d.IP.split(".").slice(-2).join(".")+'</a>';
            }
        },
        {
            field: 'pwd',
            width: "13%",
            title: '密码',
            align: 'center',
            templet: function (d) {
                return d.pwd1 + "&nbsp;&nbsp;" + d.pwd2
            }
        },
        {
            field: 'award_status',
            width: os.isPc ? "56%" : "200",
            title: '兑奖状态',
            templet: function (d) {
                if (d.award_status == "IDLE") {
                    text = "空闲";
                    color = "green";
                } else {
                    text = "正在兑奖 <b style='color:red'>票号：" + d.award_status + "</b>";
                    color = "blue";
                }
                return '<span id="award_status_' + d.terminal_no + '" data-value="' + d.award_status + '" style="color:' + color + '">' + text + '</span>'
            }
        },
        {
            field: 'work_status',
            width: os.isPc ? "10%" : "120",
            fixed: 'right',
            align: 'center',
            title: '工作状态',
            templet: "#checkboxWorkStatus"
        }]]
    });

}

layui.use('table',
    function () {
        table = layui.table;
        form = layui.form;
        $ = layui.$;
        getWorkStatus(true);
        initWinTicket();

        form.on('checkbox(checkboxWorkStatus)', function (obj) {
            // console.log(this.value, this.name, obj.elem.checked, obj.othis);
            // layer.tips(this.value + ' ' + this.name + '：'+ obj.elem.checked, obj.othis);
            var terminal_no = this.value;
            $.get("/api/changeTerminalWorkStatus?terminal_no=" + terminal_no + "&work_status=" + (!obj.elem.checked ? "START" : "STOP"),
                function (d) {
                    if (d.code == 0) {
                        if (obj.elem.checked) {
                            var el = $("#award_status_" + terminal_no);
                            workListEl[terminal_no] = el;
                            for (var i = 0; i < all_terminal.length; i++) {
                                if (all_terminal[i].terminal_no == terminal_no) {
                                    all_terminal[i].work_status = "START";
                                    break;
                                }
                            }
                            workList = Object.keys(workListEl);
                            getWorkStatusTimer && clearTimeout(getWorkStatusTimer);
                            getWorkStatus();
                        } else {
                            delete workListEl[terminal_no];
                            for (var i = 0; i < all_terminal.length; i++) {
                                if (all_terminal[i].terminal_no == terminal_no) {
                                    all_terminal[i].work_status = "STOP";
                                    break;
                                }
                            }
                            workList = Object.keys(workListEl);
                        }
                        layer.tips(d.msg, obj.othis);
                    } else {
                        layer.tips(d.msg, obj.othis);
                        obj.elem.checked = !obj.elem.checked;
                        obj.othis.toggleClass("layui-form-checked");
                    }
                }).fail(function () {
                    layer.tips("操作失败", obj.othis);
                    obj.elem.checked = !obj.elem.checked;
                    obj.othis.toggleClass("layui-form-checked");
                });
        });

        table.on('sort(winTicket)', function (obj) { //注：tool是工具条事件名，test是table原始容器的属性 lay-filter="对应的值"
            // console.log(obj.field); //当前排序的字段名
            // console.log(obj.type); //当前排序类型：desc（降序）、asc（升序）、null（空对象，默认排序）
            // console.log(this); //当前排序的 th 对象

            //尽管我们的 table 自带排序功能，但并没有请求服务端。
            //有些时候，你可能需要根据当前排序的字段，重新向服务端发送请求，从而实现服务端排序，如：
            table.reload('winTicket', { //testTable是表格容器id
                initSort: obj //记录初始排序，如果不设的话，将无法标记表头的排序状态。 layui 2.1.1 新增参数
                , where: { //请求参数（注意：这里面的参数可任意定义，并非下面固定的格式）
                    field: obj.field //排序字段
                    , order: obj.type //排序方式
                }, page: {
                    curr: 1
                }
            });
        });

        /*(function longPolling() {
            $.ajax({
                  url: "/sub?key=AWARD_RESULT",
                  data: {"timed": new Date().getTime()},
                  dataType: "text",
                  timeout: 500000,
                  error: function (XMLHttpRequest, textStatus, errorThrown) {
                      console.log("[state: " + textStatus + ", error: " + errorThrown + " ]" + new Date());
                      if (textStatus == "timeout") { // 请求超时
                              longPolling(); // 递归调用
                          // 其他错误，如网络错误等
                          } else { 
                              longPolling();
                          }
                      },
                  success: function (data, textStatus) {
                      console.log(data);
                      if (textStatus == "success") { // 请求成功
                          longPolling();
                      }
                  }
              });
          })();*/
    });