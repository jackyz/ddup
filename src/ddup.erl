-module(ddup).
-export([start/0, stop/0]).

ensure_started(App) ->
    case application:start(App) of
        ok ->
            ok;
        {error, {already_started, App}} ->
            ok
    end.
        
%% @spec start() -> ok
%% @doc Start the ddup server.
start() ->
    ddup_deps:ensure(),
    ensure_started(crypto),
    application:start(ddup).

%% @spec stop() -> ok
%% @doc Stop the ddup server.
stop() ->
    Res = application:stop(ddup),
    application:stop(crypto),
    Res.
