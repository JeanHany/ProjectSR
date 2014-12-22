%% Server take in doc erlang
-module(serverErlang).

-behavior(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/0, server/1, loop/1]).

-record(state, {nbplayer = 0, player1, mapPosId, mapSocketId, mapScore, player2, player3, socket1, socket2, socket3, points, nbpas=0, nbsweet1=0, nbsweet2=0, nbsweet3=0}).
-type state() :: #state{}.
-record(point, {coordX, coordY}).
-record(playercoord, {nbplayer, coord, nbsweet}).

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%TODO : Init table mnesia in disc
%% gerer tt les state
-spec init([]) -> {ok, state()}.
init([]) ->
	io:format("Init", []),
	start_s(),
	create_table(),
	State = #state{},
	{ok, State}.

%%Send la position aux differents players
send_position(S, Id) -> gen_server:call(?MODULE, {send_position, [S, Id]}).

%%Test calcul les nouvelles position
test_position(S, Pos) -> gen_server:call(?MODULE, {test_position, [S, Pos]}).

%%Set les points generer aleatoirement
set_point(Point) -> gen_server:call(?MODULE, {set_point, [Point]}).

%%TODO passe pos entre fonction
handle_call({test_position, [S, Pos]}, _From, #state{player1=_P1, mapPosId=MapPos, mapSocketId = MapSock, player2=_P2, player3=_P3, socket1=_Socket1, socket2=_Socket2, socket3=_Socket3, points=Points,
													 mapScore= MapScore, nbsweet1=Nb1, nbsweet2=Nb2, nbsweet3=Nb3, nbpas=Nbpas, nbplayer=_Nbplay}=State) ->
	
	[X, Y] = binary:split(Pos, <<",">>),
	X1 = list_to_integer(binary_to_list(X)),
	Y1 = list_to_integer(binary_to_list(Y)),
	Id = maps:get(S, MapSock),
	LastPos = maps:get(Id, MapPos),
	ListPos = maps:values(MapPos),
	%% 	case S of
	%% 		Socket1 ->
	New_pos = calcul_newPos(LastPos, X1, Y1),
	case lists:member(New_pos, ListPos) of
		true -> 
			Reply = ko,
			State2 = State;
		false -> 					
			Reply = ok,
			MapNPos = maps:put(Id, New_pos, MapPos),
			{NewPoint, Nb12, Nbpas2, Nbplay2, Nb22, Nb33, NewMapSc} = new_position(MapScore, MapSock, Pos, Nb1, Points, Nb2, Nb3, New_pos, Nbpas, Id),
			%%TODO change pos player
			State2 = State#state{player1=New_pos, points=NewPoint, nbsweet1=Nb12, nbsweet2=Nb22, nbsweet3=Nb33,  mapScore= NewMapSc,
								 nbpas=Nbpas2, nbplayer=Nbplay2, mapPosId=MapNPos}
	end,
	{reply, Reply, State2};
