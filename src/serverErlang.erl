%% Server take in doc erlang
-module(serverErlang).

-behavior(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/0, server/1, loop/1]).
%% -export([add_player/1, send_position/1, test_position/2, get_state/0]).

-record(state, {nbplayer = 0, player1, player2, socket1, socket2, points, nbpas=0}).
-type state() :: #state{}.
-record(point, {coordX, coordY}).
-record(playercoord, {nbplayer, coord, nbsweet}).

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() -> gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%TODO : Init table mnesia and finish the game and remove point in state et mettre nb sweet by player
%% gerer tt les state
-spec init([]) -> {ok, state()}.
init([]) ->
	io:format("Init", []),
	start_s(),
	create_table(),
%% 	put_coordonnees(10), Voir ou le mettre
	State = #state{},
%% 	{reply, _Reply, State} = get_state(),
	{ok, State}.

add_player(S) -> gen_server:call(?MODULE, {add_player, [S]}).

send_position(S) -> gen_server:call(?MODULE, {send_position, [S]}).

test_position(S, Pos) -> gen_server:call(?MODULE, {test_position, [S, Pos]}).

set_point(Point) -> gen_server:call(?MODULE, {set_point, [Point]}).

%% get_state() -> gen_server:call(?MODULE, {get_state}).

handle_call({test_position, [S, Pos]}, _From, #state{player1=P1, player2=P2, socket1=Socket1, socket2=Socket2, points=Points}=State) ->
    
	[X, Y] = binary:split(Pos, <<",">>),
	X1 = list_to_integer(binary_to_list(X)),
	Y1 = list_to_integer(binary_to_list(Y)),
	case S of
		Socket1 ->
			[X11, Y11] = binary:split(P1, <<",">>),
			X12 = list_to_integer(binary_to_list(X11)),
			Y12 = list_to_integer(binary_to_list(Y11)),
			X2 = mod(X12+X1, 20),
			Y2 = mod(Y12+Y1, 20),
			%% 			New_pos = {element(1, P1)+X1, element(2, P1)+Y1},
			S1 = list_to_binary(integer_to_list(X2)),
			S2 = list_to_binary(integer_to_list(Y2)),
			New_pos = <<S1/binary, <<",">>/binary, S2/binary>>,
			%% 			io:format("New pos 1 ~p ~n", [P2]),
			%% 			io:format("New pos 1 ~p ~n", [New_pos]),
			if
				P2 == New_pos -> 
					Reply = ko,
					State2 = State;
				true -> 
					
					Reply = ok,
					%% Calculer new pos														
					
					Posnew = <<<<"1;">>/binary, Pos/binary, <<"\n">>/binary>>,
					Posnew2 = <<<<"2;">>/binary, Pos/binary, <<"\n">>/binary>>,								
					gen_tcp:send(Socket1, Posnew),
					gen_tcp:send(Socket2, Posnew2),
					
					case lists:member(New_pos, Points) of
						true -> Posnew3 = <<<<"3;">>/binary, New_pos/binary, <<"\n">>/binary>>,
								NewPoint = lists:delete(New_pos, Points),
								gen_tcp:send(Socket1, Posnew3),
								gen_tcp:send(Socket2, Posnew3),
								case lists:flatlength(NewPoint) of
									0 ->
										Posnew4 = <<"4; fini\n">>,
										gen_tcp:send(Socket1, Posnew4),
										gen_tcp:send(Socket2, Posnew4);
									Nb -> io:format("Point +1 ~p ~n", [Nb])
								end;
						
						false ->
							NewPoint = Points,
							io:format("No Point  ~n", [])
					end,
					State2 = State#state{player1=New_pos, points=NewPoint}
			end;
		Socket2 ->   
			[X11, Y11] = binary:split(P2, <<",">>),
			X12 = list_to_integer(binary_to_list(X11)),
			Y12 = list_to_integer(binary_to_list(Y11)),
			X2 = mod(X12+X1, 20),
			Y2 = mod(Y12+Y1, 20),
%% 			New_pos = {element(1, P1)+X1, element(2, P1)+Y1},
			S1 = list_to_binary(integer_to_list(X2)),
			S2 = list_to_binary(integer_to_list(Y2)),
%% 			New_pos = {element(1, P1)+X1, element(2, P1)+Y1},
			New_pos = <<S1/binary, <<",">>/binary, S2/binary>>,
					if
						P1 == New_pos -> 
							Reply = ko,
									 State2 = State;
						true -> 
								Reply = ok,
								State2 = State#state{player2=New_pos},
								Posnew = <<<<"1;">>/binary, Pos/binary, <<"\n">>/binary>>,
								Posnew2 = <<<<"2;">>/binary, Pos/binary, <<"\n">>/binary>>,
%% 								io:format("New pos ~p ~n", [Posnew]),
								gen_tcp:send(Socket2, Posnew),
								gen_tcp:send(Socket1, Posnew2),
								case lists:member(New_pos, Points) of
										true -> Posnew3 = <<<<"3;">>/binary, New_pos/binary, <<"\n">>/binary>>,
												NewPoint = lists:delete(New_pos, Points),
												gen_tcp:send(Socket1, Posnew3),
												gen_tcp:send(Socket2, Posnew3),
									case lists:flatlength(NewPoint) of
									0 ->
										Posnew4 = <<"4; fini\n">>,
										gen_tcp:send(Socket1, Posnew4),
										gen_tcp:send(Socket2, Posnew4);
									Nb -> io:format("Point +1 ~p ~n", [Nb])
										end;
										false ->
											NewPoint = Points,
												io:format("No Point ~n", [])
							end,
					State2 = State#state{player1=New_pos, points=NewPoint}
					end
	end,
    {reply, Reply, State2};
handle_call({add_player, [S]}, _From, #state{nbplayer=Nbj}=State) ->
	io:format("Add player ~p~n", [S]),
    Reply = ok,
	Nbj2 = Nbj+1,
%% 	Points = mnesia:dirty_read(point),
%% 	io:format("Point All ~p~n", [Points]),
	State3 = State#state{nbplayer=Nbj2},
    {reply, Reply, State3};
handle_call({set_point, [Point]}, _From, #state{points=Points, nbpas=Pas}=State) ->	
    Reply = ok,
	Pas2 = Pas+1,
	if
		Pas2 == 1 ->
			State3 = State#state{points=Point, nbpas=Pas2};
		Pas2 =< 10 ->
			Points2 = <<Points/binary, <<";">>/binary, Point/binary>>,
			io:format("Set point ~p~n", [Points2]),
			State3 = State#state{points=Points2, nbpas=Pas2};
		true -> State3 = State
	end,
    {reply, Reply, State3};
handle_call({send_position, [S]}, _From, #state{nbplayer=Nbj, player1=_Pos_play1, socket1=S1, points=Points}=State) ->
    Reply = ok,
	if
		Nbj == 1 ->
%% 			io:format("Nb joueur ~p~n", [Nbj]),
%% 			Pos = {1, 1},
			Pos2 = <<"0,0\n">>,
			Pos21 = <<"0,0">>,
			PlayC = #playercoord{nbplayer=1, coord= Pos21, nbsweet=0},
			mnesia:dirty_write(PlayC),
			send_pos(Pos2, S),
			State2 = State#state{player1=Pos21, socket1=S},
			{reply, Reply, State2};
		Nbj == 2 -> 
%% 			io:format("Nb joueur ~p~n", [Nbj]),
%% 			Pos1 = {19, 19},
			Pos2 = <<"19,0\n">>,
			Pos21 = <<"19,0">>,
			PlayC = #playercoord{nbplayer=2, coord= Pos21, nbsweet=0},
			mnesia:dirty_write(PlayC),			
			send_pos(Pos2, S),
			send_pos(Pos2, S1),
%% 			send_pos(<<"2">>, S),
%% 			Pos_play12 = <<element(1, Pos_play1), >>,
			Pos212 = <<"0,0\n">>,
			send_pos(Pos212, S),
%% 			Points2 = list_to_binary(Points),
			Points3 = <<Points/binary, <<"\n">>/binary>>,
			io:format("Point All ~p~n", [Points3]),
			send_pos(Points3, S1),
			send_pos(Points3, S),
			Pointbin = binary:split(Points, <<";">>, [global]),
			State3 = State#state{player2=Pos21, socket2=S, points=Pointbin},
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
			add_player(S),
            spawn(?MODULE, loop, [S]),
			io:format("Socket ~p~n", [S]),
%% 			send_position(S),
            server(LS);
        Other ->
            io:format("accept returned ~w - goodbye!~n",[Other]),
            ok
    end.

%%TODO : Test position et send ok or ko case down top left right
loop(S) ->
    case gen_tcp:recv(S, 0) of
        {ok,Data} ->
            io:format("Test ~p~n", [Data]),
				case Data of					
            		<<"ok">> -> 
							  gen_tcp:send(S, <<"ok\n">>),
							  send_position(S),
							  put_coordonnees(10);
					Other -> 	
								test_position(S, Other)
%% 								case Reply of
%% 									ko -> gen_tcp:send(S, "ko\n");
%% 									ok -> gen_tcp:send(S, "ok\n")
%% 								end
				end,
            loop(S);
        {error, closed} ->
            io:format("Socket ~w closed [~w]~n",[S,self()]),
            ok
    end.

create_table() ->
	io:format("Create table ~n", []),
%% 	{ok, Pwd} = file:get_cwd(),
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

put_coordonnees(0) ->
	ok;
put_coordonnees(N) ->	
	X = random:uniform(20),
	Y = random:uniform(20),
	S1 = list_to_binary(integer_to_list(X)),
	S2 = list_to_binary(integer_to_list(Y)),
%% 	Pos = <<S1/binary, <<",">>/binary , S2/binary>>,
%% 	io:format("Put Position ~p~n", [Pos]),
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