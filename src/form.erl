-module(form).

%% process dict
%% form.field.vals form.field.errs

-define(KEY, form).
-define(GET(), (erlang:get(?KEY))).
-define(SET(Term), (erlang:put(?KEY, Term))).
-define(DEL(), (erlang:erase(?KEY))).
-define(HD(List), (case List of
		       [] -> undefined;
		       [H|_] -> H 
		   end)).

%% -define(GET_PARAM(), (erlang:get(?PARAM_KEY))).
%% -define(SET_PARAM(Term), (erlang:put(?PARAM_KEY, Term))).
%% -define(DEL_PARAM(), (erlang:erase(?PARAM_KEY))).

%% -define(GET_ERROR(), (erlang:get(?ERROR_KEY))).
%% -define(SET_ERROR(Term), (erlang:put(?ERROR_KEY, Term))).
%% -define(DEL_ERROR(), (erlang:erase(?ERROR_KEY))).

-compile(export_all).

-include_lib("eunit/include/eunit.hrl").

%%%% test ::
test() ->
    ?assert(true   =:= match({mobile}, "13501374518")),
    %% ?assert(exist  =:= match({mobile}, "")),
    ?assert(regexp =:= match({mobile}, "a")),
    ?assert(true   =:= match({password}, "123456")),
    %% ?assert(exist  =:= match({password}, "")),
    ?assert(length =:= match({password}, "123")),
    ?assert(length =:= match({password}, "12345678901234567")),
    ?assert(true   =:= match({token, "1234"}, "1234")),
    %% ?assert(exist  =:= match({token, "1234"}, "")),
    ?assert(length =:= match({token, "1234"}, "123")),
    ?assert(equal  =:= match({token, "1234"}, "2345")),
    ?assert(true   =:= match({email}, "jackyz.zhao@gmail.com")),
    %% ?assert(exist  =:= match({email}, "")),
    ?assert(regexp =:= match({email}, "abc#damm.")),
    ?assert(true   =:= match({bool}, "yes")),
    ?assert(true   =:= match({bool}, "no")),
    ?assert(within =:= match({bool}, "1234")),
    
    bind({beepbeep, [{"beepbeep.data",
    		      [{"mobile", "13501374518"},
		       {"password", "123456"},
		       {"email", "j@abc.com"},
    		       {"token", "1234"}
    		      ]}]}),
    
    ?assert("13501374518" =:= val("mobile")),
    ?assert("123456" =:= val("password")),
    ?assert("j@abc.com" =:= val("email")),
    ?assert("1234" =:= val("token")),

    ?assert(["13501374518"] =:= vals("mobile")),
    ?assert(["123456"] =:= vals("password")),
    ?assert(["j@abc.com"] =:= vals("email")),
    ?assert(["1234"] =:= vals("token")),

    ?assert(true =:= valid({mobile}, "mobile")),
    ?assert(true =:= valid({password}, "password")),
    ?assert(true =:= valid({token, "1234"}, "token")),
    ?assert(true =:= valid({email}, "email")),
    ?assert(true =:= valid()),

    ?debugVal(?GET()),
    io:format("DUMP JSON:~s~n", [mochijson2:encode(dump(json))]),
    ?debugVal(?GET()),
    
    bind({beepbeep, [{"beepbeep.data",
    		      [{"mobile", "a3501374518"},
		       {"password", "12345"},
		       {"email", "abc#damm."},
    		       {"token", "123"}
    		      ]}]}),
    
    ?assert(regexp =:= valid({mobile}, "mobile")),
    ?assert(length =:= valid({password}, "password")),
    ?assert(regexp =:= valid({email}, "email")),
    ?assert(length =:= valid({token, "1234"}, "token")),

    ?debugVal(?GET()),
    err("info", auth),
    ?debugVal(?GET()),

    ?assert(false  =:= valid()),

    ?debugVal(?GET()),
    io:format("DUMP JSON:~s~n", [mochijson2:encode(dump(json))]),
    ?debugVal(?GET()),
    
    ok.

%%%% unbind :: clear the process dict
unbind() ->
    ?DEL(),
    ok.

%%%% bind Env :: using the process dict
bind({beepbeep, Env}) ->
    ok = unbind(),
    D = proplists:get_value("beepbeep.data", Env),
    ?SET([{K, [{vals, proplists:get_all_values(K, D)}, {errs, []}]}
	  || K <- proplists:get_keys(D)]),
    ok.

%%%% dump :: dump and clear the process dict
%% erlydtl is suck, leak of atom table possible
dump(erlydtl) ->
    F = ?GET(),
    FP = [{list_to_atom(K), V} || {K, [{vals, V}, {errs, _E}]} <- F],
    FE = [{list_to_atom("error_"++K), E} || {K, [{vals, _V}, {errs, E}]} <- F],
    R = lists:append(FP, FE),
    ok = unbind(), R;
dump(json) ->
    Bl = fun
	     ([]) ->
		 [];
	     ([H|_]=L) when is_list(H) ->
		 [list_to_binary(X) || X <- L];
	     ([H|_]=L) when is_atom(H) -> 
		 [atom_to_binary(X, utf8) || X <- L];
	     (L) when is_list(L) ->
		 list_to_binary(L);
	     (U) ->
		 exit({'Bin', unknown, U})
	 end,
    F = ?GET(),
    %% J = [{Bl(K), {struct, [{val, Bl(V)}, {err, Bl(E)}]}}
    %% 	 || {K, [{vals, V}, {errs, E}]} <- F],
    J = [{Bl(K), {struct, [{err, Bl(E)}]}} || {K, [{vals, _},{errs, E}]} <- F],
    R = {struct, J},
    ok = unbind(), R.

