-module(serverErlang_SUITE).

-compile(export_all).

-include_lib("eunit/include/eunit.hrl").
-include_lib("common_test/include/ct.hrl").
-include_lib("kernel/include/file.hrl").

%% %%--------------------------------------------------------------------
%% %% @spec suite() -> Info
%% %% Info = [tuple()]
%% %% @end
%% %%--------------------------------------------------------------------
suite() ->
	[{timetrap,{seconds,5}}].
%% %%--------------------------------------------------------------------
%% %% @spec init_per_suite(Config0) ->
%% %% Config1 | {skip,Reason} | {skip_and_save,Reason,Config1}
%% %% Config0 = Config1 = [tuple()]
%% %% Reason = term()
%% %% @end
%% %%--------------------------------------------------------------------
init_per_suite(_Config) ->
	[{ok, ok}].
%% 
%% 
%% %% connect(_Config) ->
%% %% 	{ok, Sock1} = gen_tcp:connect("localhost", 5678, [binary, {packet, raw}, {active, false}, {reuseaddr, true}]),
%% %% 	{ok, Sock2} = gen_tcp:connect("localhost", 5678, [binary, {packet, raw}, {active, false}, {reuseaddr, true}]),
%% %% 	Config1 = [{sock1, Sock1}, {sock2, Sock2}],
%% %% 	Config1.
%% %%--------------------------------------------------------------------
%% %% @spec end_per_suite(Config0) -> void() | {saveConfig,Config1}
%% %% Config0 = Config1 = [tuple()]
%% %% @end
%% %%--------------------------------------------------------------------
end_per_suite(_Config) ->
	ok.
%% %%--------------------------------------------------------------------
%% %% @spec init_per_group(GroupName, Config0) ->
%% %% Config1 | {skip,Reason} | {skip_and_save,Reason,Config1}
%% %% GroupName = atom()
%% %% Config0 = Config1 = [tuple()]
%% %% Reason = term()
%% %% @end
%% %%--------------------------------------------------------------------
init_per_group(_GroupName, Config) ->
	application:start(serverErlang),
	Config.
%% %%--------------------------------------------------------------------
%% %% @spec end_per_group(GroupName, Config0) ->
%% %% void() | {saveConfig,Config1}
%% %% GroupName = atom()
%% %% Config0 = Config1 = [tuple()]
%% %% @end
%% %%--------------------------------------------------------------------
end_per_group(_GroupName, _Config) ->
	application:stop(serverErlang),
	ok.
%% %%--------------------------------------------------------------------
%% %% @spec init_per_testcase(TestCase, Config0) ->
%% %% Config1 | {skip,Reason} | {skip_and_save,Reason,Config1}
%% %% TestCase = atom()
%% %% Config0 = Config1 = [tuple()]
%% %% Reason = term()
%% %% @end
%% %%--------------------------------------------------------------------
init_per_testcase(_TestCase, Config) ->
	Config.
%% %%--------------------------------------------------------------------
%% %% @spec end_per_testcase(TestCase, Config0) ->
%% %% void() | {saveConfig,Config1} | {fail,Reason}
%% %% TestCase = atom()
%% %% Config0 = Config1 = [tuple()]
%% %% Reason = term()
%% %% @end
%% %%--------------------------------------------------------------------
end_per_testcase(_TestCase, _Config) ->
	ok.
%%--------------------------------------------------------------------
%% @spec groups() -> [Group]
%% Group = {GroupName,Properties,GroupsAndTestCases}
%% GroupName = atom()
%% Properties = [parallel | sequence | Shuffle | {RepeatType,N}]
%% GroupsAndTestCases = [Group | {group,GroupName} | TestCase]
%% TestCase = atom()
%% Shuffle = shuffle | {shuffle,{integer(),integer(),integer()}}
%% RepeatType = repeat | repeat_until_all_ok | repeat_until_all_fail |
%% repeat_until_any_ok | repeat_until_any_fail
%% N = integer() | forever
%% @end
%%--------------------------------------------------------------------
%% get_query,
groups() ->
	[
	 {test_recv, [], [test_receive, test_receive2]},
	 {test_pos, [], [test_pos]},
	 {test_pos2, [], [test_pos2]}
	].
%%--------------------------------------------------------------------
%% @spec all() -> GroupsAndTestCases | {skip,Reason}
%% GroupsAndTestCases = [{group,GroupName} | TestCase]
%% GroupName = atom()
%% TestCase = atom()
%% Reason = term()
%% @end
%%--------------------------------------------------------------------
all() ->
	[{group, test_recv},
	 {group, test_pos},
	 {group, test_pos2}].
%
% @doc Test creation of a new resource on a new ID.
% expect: "result"
% %end
%
test_receive(_Config) ->
	{ok, Sock1} = gen_tcp:connect("localhost", 5678, [binary, {packet, raw}, {active, false}]),
	gen_tcp:send(Sock1, <<"ok">>),
	case gen_tcp:recv(Sock1, 0) of
		{ok, V} -> 
			Result = V;
		{error, _Result} ->
			Result = <<"ko">>
	end,
	gen_tcp:close(Sock1),
	?assertEqual(Result, <<"ok\n5;0,0\n">> ).

test_receive2(_Config) ->
	{ok, Sock2} = gen_tcp:connect("localhost", 5678, [binary, {packet, raw}, {active, false}]),
	gen_tcp:send(Sock2, <<"ok">>),
	case gen_tcp:recv(Sock2, 0) of
		{ok, V} -> 
			Result = V;
		{error, _Result} ->
			Result = <<"ko">>
	end,
	gen_tcp:close(Sock2),
	?assertEqual(Result, <<"ok\n5;19,0\n6;0,0\n">> ).

test_pos(_Config) ->
	{ok, Sock1} = gen_tcp:connect("localhost", 5678, [binary, {packet, raw}, {active, false}]),
	{ok, Sock2} = gen_tcp:connect("localhost", 5678, [binary, {packet, raw}, {active, false}]),
	gen_tcp:send(Sock1, <<"ok">>),
	gen_tcp:recv(Sock1, 0),
	gen_tcp:send(Sock2, <<"ok">>),
	gen_tcp:recv(Sock2, 0),
	gen_tcp:recv(Sock1, 0),
	gen_tcp:recv(Sock2, 0),
	gen_tcp:send(Sock1, <<"0,1">>),
	case gen_tcp:recv(Sock1, 0) of
		{ok, V2} -> 
			Result2 = V2;
		{error, _Result2} ->
			Result2 = <<"ko">>
	end,
	gen_tcp:close(Sock1),
	gen_tcp:close(Sock2),
	?assertEqual(Result2, <<"1;0,1\n">> ).

test_pos2(_Config) ->
	{ok, Sock1} = gen_tcp:connect("localhost", 5678, [binary, {packet, raw}, {active, false}]),
	{ok, Sock2} = gen_tcp:connect("localhost", 5678, [binary, {packet, raw}, {active, false}]),
	gen_tcp:send(Sock1, <<"ok">>),
	gen_tcp:recv(Sock1, 0),
	gen_tcp:send(Sock2, <<"ok">>),
	gen_tcp:recv(Sock2, 0),
	gen_tcp:recv(Sock1, 0),
	gen_tcp:recv(Sock2, 0),
	gen_tcp:send(Sock2, <<"0,-1">>),
	case gen_tcp:recv(Sock1, 0) of
		{ok, V2} -> 
			Result2 = V2;
		{error, _Result2} ->
			Result2 = <<"ko">>
	end,
	gen_tcp:close(Sock1),
	gen_tcp:close(Sock2),
	?assertEqual(Result2, <<"2;0,-1\n">> ).
