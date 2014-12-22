%% Server take in doc erlang
-module(serverErlang).

-behavior(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/0, server/1, loop/1]).

-record(state, {nbplayer = 0, player1, mapSocketId, player2, player3, socket1, socket2, socket3, points, nbpas=0, nbsweet1=0, nbsweet2=0, nbsweet3=0}).
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

handle_call({test_position, [S, Pos]}, _From, #state{player1=P1, mapSocketId =Id1, player2=P2, player3=P3, socket1=Socket1, socket2=Socket2, socket3=Socket3, points=Points,
													 nbsweet1=Nb1, nbsweet2=Nb2, nbsweet3=Nb3, nbpas=Nbpas, nbplayer=Nbplay}=State) ->
	
	[X, Y] = binary:split(Pos, <<",">>),
	X1 = list_to_integer(binary_to_list(X)),
	Y1 = list_to_integer(binary_to_list(Y)),
	Id = maps:get(S, Id1),
	case S of
		Socket1 ->
			New_pos = calcul_newPos(P1, X1, Y1),
			if
				P2 == New_pos -> 
					Reply = ko,
					State2 = State;
				P3 == New_pos ->
					Reply = ko,
					State2 = State;
				true -> 					
					Reply = ok,													
					{NewPoint, Nb12, Nbpas2, Nbplay2, Nb22, Nb33} = new_position(Pos, Socket1, Socket2, Socket3, Nb1, Points, Nb2, Nb3, <<"1">>, New_pos, Nbpas, Id, Nbplay),					
					State2 = State#state{player1=New_pos, points=NewPoint, nbsweet1=Nb12, nbsweet2=Nb22, nbsweet3=Nb33, nbpas=Nbpas2, nbplayer=Nbplay2}
			end;
		Socket2 ->   
			New_pos = calcul_newPos(P2, X1, Y1),
			if
				P1 == New_pos -> 
					Reply = ko,
					State2 = State;
				P3 == New_pos ->
					Reply = ko,
					State2 = State;
				true -> 
					Reply = ok,
					{NewPoint, Nb12, Nbpas2, Nbplay2, Nb22, Nb33} = new_position(Pos, Socket2, Socket1, Socket3, Nb2, Points, Nb1, Nb3, <<"2">>, New_pos, Nbpas, Id, Nbplay),					
					State2 = State#state{player2=New_pos, points=NewPoint, nbsweet2=Nb12, nbsweet1=Nb22, nbpas=Nbpas2, nbplayer=Nbplay2, nbsweet3=Nb33}
			end;
		Socket3 ->
			New_pos = calcul_newPos(P3, X1, Y1),
			if
				P2 == New_pos -> 
					Reply = ko,
					State2 = State;
				P1 == New_pos ->
					Reply = ko,
					State2 = State;
				true -> 					
					Reply = ok,													
					{NewPoint, Nb12, Nbpas2, Nbplay2, Nb112, Nb22} = new_position(Pos, Socket3, Socket1, Socket2, Nb3, Points, Nb1, Nb2, <<"3">>, New_pos, Nbpas, Id1, Nbplay),					
					State2 = State#state{player3=New_pos, points=NewPoint, nbsweet1=Nb112, nbsweet2=Nb22, nbsweet3=Nb12, nbpas=Nbpas2, nbplayer=Nbplay2}
			end
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
handle_call({send_position, [S, Id]}, _From, #state{mapSocketId =MapId, nbplayer=Nbj, player1=Pos_play1, player2=Pos_player2, socket1=S1, socket2=S2, points=Points}=State) ->
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
			State2 = State#state{nbplayer=Nbj2, player1=Pos21, socket1=S, mapSocketId = Map1},
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
%% 			Id11 = list_to_binary(Id1),
			Pos212 = << <<"5;">>/binary, Id1/binary, <<";0,0\n">>/binary>>,
			send_pos(Pos212, S),
			Points3 = << <<"7;">>/binary, Points/binary, <<"\n">>/binary>>,
			io:format("Point All ~p~n", [Points3]),
			send_pos(Points3, S1),
			send_pos(Points3, S),
			Pointbin1 = binary:split(Points, <<";">>, [global]),
			Map2 = maps:put(S, Id, MapId),
			State3 = State#state{nbplayer=Nbj2, player2=Pos21, socket2=S, points=Pointbin1, mapSocketId = Map2},
			{reply, Reply, State3};
		Nbj2 == 3 -> 
			Pos2 = <<"5;0,19\n">>,
			Pos22 = <<"8;0,19\n">>,
			Pos31 = <<"0,19">>,
			PlayC = #playercoord{nbplayer=3, coord= Pos31, nbsweet=0},
			mnesia:dirty_write(PlayC),	
			%% Send pos au 3 Client
			send_pos(Pos2, S),
			send_pos(Pos22, S1),
			send_pos(Pos22, S2),
			%% Send Pos client 3 
			Pos312 = << <<"6;">>/binary,Pos_play1/binary,<<"\n">>/binary>>,
			Pos213 = << <<"8;">>/binary,Pos_player2/binary,<<"\n">>/binary>>,
			send_pos(Pos312, S),
			send_pos(Pos213, S),
			Pointbin12 = parse_list(Points),
			Pointbin123 = << <<"7;">>/binary, Pointbin12/binary>>,
			send_pos(Pointbin123, S),
			State3 = State#state{nbplayer=Nbj2, player3=Pos31, socket3=S},
			{reply, Reply, State3};
		true -> error_logger:info_msg("Full player ~p", []),
				{reply, Reply, State}
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
new_position(Pos, Socket1, Socket2, Socket3, Nb1, Points, Nb2, Nb3, Player, New_pos, Nbpas, Id, 3) ->
	Posnew = <<<<"1;">>/binary, Pos/binary, <<"\n">>/binary>>,
	Posnew2 = <<<<"2;">>/binary, Pos/binary, <<"\n">>/binary>>,		
	Posnew3 = <<<<"9;">>/binary, Pos/binary, <<"\n">>/binary>>,
	case Player of
		<<"1">> -> 
			Posnew = << Id/binary, <<";">>/binary, Pos/binary, <<"\n">>/binary>>,
			Posnew2 = << Id/binary, <<";">>/binary, Pos/binary, <<"\n">>/binary>>,		
			gen_tcp:send(Socket1, Posnew),
			gen_tcp:send(Socket2, Posnew2),	
			gen_tcp:send(Socket3, Posnew2);
		<<"2">> ->
			Posnew = <<<<"1;">>/binary, Pos/binary, <<"\n">>/binary>>,
			Posnew2 = <<<<"2;">>/binary, Pos/binary, <<"\n">>/binary>>,		
			Posnew3 = <<<<"9;">>/binary, Pos/binary, <<"\n">>/binary>>,
			gen_tcp:send(Socket1, Posnew),
			gen_tcp:send(Socket2, Posnew2),	
			gen_tcp:send(Socket3, Posnew3);
		<<"3">> ->
			Posnew = <<<<"1;">>/binary, Pos/binary, <<"\n">>/binary>>,	
			Posnew3 = <<<<"9;">>/binary, Pos/binary, <<"\n">>/binary>>,
			gen_tcp:send(Socket1, Posnew),
			gen_tcp:send(Socket2, Posnew3),	
			gen_tcp:send(Socket3, Posnew3)
	end,
	case lists:member(New_pos, Points) of
		true -> {Nb12, NewPoint, Nbpas2, Nbplay2, Nb22, Nb32} = test_point3(Socket1, Socket2, Socket3, New_pos, Points, Nb1, Nb2, Nb3, Player, Nbpas, 3);
		false ->
			Nbplay2 = 3,
			Nbpas2 = Nbpas,
			Nb12 = Nb1,
			Nb22 = Nb2,
			Nb32 = Nb3,
			NewPoint = Points
	end,
	{NewPoint, Nb12, Nbpas2, Nbplay2, Nb22, Nb32};
new_position(Pos, Socket1, Socket2, _Socket3, Nb1, Points, Nb2, Nb3, Player, New_pos, Nbpas, Id, 2) ->
	Posnew = << Id/binary, <<";">>/binary, Pos/binary, <<"\n">>/binary>>,
	Posnew2 = << Id/binary, <<";">>/binary, Pos/binary, <<"\n">>/binary>>,		
	gen_tcp:send(Socket1, Posnew),
	gen_tcp:send(Socket2, Posnew2),	
	case lists:member(New_pos, Points) of
		true -> {Nb12, NewPoint, Nbpas2, Nbplay2, Nb22} = test_point2(Socket1, Socket2,  New_pos, Points, Nb1, Nb2, Player, Nbpas, 2);
		false ->
			Nbplay2 = 2,
			Nbpas2 = Nbpas,
			Nb12 = Nb1,
			Nb22 = Nb2,
			NewPoint = Points
	end,
	{NewPoint, Nb12, Nbpas2, Nbplay2, Nb22, Nb3}.

%%Test des point pour 2 player
test_point2(Socket1, Socket2, New_pos, Points, Nb1, Nb2, Player, Nbpas, 2) ->
	Nb12 = Nb1 + 1,
	Nb13 = list_to_binary(integer_to_list(Nb12)),
	Posnew3 = <<<<"3;">>/binary, New_pos/binary, <<";">>/binary, Nb13/binary, <<";">>/binary, Player/binary, <<"\n">>/binary>>,
	NewPoint = lists:delete(New_pos, Points),
	gen_tcp:send(Socket1, Posnew3),
	gen_tcp:send(Socket2, Posnew3),
	case lists:flatlength(NewPoint) of
		0 ->
			Nbpas2 = 0,
			Nbplay2 = 0,
			if
				Nb12 > Nb2 ->	Posnew4 = << <<"4;">>/binary, Player/binary, <<"\n">>/binary >>,
								Posnew5 = <<"4;other\n">>,
								gen_tcp:send(Socket1, Posnew4),
								gen_tcp:send(Socket2, Posnew5);
				Nb12 == Nb2 -> 	Posnew4 = <<"4;equals\n">>,
								gen_tcp:send(Socket1, Posnew4),
								gen_tcp:send(Socket2, Posnew4);
				true -> 		Posnew4 = <<"4;other\n">>,
								Posnew5 = << <<"4;">>/binary, Player/binary, <<"\n">>/binary >>,
								gen_tcp:send(Socket1, Posnew4),
								gen_tcp:send(Socket2, Posnew5)
			end,
			Nb122 = 0,
			Nb22 = 0;
		Nb -> 
			Nb122 = Nb12,
			Nb22 = Nb2,
			Nbplay2 = 2,
			Nbpas2 = Nbpas,
			io:format("Point +1 ~p ~n", [Nb])
	end,
	{Nb122, NewPoint, Nbpas2, Nbplay2, Nb22}.

%%Test des point pour 3 player
test_point3(Socket1, Socket2, Socket3, New_pos, Points, Nb1, Nb2, Nb3, Player, Nbpas, 3) ->
	Nb12 = Nb1 + 1,
	Nb13 = list_to_binary(integer_to_list(Nb12)),
	Posnew3 = <<<<"3;">>/binary, New_pos/binary, <<";">>/binary, Nb13/binary, <<";">>/binary, Player/binary, <<"\n">>/binary>>,
	NewPoint = lists:delete(New_pos, Points),
	gen_tcp:send(Socket1, Posnew3),
	gen_tcp:send(Socket2, Posnew3),
	gen_tcp:send(Socket3, Posnew3),
	case lists:flatlength(NewPoint) of
		0 ->
			Nbpas2 = 0,
			Nbplay2 = 0,
			if
				(Nb12 > Nb2) and (Nb12 > Nb3) ->	
					Posnew4 = << <<"4;">>/binary, Player/binary, <<"\n">>/binary >>,
					Posnew5 = <<"4;other\n">>,
					gen_tcp:send(Socket1, Posnew4),
					gen_tcp:send(Socket2, Posnew5),
					gen_tcp:send(Socket3, Posnew5);
				(Nb12 == Nb2) and (Nb12 == Nb3) -> 	
					Posnew4 = <<"4;equals\n">>,
					gen_tcp:send(Socket1, Posnew4),
					gen_tcp:send(Socket2, Posnew4),
					gen_tcp:send(Socket3, Posnew4);
				(Nb2 > Nb3) and (Nb2 > Nb12) -> 					
					Posnew5 = << <<"4;">>/binary, Player/binary, <<"\n">>/binary >>,
					Posnew4 = <<"4;other\n">>,
					gen_tcp:send(Socket1, Posnew4),
					gen_tcp:send(Socket2, Posnew5),
					gen_tcp:send(Socket3, Posnew4);
				(Nb2 == Nb3) and (Nb2 > Nb12) -> 					
					Posnew5 = << <<"4;">>/binary, Player/binary, <<"\n">>/binary >>,
					Posnew4 = <<"4;other\n">>,
					gen_tcp:send(Socket1, Posnew4),
					gen_tcp:send(Socket2, Posnew5),
					gen_tcp:send(Socket3, Posnew4);
				(Nb2 == Nb3) and (Nb2 < Nb12) -> 					
					Posnew5 = << <<"4;">>/binary, Player/binary, <<"\n">>/binary >>,
					Posnew4 = <<"4;other\n">>,
					gen_tcp:send(Socket1, Posnew5),
					gen_tcp:send(Socket2, Posnew4),
					gen_tcp:send(Socket3, Posnew4);
				(Nb12 == Nb3) and (Nb12 > Nb2) -> 					
					Posnew5 = << <<"4;">>/binary, Player/binary, <<"\n">>/binary >>,
					Posnew4 = <<"4;other\n">>,
					gen_tcp:send(Socket1, Posnew5),
					gen_tcp:send(Socket2, Posnew4),
					gen_tcp:send(Socket3, Posnew5);
				(Nb12 == Nb3) and (Nb12 < Nb2) -> 					
					Posnew5 = << <<"4;">>/binary, Player/binary, <<"\n">>/binary >>,
					Posnew4 = <<"4;other\n">>,
					gen_tcp:send(Socket1, Posnew4),
					gen_tcp:send(Socket2, Posnew5),
					gen_tcp:send(Socket3, Posnew4);
				(Nb12 == Nb2) and (Nb2 > Nb3) -> 					
					Posnew5 = << <<"4;">>/binary, Player/binary, <<"\n">>/binary >>,
					Posnew4 = <<"4;other\n">>,
					gen_tcp:send(Socket1, Posnew5),
					gen_tcp:send(Socket2, Posnew5),
					gen_tcp:send(Socket3, Posnew4);
				(Nb12 == Nb2) and (Nb2 < Nb3) -> 					
					Posnew5 = << <<"4;">>/binary, Player/binary, <<"\n">>/binary >>,
					Posnew4 = <<"4;other\n">>,
					gen_tcp:send(Socket1, Posnew4),
					gen_tcp:send(Socket2, Posnew4),
					gen_tcp:send(Socket3, Posnew5);
				true ->							
					Posnew4 = <<"4;other\n">>,
					Posnew5 = << <<"4;">>/binary, Player/binary, <<"\n">>/binary >>,
					gen_tcp:send(Socket1, Posnew4),
					gen_tcp:send(Socket2, Posnew4),
					gen_tcp:send(Socket3, Posnew5)
			end,
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
	{Nb122, NewPoint, Nbpas2, Nbplay2, Nb22, Nb33}.

calcul_newPos(P1, X1, Y1) ->
	[X11, Y11] = binary:split(P1, <<",">>),
	X12 = list_to_integer(binary_to_list(X11)),
	Y12 = list_to_integer(binary_to_list(Y11)),
	X2 = mod(X12+X1, 20),
	Y2 = mod(Y12+Y1, 20),
	S1 = list_to_binary(integer_to_list(X2)),
	S2 = list_to_binary(integer_to_list(Y2)),
	<<S1/binary, <<",">>/binary, S2/binary>>.

%%TODO erase table, new point, Put Id
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