-module(ddup_util).

-compile(export_all).

%% draw fuzzy png bin for a string
fuzzy_png(Str) ->
    %% defines
    Imw = 60, Imh = 20,
    Ftw = 7,  Fth = 14,
    Ft = egd_font:load(filename:join([code:priv_dir(ddup), "7x14.wingsfont"])),
    C0 = egd:color({0,0,0,64}),
    CF = [egd:color({255,0,0,172}),
	  egd:color({0,255,0,172}),
	  egd:color({0,0,255,172})],
    CM = [egd:color({255,0,0,64}),
	  egd:color({255,255,0,64}),
	  egd:color({0,255,0,64}),
	  egd:color({0,255,255,64}),
	  egd:color({0,0,255,64}),
	  egd:color({255,0,255,64})],
    %% init
    Im = egd:create(Imw,Imh),
    %% random draw text
    Dx = trunc(Imw/length(Str)),
    Dy = Imh,
    Fx = fun(I, C) ->
		 Px = I * Dx + random:uniform(Dx - Ftw),
		 Py = random:uniform(Dy - Fth),
		 Cx = lists:nth(random:uniform(length(CF)), CF),
		 egd:text(Im, {Px, Py}, Ft, [C], Cx)
	 end,
    [Fx(X-1, lists:nth(X, Str)) || X <- lists:seq(1,length(Str))],
    %% fuzzy
    Fz = fun() ->
		 Px1 = random:uniform(Imw),
		 Px2 = random:uniform(Imw),
		 Py1 = random:uniform(Imh),
		 Cx = lists:nth(random:uniform(length(CM)), CM),
		 egd:line(Im, {Px1, Py1}, {Px2, Py1}, Cx)
	 end,
    [Fz() || _ <- lists:seq(1, 10)],
    %% mask dark
    egd:filledRectangle(Im,{0,0},{Imw-1,Imh-1},C0),
    %% render
    Bin = egd:render(Im,png,[{render_engine, alpha}]),
    egd:destroy(Im),
    Bin.

%% rand_str
rand_str(Len) ->
    rand_str(Len, "1234567890ABCEFGHJKLMNPRTUVWXYabcdefhjkmnprtuvwxy").

%% rand_str
rand_str(Len, L) ->
    [rand_char(L) || _X <- lists:seq(1, Len)].

%% rand_char
rand_char(L) ->
    lists:nth(random:uniform(length(L)), L).

%% shuffle list    
shuffle(List) ->
    D = [{random:uniform(), X} || X <- List],
    {_, D1} = lists:unzip(lists:keysort(1, D)), 
    D1.
