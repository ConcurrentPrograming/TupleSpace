-module(tuplespace).
-export([match/2, new/0 , in/2 , out/2]).

%creates a new Tuplespace
new()->
	spawn_link(tuplespace, tupleHandler, [[],[]]).		
		
match(any,_) -> true;
match(P,Q) when is_tuple(P), is_tuple(Q)
                -> match(tuple_to_list(P),tuple_to_list(Q));
match([P|PS],[L|LS]) -> case match(P,L) of
                              true -> match(PS,LS); 
                              false -> false
                         end;
match(P,P) -> true;
match(_,_) -> false.

in(Tuplespace, InTuple) ->
	Ref = make_ref(),
	Tuplespace ! {self() , Ref, InTuple};
in(_,_) -> io:format("wrong arguments").

out(Tuplespace, OutTuple) when is_tuple(PatternOut) -> 
	Ref = make_ref(),
	Tuplespace ! {self(), Ref, PatternOut};
out(_,_) -> io:format("wrong arguments").

