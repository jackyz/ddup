-module(user_db).

-compile(export_all).

%% ok | {error, Reason}
authenticate(Mobile, Password) ->
    io:format("authenticate(~p,~p)~n", [Mobile, Password]),
    %% TODO 
    ok.

%% [] | ...
get_groups(Mobile) ->
    io:format("get_groups(~p)~n", [Mobile]),
    %% TODO
    [].

%% string
get_nick(Mobile) ->
    io:format("get_nick(~p)~n", [Mobile]),
    %% TODO
    "贝贝妈".
