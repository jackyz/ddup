-module(home_controller,[Env]).

-export([handle_request/2,before_filter/0]).

before_filter() ->
    ok.

handle_request("index",[]) ->
    case user() of
	undefined -> {render, "index.html", []};
	User ->
	    {render, "main.html", [{nick, user_db:get_nick(User)}]}
    end.

%%%% internal

%% undefined | username
user() ->
    beepbeep_args:get_session_data("user", Env).