%%%% retrieve param val

%% get val of key
val(Key) ->
    ?HD(vals(Key)).

%% get vals of key
vals(Key) ->
    case [V || {K, [{vals, V}, {errs, _E}]} <- ?GET(), K =:= Key] of
	[R] -> R;
	_ -> []
    end.

%%%% set param

%% set value of key (replace the old one) :: modify for display
val(Key, Value) ->
    EH = {Key, [{vals, [Value]}, {errs, errs(Key)}]},
    ET = [E || {K, _}=E <- ?GET(), K =/= Key],
    ?SET([EH | ET]),
    ok.

%%%% retrieve param error

%% get err of key
err(Key) ->
    ?HD(errs(Key)).

%% get errs of key
errs(Key) ->
    case [E || {K, [{vals, _V}, {errs, E}]} <- ?GET(), K =:= Key] of
	[R] -> R;
	_ -> []
    end.

%%%% set param error

%% set err value of key (append after old one) :: for display
err(Key, Value) ->
    EH = {Key, [{vals, vals(Key)}, {errs, errs(Key)++[Value]}]},
    ET = [E || {K, _}=E <- ?GET(), K =/= Key],
    ?SET([EH | ET]),
    ok.

%%%% check if form valid all the valid ?
valid() ->
    AllErrs = [E || {_K, [{vals, _V}, {errs, E}]} <- ?GET(), E =/= []],
    AllErrs =:= [].

%%%% valid param if invalid set error

%% batch
%% * valid([Rule], [Key])
%%   valid([Rule], Key)
%% * valid(Rule, [Key])

%% one
%%   valid(Rule, Key)
%% * valid(Rule, Key, EAtom)

%% valid key if invalid set err with default info
valid([], _) -> true;
valid([H|T], Key)
  when is_tuple(H) -> %% iterate
    case valid(H, Key) of
	true -> valid(T, Key);
	Any -> Any
    end;
valid(_, []) -> true;
valid(Rule, [H|T])
  when is_list(H) ->  %% iterate
    case valid(Rule, H) of
	true -> valid(Rule, T);
	Any -> Any
    end;
valid(Rule, Key)
  when is_tuple(Rule), is_list(Key) ->
    valid(Rule, Key, undefined); %% deeper
valid(Rule, Key) ->
    error_logger:info_report({?MODULE, valid, badargs, {Rule, Key}}),
    error.

%% valid key if invalid set err with E
valid(Rule, Key, E)
  when is_tuple(Rule), is_list(Key), is_atom(E) ->
    case vals(Key) of %% deeper
	[] -> valid_val(Rule, undefined, Key, E);
	[H|_]=Vals when is_list(H) -> valid_vals(Rule, Vals, Key, E)
    end;
valid(Rule, Key, E) ->
    error_logger:info_report({?MODULE, valid, badargs, {Rule, Key, E}}),
    error.

%% batch on vals
%% * valid_vals(Rule, [Val], Key, E)

%% one on val
%%   valid_val(Rule, Val, Key, E)

%% valid vals if invalid set err with E in Key
valid_vals(_, [], _, _) -> true;
valid_vals(Rule, [H|T], Key, E)
  when is_list(H) -> %% iterate
    case valid_val(Rule, H, Key, E) of %% deeper
	true -> valid_vals(Rule, T, Key, E);
	Any -> Any
    end.

%% valid val if invalid set err with E in Key
valid_val(Rule, Val, Key, undefined)
  when is_tuple(Rule), is_list(Key) ->
    case match(Rule, Val) of %% deeper
	true -> true;
	E -> err(Key, E), E
    end;
valid_val(Rule, Val, Key, E)
  when is_tuple(Rule), is_list(Key), is_atom(E) ->
    case match(Rule, Val) of %% deeper
	true -> true;
	_ -> err(Key, E), E
    end;
valid_val(Rule, Val, Key, E) ->
    error_logger:info_report({?MODULE, valid, badargs, {Rule, Val, Key, E}}),
    error.

%%%% match val against rule

%% match val if valid return true or return the err atom

match({mobile}, Val) ->
    match([{regexp, "^1[0-9]{10}\$"}], Val);
match({password}, Val) ->
    match([{length, 6, 16}], Val);
match({gender}, Val) ->
    match([{within, ["male", "female"]}], Val);
match({token, T}, Val) ->
    match([{length, 4, 4}, {equal, lower, T}], Val);
match({email}, Val) ->
    match([{regexp, "^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\$"}], Val);
match({date, iso}, Val) ->
    match([{regexp, "^[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}\$"}], Val);
match({bool}, Val) ->
    match([{within, ["yes", "no", "true", "false"]}], Val);

match([], _) -> true;
match([H|T], Val) -> 
    case match(H, Val) of %% iterate
	true -> match(T, Val);
	Any -> Any
    end;
match(R, Val)
  when is_tuple(R) ->
    case rule(R, Val) of %% deeper
	true -> true;
	_ -> erlang:element(1, R)
    end.

%% rule val return true or false
rule({exist}, Val) ->
    (Val /= undefined) and (Val /= []);
rule({length, Min, Max}, Val) ->
    Length = erlang:length(Val),
    (Length >= Min) and (Length =< Max);
rule({equal, Term}, Val) ->
    Term == Val;
rule({equal, lower, Term}, Val) ->
    string:to_lower(Term) == string:to_lower(Val);
rule({within, List}, Val) ->
    lists:member(Val, List);
rule({regexp, Re}, Val) ->
    case re:run(Val, Re) of
	{match, _} -> true;
	_ -> false
    end;
rule(Rule, Val) ->
    error_logger:info_report({?MODULE, rule, undef, {Rule, Val}}),
    false.