handle_call({set_point, [Point]}, _From, #state{points=Points, nbpas=Pas}=State) ->	
	Reply = ok,
	Pas2 = Pas+1,
	if
		Pas2 == 1 ->
			State3 = State#state{points=Point, nbpas=Pas2};
		Pas2 =< 10 ->
			Pointbin = binary:split(Points, <<";">>, [global]),
			case lists:member(Point, Pointbin) of
				false -> Points2 = <<Points/binary, <<";">>/binary, Point/binary>>;				
				true -> Points2 = Points
			end,
			State3 = State#state{points=Points2, nbpas=Pas2};
		true -> State3 = State
	end,
	{reply, Reply, State3};
handle_call({send_position, [S, Id]}, _From, #state{mapScore= MapScore, mapPosId=MapPos, mapSocketId=MapId, nbplayer=Nbj, player1=_Pos_play1, player2=_Pos_player2, socket1=S1, socket2=_S2, points=Points}=State) ->
	Reply = ok,
	Nbj2 = Nbj+1,
	if
		Nbj2 == 1 ->
			Pos2 = << <<"5;">>/binary, Id/binary, <<";0,0\n">>/binary >>,
			Pos21 = <<"0,0">>,
			PlayC = #playercoord{nbplayer=1, coord= Pos21, nbsweet=0},
			mnesia:dirty_write(PlayC),
			send_pos(Pos2, S),
			Map = maps:new(),
			Map1 = maps:put(S, Id, Map),
			Map11 = maps:new(),
			Map12 = maps:put(Id, Pos21, Map11),
			Map13 = maps:new(),
			Map14 = maps:put(Id, 0, Map13),
			State2 = State#state{nbplayer=Nbj2, player1=Pos21, socket1=S, mapSocketId = Map1, mapPosId=Map12, mapScore=Map14},
			{reply, Reply, State2};
		Nbj2 == 2 -> 
			Pos2 = << <<"5;">>/binary, Id/binary, <<";19,0\n">>/binary >>,
			Pos22 = << <<"5;">>/binary, Id/binary, <<";19,0\n">>/binary >>,
			Pos21 = <<"19,0">>,
			PlayC = #playercoord{nbplayer=2, coord= Pos21, nbsweet=0},
			mnesia:dirty_write(PlayC),			
			send_pos(Pos2, S),
			send_pos(Pos22, S1),
			[Id1 | _T] = maps:values(MapId),
			Pos212 = << <<"5;">>/binary, Id1/binary, <<";0,0\n">>/binary>>,
			send_pos(Pos212, S),
			Points3 = << <<"7;">>/binary, Points/binary, <<"\n">>/binary>>,
			io:format("Point All ~p~n", [Points3]),
			send_pos(Points3, S1),
			send_pos(Points3, S),
			Pointbin1 = binary:split(Points, <<";">>, [global]),
			Map2 = maps:put(S, Id, MapId),
			Map21 = maps:put(Id, Pos21, MapPos),
			Map31 = maps:put(Id, 0, MapScore),
			State3 = State#state{nbplayer=Nbj2, player2=Pos21, socket2=S, points=Pointbin1, mapSocketId = Map2, mapPosId=Map21, mapScore=Map31},
			{reply, Reply, State3};
		Nbj2 == 3 -> 
			Pos2 = << <<"5;">>/binary, Id/binary, <<";0,19\n">>/binary >>,
			IdPlayer = maps:keys(MapPos),
			Sockets = maps:keys(MapId),
			
			lists:foreach(fun(Sock) ->
								  gen_tcp:send(Sock, Pos2)
						  end, Sockets),
			Pos31 = <<"0,19">>,
			PlayC = #playercoord{nbplayer=3, coord= Pos31, nbsweet=0},
			mnesia:dirty_write(PlayC),	
			%% Send pos au 3 Client
			send_pos(Pos2, S),
			%% Send Pos client 3 			
			lists:foreach(fun(Player) -> 
								  Pospl = maps:get(Player, MapPos),			  
								  PosPlayer = << <<"5;">>/binary, Player/binary, <<";">>/binary, Pospl/binary,<<"\n">>/binary >>,
								  send_pos(PosPlayer, S)
						  end, IdPlayer),
			Map21 = maps:put(Id, Pos31, MapPos),
			Map2 = maps:put(S, Id, MapId),
			Map31 = maps:put(Id, 0, MapScore),
			Pointbin12 = parse_list(Points),
			Pointbin123 = << <<"7;">>/binary, Pointbin12/binary>>,
			send_pos(Pointbin123, S),
			State3 = State#state{nbplayer=Nbj2, player3=Pos31, socket3=S,  mapSocketId = Map2, mapPosId=Map21, mapScore=Map31},
			{reply, Reply, State3};
		true -> 
			X = random:uniform(20) -1,
			Y = random:uniform(20) -1,
			X1 = list_to_binary(integer_to_list(X)),
			Y2 = list_to_binary(integer_to_list(Y)),
			Pos2 = << <<"5;">>/binary, Id/binary, <<";">>/binary, X1/binary,<<",">>/binary, Y2/binary, <<"\n">>/binary >>,
			IdPlayer = maps:keys(MapPos),
			Sockets = maps:keys(MapId),			
			lists:foreach(fun(Sock) ->
								  gen_tcp:send(Sock, Pos2)
						  end, Sockets),
			Pos31 = <<X1/binary,<<",">>/binary, Y2/binary>>,
			PlayC = #playercoord{nbplayer=Nbj2, coord= Pos31, nbsweet=0},
			mnesia:dirty_write(PlayC),
			send_pos(Pos2, S),	
			lists:foreach(fun(Player) -> 
								  Pospl = maps:get(Player, MapPos),			  
								  PosPlayer = << <<"5;">>/binary, Player/binary, <<";">>/binary, Pospl/binary,<<"\n">>/binary >>,
								  send_pos(PosPlayer, S)
						  end, IdPlayer),
			Map21 = maps:put(Id, Pos31, MapPos),
			Map2 = maps:put(S, Id, MapId),
			Map31 = maps:put(Id, 0, MapScore),
			Pointbin12 = parse_list(Points),
			Pointbin123 = << <<"7;">>/binary, Pointbin12/binary>>,
			send_pos(Pointbin123, S),
			State3 = State#state{nbplayer=Nbj2,  mapSocketId = Map2, mapPosId=Map21, mapScore=Map31},
			{reply, Reply, State3}
	end;
handle_call(_Call, _From, State) -> {reply, ko, State}.

-spec handle_info({nodedown, atom()}, state()) -> {stop, nodedown, state()} | {noreply, state()}.
handle_info(_Info, State) ->
	{noreply, State}.

%% @private
-spec handle_cast(term(), state()) -> {noreply, state()}.
handle_cast(_Msg, State) -> {noreply, State}.
%% @private
-spec terminate(_, state()) -> ok.
terminate(_Reason, _State) -> ok.
%% @private
-spec code_change(term(), state(), term()) -> {ok, state()}.
code_change(_OldVersion, State, _Extra) -> {ok, State}.

%%Listener sur le port 5678
start_s() ->
	case gen_tcp:listen(5678, [binary, {packet, 0}, 
							   {active, false}]) of
		{ok, ListenSock} ->
			start_servers(ListenSock);
		{error,Reason} ->
			{error,Reason}
	end.

start_servers(LS) ->
	spawn(?MODULE,server,[LS]).

server(LS) ->
	case gen_tcp:accept(LS) of
		{ok,S} ->
			spawn(?MODULE, loop, [S]),
			io:format("Socket ~p~n", [S]),
			server(LS);
		Other ->
			io:format("accept returned ~w - goodbye!~n",[Other]),
			ok
	end.

%%TODO : Test position et send ok or ko case other down top left right
loop(S) ->
	case gen_tcp:recv(S, 0) of
		{ok, Data} ->
			case Data of					
				<<"ok">> ->
					case gen_tcp:recv(S, 0) of
						{ok, Data1} ->
							gen_tcp:send(S, <<"ok\n">>),
							send_position(S, Data1),
							put_coordonnees(10);
						{error, closed} ->
							io:format("Socket ~w closed [~w]~n",[S,self()]),
							ok
					end;
				<<"newgame">> ->
					restart(S);
				Other -> 	
					test_position(S, Other)
			end,
			loop(S);
		{error, closed} ->
			io:format("Socket ~w closed [~w]~n",[S,self()]),
			ok
	end.

%%Faulth tolerance save in disc
create_table() ->
	io:format("Create table ~n", []),
	%% 	mnesia:create_schema([node()]),
	mnesia:start(),
	%% 	{disc_copies, [node()]}, {disc_copies, [node()]},
	Table = [
			 {attributes, record_info(fields, point)}],
	Table1 = [
			  {attributes, record_info(fields, playercoord)}],
	Test = mnesia:create_table(point , Table),							  
	io:format("Create table ~p~n", [Test]),
	mnesia:create_table(playercoord, Table1).

%%TODO check if already exist and random uniform
put_coordonnees(0) ->
	ok;
put_coordonnees(N) ->	
	X = random:uniform(20) -1,
	Y = random:uniform(20) -1,
	S1 = list_to_binary(integer_to_list(X)),
	S2 = list_to_binary(integer_to_list(Y)),
	Point = #point{coordX=S1, coordY=S2},
	mnesia:dirty_write(Point),
	Point2 = <<S1/binary,<<",">>/binary, S2/binary>>,
	set_point(Point2),
	put_coordonnees(N-1).

send_pos(Pos, S) ->
	io:format("Send socket ~p~n", [Pos]),
	gen_tcp:send(S, Pos).

mod(X,Y) when X > 0 -> X rem Y;
mod(X,Y) when X < 0 -> Y + X rem Y;
mod(0,_Y) -> 0.

%%Envoie la nouvelle position aux players
new_position(MapScore, MapSock, Pos, Nb1, Points, Nb2, Nb3, New_pos, Nbpas, Id) ->
	Posnew = << Id/binary, <<";">>/binary, Pos/binary, <<"\n">>/binary>>,
	Sockets = maps:keys(MapSock),
	lists:foreach(fun(Sock) ->
						  gen_tcp:send(Sock, Posnew)
				  end, Sockets),
	case lists:member(New_pos, Points) of
		true -> {Nb12, NewPoint, Nbpas2, Nbplay2, Nb22, Nb32, NewMapSc} = test_point(MapScore, Sockets, New_pos, Points, Nb1, Nb2, Nb3, Id, Nbpas);
		false ->
			Nbplay2 = 3,
			Nbpas2 = Nbpas,
			Nb12 = Nb1,
			Nb22 = Nb2,
			Nb32 = Nb3,
			NewPoint = Points,
			NewMapSc = MapScore
	end,
	{NewPoint, Nb12, Nbpas2, Nbplay2, Nb22, Nb32, NewMapSc}.

%%Test des point pour 3 player
%%TODO test les point
test_point(MapScore, Sockets, New_pos, Points, Nb1, Nb2, Nb3, Player, Nbpas) ->
	Nb12 = Nb1 + 1,
	Nb13 = list_to_binary(integer_to_list(Nb12)),
	Nb14 = maps:get(Player, MapScore),
	Nb15 = Nb14 + 1,
	Nb16 = list_to_binary(integer_to_list(Nb15)),
	Posnew3 = <<<<"3;">>/binary, New_pos/binary, <<";">>/binary, Nb16/binary, <<";">>/binary, Player/binary, <<"\n">>/binary>>,
	NewPoint = lists:delete(New_pos, Points),
	lists:foreach(fun(Sock) ->
						  gen_tcp:send(Sock, Posnew3)
				  end, Sockets),
	NewMapSc = maps:update(Player, Nb15, MapScore),
	case lists:flatlength(NewPoint) of
		0 ->
			Nbpas2 = 0,
			Nbplay2 = 0,
			ListScore = maps:values(MapScore),
			MaxScore = lists:max(ListScore),
			PlayerMax = maps:to_list(MapScore),
			lists:foreach(fun(Play) -> 
								  case Play of
									  {Value, MaxScore} -> 
										  Posnew4 = << <<"4;">>/binary, Value/binary, <<"\n">>/binary >>,
										  lists:foreach(fun(Sock) ->
																gen_tcp:send(Sock, Posnew4)
														end, Sockets);
									  	_ -> io:format("Error")
								  end
						  end, PlayerMax),
			
			Nb122 = 0,
			Nb22 = 0,
			Nb33 = 0;
		Nb -> 
			Nb122 = Nb12,
			Nb22 = Nb2,
			Nb33 = Nb3,
			Nbplay2 = 3,
			Nbpas2 = Nbpas,
			io:format("Point +1 ~p ~n", [Nb])
	end,
	{Nb122, NewPoint, Nbpas2, Nbplay2, Nb22, Nb33, NewMapSc}.

calcul_newPos(P1, X1, Y1) ->
	[X11, Y11] = binary:split(P1, <<",">>),
	X12 = list_to_integer(binary_to_list(X11)),
	Y12 = list_to_integer(binary_to_list(Y11)),
	X2 = mod(X12+X1, 20),
	Y2 = mod(Y12+Y1, 20),
	S1 = list_to_binary(integer_to_list(X2)),
	S2 = list_to_binary(integer_to_list(Y2)),
	<<S1/binary, <<",">>/binary, S2/binary>>.

%%TODO erase table, new point, Put Id, Check bug
restart(Socket) ->	
	put_coordonnees(10),
	gen_tcp:send(Socket, <<"ok\n">>),
	send_position(Socket, <<"player">>).

parse_list(List) ->
	lists:foldr(fun(X, Bina) -> 
						if
							Bina == <<"\n">> ->
								<<X/binary, Bina/binary>>;
							true -> 
								<<X/binary, <<";">>/binary, Bina/binary>>
						end end, <<"\n">>, List).