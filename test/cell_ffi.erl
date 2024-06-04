-module(cell_ffi).
-export([new/0, set/2, get/1]).
-export([loop/1]).

loop(State) ->
    receive
        {set, Value} -> loop({ok, Value});
        {get, Pid} ->
            Pid ! State,
            loop(State)
    end.

new() ->
    spawn(?MODULE, loop, [{error, nil}]).

set(Cell, Value) ->
    Cell ! {set, Value},
    nil.

get(Cell) ->
    Cell ! {get, self()},
    receive Result -> Result end.
