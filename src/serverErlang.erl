%% Server take in doc erlang
-module(serverErlang).

-behavior(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([start_link/0, server/1, loop/1, init_local/0]).

-record(state, {nbplayer = 0, mapPosId, mapSocketId, mapScore, points, nbpas = 0}).
-type state() :: #state{}.

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
  gen_server_cluster:start(?MODULE, ?MODULE, [], []).


-spec init([]) -> {ok, state()}.
init([]) ->
  io:format("Init", []),
  start_s(),
  State = #state{},
  {ok, State}.

init_local() ->
  io:format("Init local", []),
  start_s().

%%Send la position aux differents players
send_position(S, Id) -> gen_server:call({global, ?MODULE}, {send_position, [S, Id]}).

send_position(S) -> gen_server:call({global, ?MODULE}, {send_position, [S]}).

%%Test calcul les nouvelles position
test_position(S, Pos) -> gen_server:call({global, ?MODULE}, {test_position, [S, Pos]}).

%%Set les points genere aleatoirement
set_point(Point) -> gen_server:call({global, ?MODULE}, {set_point, [Point]}).

reconnect(S, Id) -> gen_server:call({global, ?MODULE}, {reconnect, [S, Id]}).

player_disconnect(S)->gen_server:call({global, ?MODULE}, {player_disconnect, [S]}).

handle_call({player_disconnect, [S]},_From, #state{ mapPosId = MapPos, mapSocketId = MapSock, nbplayer = Nbplay,
    mapScore = MapScore}=State) ->
  Id = maps:get(S, MapSock),
  MapPos2 = maps:remove(Id, MapPos),
  MapScore2 = maps:remove(Id, MapScore),
  MapSock2 = maps:remove(S, MapSock),
  Msg = <<<<"8;">>/binary,Id/binary, <<"\n">>/binary>>,
  Sockets = maps:keys(MapSock2),
  lists:foreach(fun(Sock) ->
    gen_tcp:send(Sock, Msg)
  end, Sockets),
  State2 = State#state{mapScore = MapScore2, nbplayer = Nbplay-1, mapPosId = MapPos2, mapSocketId = MapSock2},
  {reply, ok, State2};

%%TODO passe pos entre fonction
handle_call({test_position, [S, Pos]}, _From, #state{mapPosId = MapPos, mapSocketId = MapSock, points = Points,
  mapScore = MapScore, nbpas = Nbpas, nbplayer = _Nbplay} = State) ->
  [X, Y] = binary:split(Pos, <<",">>),
  X1 = list_to_integer(binary_to_list(X)),
  Y1 = list_to_integer(binary_to_list(Y)),
  Id = maps:get(S, MapSock),
  LastPos = maps:get(Id, MapPos),
  ListPos = maps:values(MapPos),
  New_pos = calcul_newPos(LastPos, X1, Y1),
  case lists:member(New_pos, ListPos) of
    true ->
      Reply = ko,
      State2 = State;
    false ->
      Reply = ok,
      MapNPos = maps:put(Id, New_pos, MapPos),
      {NewPoint, Nbpas2, Nbplay2, NewMapSc} = new_position(MapScore, MapSock, Pos, Points, New_pos, Nbpas, Id),
      State2 = State#state{points = NewPoint, mapScore = NewMapSc,
        nbpas = Nbpas2, nbplayer = Nbplay2, mapPosId = MapNPos}
  end,
  {reply, Reply, State2};

