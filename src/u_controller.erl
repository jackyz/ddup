-module(u_controller,[Env]).

-export([before_filter/0, handle_request/2]).

before_filter() ->
    Filter = [], %% ["login", "register", "recover"],
    Method = beepbeep_args:method(Env),
    Action = beepbeep_args:get_action(Env),
    case {Method == 'GET', lists:member(Action, Filter)} of
	{true, true} ->
	    "/"++Path = beepbeep_args:path(Env),
	    Tmpl = hd(string:tokens(Path,"."))++".html",
	    {render, Tmpl, []};
	_ -> ok
    end.

handle_request("token",[]) ->
    %% error_logger:info_report({token, ?MODULE, ?LINE, self()}),
    Str = get_token(),
    Bin = ddup_util:fuzzy_png(Str),
    {png, Bin};

handle_request("login",[]) ->
    form:bind({beepbeep, Env}),
    form:valid([{exist}, {mobile}], "mobile"),
    form:valid([{exist}, {password}], "password"),
    form:valid([{exist}, {token, get_token()}], "token"),
    case form:valid() of
	true ->
	    del_token(), form:val("token", ""),
	    case login(form:val("mobile"), form:val("password")) of
		{error, Reason} ->
		    form:err("info", Reason),
		    {json, [1, form:dump(json)]};
		ok -> {json, [0]}
	    end;
	false -> {json, [1, form:dump(json)]}
    end;

handle_request("register",[]) ->
    form:bind({beepbeep, Env}),
    form:valid([{exist}, {mobile}], "mobile"),
    form:valid([{exist}], "nick"),
    form:valid([{exist}], "name"),
    form:valid([{exist}, {date, iso}], "birthday"), %% YYYY.MM.DD
    form:valid([{exist}, {gender}], "gender"),
    case form:val("email") of
	undefined -> ok;
	_ -> form:valid([{email}], "email")
    end,
    form:valid([{exist}, {token, get_token()}], "token"),
    case form:valid() of
	true ->
	    del_token(), form:val("token", ""),
	    %% do_register(...);
	    {json, [0]};
	false -> {json, [1, form:dump(json)]}
    end;

handle_request("recover",[]) ->
    form:bind({beepbeep, Env}),
    form:valid([{exist}, {mobile}], "mobile"),
    form:valid([{exist}, {token, get_token()}], "token"),
    case form:valid() of
	true ->
	    del_token(), form:val("token", ""),
	    %% do_recover(form:val("mobile"));
	    {json, [0]};
	false -> {json, [1, form:dump(json)]}
    end;

handle_request("logout",[]) ->
    ok = logout(),
    {json, [0]}.

%%%% internal

%% string
get_token() ->
    case beepbeep_args:get_session_data("token", Env) of
	undefined ->
	    S = ddup_util:rand_str(4),
	    beepbeep_args:set_session_data("token", S, Env), S;
	Any -> Any
    end.

%% ok
del_token() ->
    beepbeep_args:remove_session_data("token", Env),
    ok.

%% ok | {error, Reason}
login(Mobile, Password) ->
    case user_db:authenticate(Mobile, Password) of
	{error, Reason} ->
	    {error, Reason};
	ok ->
	    Groups = user_db:get_groups(Mobile),
	    beepbeep_args:set_session_data("groups", Groups, Env),
	    beepbeep_args:set_session_data("user", Mobile, Env),
	    ok
    end.

%% ok
logout() ->
    beepbeep_args:remove_session_data("groups", Env),
    beepbeep_args:remove_session_data("user", Env),
    ok.

%% undefined | username
user() ->
    beepbeep_args:get_session_data("user", Env).

%% true | false
is_login() ->
    case user() of
	undefined -> false;
	_ -> true
    end.

%% ok | {error, Reason}
authorize(AllowGroups) ->
    Groups = case is_login() of
		 true -> beepbeep_args:get_session_data("groups", Env);
		 false -> ["guest"]
	     end,
    case Groups of
        undefined -> {error, authorization};
        _ ->
            case lists:any(fun(Group) ->
                                   lists:member(Group, AllowGroups)
                           end, Groups) of
                true -> ok;
                false -> {error, authorization}
            end
    end.

