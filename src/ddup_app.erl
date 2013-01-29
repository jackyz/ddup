-module(ddup_app).

-behaviour(application).
-export([start/2,stop/1]).


%% @spec start(_Type, _StartArgs) -> ServerRet
%% @doc application start callback for ddup.
start(_Type, _StartArgs) ->
    ddup_deps:ensure(),
    ddup_sup:start_link().

%% @spec stop(_State) -> ServerRet
%% @doc application stop callback for ddup.
stop(_State) ->
    ok.
