-module(q_eqc).
-include_lib("eqc/include/eqc.hrl").
-include_lib("eqc/include/eqc_statem.hrl").
-compile(export_all).

-record(state,{size,           % maximum size of the queue
               contents = [],  % current contents
               ptr             % address of the queue
              }).

%% Returns the state in which each test case starts.
initial_state() ->
  #state{}.

%% new

new_command(_S) ->
  {call, q, new, [nat()]}.

new_pre(S) ->
  S#state.ptr == undefined.

new_pre(_S, [Size]) ->
  Size > 0.

new_next(_S, Value, [Size]) ->
  #state{ size = Size, contents = [], ptr = Value }.

new_post(_S, _Args, _Res) ->
  true.

%% get

get_command(S) ->
  {call, q, get, [S#state.ptr]}.

get_pre(S) ->
  S#state.ptr /= undefined andalso
    S#state.contents /= [].

get_next(S, _Value, _Args) ->
  S#state{ contents = tl(S#state.contents) }.

get_post(S, _Args, Res) ->
  eq(Res, hd(S#state.contents)).

%% put

put_command(S) ->
  {call, q, put, [S#state.ptr, int()]}.

put_pre(S) ->
  S#state.ptr /= undefined
    andalso length(S#state.contents) < S#state.size.

put_next(S, _Value, [_Ptr, X]) ->
  S#state{ contents = S#state.contents ++ [X] }.

%% size

size_command(S) ->
  {call, q, size, [S#state.ptr]}.

size_pre(S) ->
  S#state.ptr /= undefined.

size_post(S,_,Res) ->
  eq(Res, length(S#state.contents)).

%% Property

prop_q() ->
  ?SETUP(fun() ->
             compile(),
             fun() -> cleanup() end
         end,
  ?FORALL(Cmds, commands(?MODULE),
    begin
      {H, S, Res} = run_commands(?MODULE,Cmds),
      pretty_commands(?MODULE, Cmds, {H, S, Res},
                      aggregate(command_names(Cmds),
                                Res == ok))
    end
  )).

compile() ->
  eqc_c:start(q, [definitions_only, {cflags, "-coverage"}]).

cleanup() ->
  eqc_c:stop().