handle_call({set_point, [Point]}, _From, #state{points = Points, nbpas = Pas} = State) ->

  Pas2 = Pas + 1,
  if
    Pas2 == 1 ->
      ListPoint = [Point],
      State3 = State#state{points = ListPoint, nbpas = Pas2};

    Pas2 =< 10 ->
      case lists:member(Point, Points) of
        false -> Points2 = lists:append(Points,[Point]);
        true -> Points2 = Points
      end,
      State3 = State#state{points = Points2, nbpas = Pas2};
    true -> State3 = State
  end,
  {reply, ok, State3};

handle_call({send_position, [S, Id]}, _From, #state{mapScore = MapScore, mapPosId = MapPos, mapSocketId = MapId, nbplayer = Nbj, points = Points} = State) ->

  Pos = put_player(),
  PosMsg = <<<<"5;">>/binary, Id/binary, <<";">>/binary, Pos/binary, <<"\n">>/binary>>,
  if Nbj == 0 ->

    send_pos(PosMsg, S),
    Map = maps:new(),
    Map1 = maps:put(S, Id, Map),
    Map11 = maps:new(),
    Map12 = maps:put(Id, Pos, Map11),
    Map13 = maps:new(),
    Map14 = maps:put(Id, 0, Map13),

    ListPoint = parse_list(Points),
    Pointbin = <<<<"7;">>/binary, ListPoint/binary>>,
    send_pos(Pointbin, S),

    State2 = State#state{nbplayer = 1, mapSocketId = Map1, mapPosId = Map12, mapScore = Map14},
    {reply, ok, State2};

    true ->
      Map2 = maps:put(S, Id, MapId),
      Sockets = maps:keys(Map2),
      lists:foreach(fun(Sock) ->
        gen_tcp:send(Sock, PosMsg)
      end, Sockets),

      IdPlayer = maps:keys(MapPos),
      lists:foreach(fun(Player) ->
        Pospl = maps:get(Player, MapPos),
        PosPlayer = <<<<"5;">>/binary, Player/binary, <<";">>/binary, Pospl/binary, <<"\n">>/binary>>,
        send_pos(PosPlayer, S)
      end, IdPlayer),

      Map21 = maps:put(Id, Pos, MapPos),
      Map31 = maps:put(Id, 0, MapScore),
      PointBin = parse_list(Points),
      Pointbin123 = <<<<"7;">>/binary, PointBin/binary>>,
      send_pos(Pointbin123, S),
      State3 = State#state{nbplayer = Nbj + 1, mapSocketId = Map2, mapPosId = Map21, mapScore = Map31},
      {reply, ok, State3}

  end;




handle_call({send_position, [S]}, _From, #state{mapPosId = MapPos, mapSocketId = MapId, nbplayer = Nbj, points = Points} = State) ->

  Nbj2 = Nbj + 1,
  io:format("Number of player ~p~n", [Nbj2]),
  Id = maps:get(S, MapId),
  Pos = maps:get(Id, MapPos),
  Pos2 = <<<<"5;">>/binary, Id/binary, <<";">>/binary, Pos/binary, <<"\n">>/binary>>,
  Sockets = maps:keys(MapId),
  lists:foreach(fun(Sock) ->
    gen_tcp:send(Sock, Pos2)
  end, Sockets),
  Pointbin12 = parse_list(Points),
  Pointbin123 = <<<<"7;">>/binary, Pointbin12/binary>>,
  send_pos(Pointbin123, S),
  State3 = State#state{nbplayer = Nbj2},
  {reply, ok, State3};

handle_call({reconnect, [S, Id]}, _From, #state{mapSocketId = MapId} = State) ->

  MapList = maps:to_list(MapId),
  Valu = lists:keyfind(Id, 2, MapList),
  MapId2 = maps:remove(element(1, Valu), MapId),
  MapId1 = maps:put(S, Id, MapId2),
  io:format("Reconnect ~p~n", [MapId1]),
  State1 = State#state{mapSocketId = MapId1},
  {reply, ok, State1};

handle_call(_Call, _From, State) -> {reply, ko, State}.

-spec handle_info({nodedown, atom()}, state()) -> {stop, nodedown, state()} | {noreply, state()}.
handle_info(_Info, State) ->
  {noreply, State}.

%% @private
-spec handle_cast(term(), state()) -> {noreply, state()}.
handle_cast(_Msg, State) -> {noreply, State}.
%% @private
-spec terminate(_, state()) -> ok.
terminate(_Reason, _State) ->
  ok.
%% @private
-spec code_change(term(), state(), term()) -> {ok, state()}.
code_change(_OldVersion, State, _Extra) -> {ok, State}.

%%Listener sur le port 5678 
start_s() ->
  case gen_tcp:listen(5678, [binary, {packet, 0}, {reuseaddr, true},
    {active, false}]) of
    {ok, ListenSock} ->
      start_servers(ListenSock);
    {error, Reason} ->
      {error, Reason}
  end.

start_servers(LS) ->
  spawn(?MODULE, server, [LS]).

server(LS) ->
  case gen_tcp:accept(LS) of
    {ok, S} ->
      spawn(?MODULE, loop, [S]),
      io:format("Socket ~p~n", [S]),
      server(LS);
    Other ->
      io:format("accept returned ~w - goodbye!~n", [Other]),
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
              put_point(10),
              send_position(S, Data1);
            {error, closed} ->
              io:format("Socket ~w closed [~w]~n", [S, self()]),
              ok
          end;
        <<"reconect">> ->
          case gen_tcp:recv(S, 0) of
            {ok, Data1} ->
              reconnect(S, Data1);
            {error, closed} ->
              io:format("Socket ~w closed [~w]~n", [S, self()])
          end;
        <<"newgame">> ->
          io:format("new Game", []),
          restart(S);
        Other ->
          test_position(S, Other)
      end,
      loop(S);
    {error, closed} ->
      io:format("Socket ~w closed [~w]~n", [S, self()]),
      player_disconnect(S),
      ok
  end.


%%TODO check if already exist and random uniform
put_point(0) ->
  ok;
put_point(N) ->
  X = random:uniform(20) - 1,
  Y = random:uniform(20) - 1,
  S1 = list_to_binary(integer_to_list(X)),
  S2 = list_to_binary(integer_to_list(Y)),
  Point2 = <<S1/binary, <<",">>/binary, S2/binary>>,
  set_point(Point2),
  put_point(N - 1).


put_player() ->
  X = random:uniform(20) - 1,
  Y = random:uniform(20) - 1,
  X1 = list_to_binary(integer_to_list(X)),
  Y2 = list_to_binary(integer_to_list(Y)),
  <<X1/binary, <<",">>/binary, Y2/binary>>.

send_pos(Pos, S) ->
  io:format("Send socket ~p~n", [Pos]),
  gen_tcp:send(S, Pos).

mod(X, Y) when X > 0 -> X rem Y;
mod(X, Y) when X < 0 -> Y + X rem Y;
mod(0, _Y) -> 0.

%%Envoie la nouvelle position aux players
new_position(MapScore, MapSock, Pos, Points, New_pos, Nbpas, Id) ->
  Posnew = <<Id/binary, <<";">>/binary, Pos/binary, <<"\n">>/binary>>,
  Sockets = maps:keys(MapSock),
  lists:foreach(fun(Sock) ->
    gen_tcp:send(Sock, Posnew)
  end, Sockets),
  case lists:member(New_pos, Points) of
    true ->
      {NewPoint, Nbpas2, Nbplay2, NewMapSc} = test_point(MapScore, Sockets, New_pos, Points, Id, Nbpas);
    false ->
      Nbplay2 = maps:size(MapSock),
      Nbpas2 = Nbpas,
      NewPoint = Points,
      NewMapSc = MapScore
  end,
  {NewPoint, Nbpas2, Nbplay2, NewMapSc}.

%%Test des point pour 3 player
%%TODO test les point
test_point(MapScore, Sockets, New_pos, Points, Player, Nbpas) ->
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
      ListScore = maps:values(NewMapSc),
      MaxScore = lists:max(ListScore),
      PlayerMax = maps:to_list(NewMapSc),
      lists:foreach(fun(Play) ->
        case Play of
          {Value, MaxScore} ->
            Posnew4 = <<<<"4;">>/binary, Value/binary, <<"\n">>/binary>>,
            lists:foreach(fun(Sock) ->
              gen_tcp:send(Sock, Posnew4)
            end, Sockets);
          _ -> io:format("Loose")
        end
      end, PlayerMax);
    Nb ->
      Nbplay2 = maps:size(MapScore),
      Nbpas2 = Nbpas,
      io:format("Point +1 ~p ~n", [Nb])
  end,
  {NewPoint, Nbpas2, Nbplay2, NewMapSc}.

calcul_newPos(P1, X1, Y1) ->
  [X11, Y11] = binary:split(P1, <<",">>),
  X12 = list_to_integer(binary_to_list(X11)),
  Y12 = list_to_integer(binary_to_list(Y11)),
  X2 = mod(X12 + X1, 20),
  Y2 = mod(Y12 + Y1, 20),
  S1 = list_to_binary(integer_to_list(X2)),
  S2 = list_to_binary(integer_to_list(Y2)),
  <<S1/binary, <<",">>/binary, S2/binary>>.

%%TODO erase table, new point, Put Id, Check bug
restart(Socket) ->
  put_point(10),
  gen_tcp:send(Socket, <<"ok\n">>),
  send_position(Socket).

parse_list(List) ->
  lists:foldr(fun(X, Bina) ->
    if
      Bina == <<"\n">> ->
        <<X/binary, Bina/binary>>;
      true ->
        <<X/binary, <<";">>/binary, Bina/binary>>
    end end, <<"\n">>, List).