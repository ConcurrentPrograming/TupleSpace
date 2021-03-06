-module(ts). 
-export([new/0, in/2, out/2]).

% returns the PID of a new (empty) tuplespace.
new() ->
    spawn_link(tuplespace, loop(), [[],[]]).

% returns a tuple matching Pattern from tuplespace TS. Note that this operation will block if there is no such tuple.
in(TS, Pattern) ->
    Ref = make_ref(),
    TS ! {self(), Ref, Pattern},
    receive
        {Ref, Result} ->
            Result
    end.
    
% puts Tuple into the tuplespace TS.
out(TS,Tuple) ->
    TS ! {Tuple}.
    
% do the loopy loop
loop() -> loop([], []).
loop(TList, WaitingList) -> %% TList = tuple list if not obvious
    receive 
        {From, Ref, Pattern} ->
            case rec_match(Pattern, TList, []) of
                {FoundTuple, NewTList} -> 
                    From ! {Ref, FoundTuple},
                    loop(NewTList, WaitingList);
                false -> 
                    loop(TList, [{From, Ref, Pattern}|WaitingList])
            end;
        {Tuple} ->
            case match_list(Tuple, WaitingList, []) of
                false -> loop([Tuple|TList], WaitingList);
                {Waiting, List}  ->
                    {From, Ref, _} = Waiting,
                    From ! {Ref, Tuple},
                    loop(TList, List)
            end
    end. 

% match pattern with tuple
match(any,_) -> true;
match(P,Q) when is_tuple(P), is_tuple(Q) -> 
    match(tuple_to_list(P),tuple_to_list(Q));
match([P|PS],[L|LS]) -> 
    case match(P,L) of
        true -> match(PS,LS); 
        false -> false
    end;
match(P,P) -> true;
match(_,_) -> false.

% match tuple against waiting list.
% returns false if no match is found, else a tuple with the
% information about the waiting process and the new list.
match_list(_, [], _) ->
    false;
match_list(Tuple, [X|XS], List) ->
    {_, _, Pattern} = X,
    case match(Pattern, Tuple) of
        true ->
            {X, lists:concat(List, XS)};
        false ->
            match_list(Tuple, XS, lists:append([X],List))
    end.

% recursive match returning a tupple of the matched tuple and new list.
rec_match(_, [], _)->
    false;
rec_match(Pattern, [X|XS], List) ->
    case match(Pattern, X) of
        true -> {X, lists:concat(List, XS)};
        false -> rec_match(Pattern, XS, lists:append([X],List))
    end.
    

