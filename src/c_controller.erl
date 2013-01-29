-module(c_controller,[Env]).

-export([handle_request/2,before_filter/0]).

handle_request("zdx",[]) ->
    {static, "/c/zdx.html"};

handle_request("zdx",["feed"]) ->
    %% TODO 从“用户课程进度”中获取“今日练习”
    {json, [0, [<<"星">>, <<"月">>, <<"安徒生童话">>]]};

handle_request("zdx",["post"]) ->
    %% TODO 解析“今日练习”反馈，更新“用户课程进度”
    {json, [0]}.

before_filter() ->
    ok.
