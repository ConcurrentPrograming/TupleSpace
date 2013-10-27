-module(test).
-export([testAll/0, test/0, test2/0, test3/0, test4/0, slave/2]).
-import(

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ts  % <-- CHANGE THIS TO YOUR TUPLESPACE MODULE NAME 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
,[in/2,out/2,new/0]
). 

testAll() ->

io:format("########## GIVEN TEST GO GO GO ########## ~n"),
test:test(),

io:format("########## GIVEN TEST END ###########~n~n~n~n~n"),
io:format("########## MULTIPLE TUPLESPACES TEST GO GO GO ########## ~n"),
test:test2(),

io:format("########## MULTIPLE TUPLESPACES END ########~n~n~n~n~n"),
io:format("########## CHECK WHAT WE RETURN TEST GO GO GO ########## ~n"),
test:test3(),

io:format("########## CHECK WHAT WE RETURN END ########~n~n~n~n~n"),
io:format("########## WEIRD INPUT TEST GO GO GO ########## ~n"),
test:test4(),

io:format("########## WEIRD INPUT TEST END ########~n"),
io:format("########## ALL TESTS ARE NOW DONE LOLZ ########~n").

test() ->
    Delay = 500,
    process_flag(trap_exit, true),
    TS = new(),
    link(TS),
    io:format("TEST: new tuplespace TS created~n", []),

    Slave1 = spawn_in_test(TS, {fish,any}),
    sleep(Delay),

    Slave2 = spawn_in_test(TS, {fowl,any}),
    sleep(Delay),

    out_test(TS, {fish,salmon}),
    sleep(Delay),

    out_test(TS, {fowl,chicken}), 
    sleep(Delay),

    replytest(Slave2, {fowl,any}, {fowl,chicken}),
    sleep(Delay),

    replytest(Slave1, {fish,any}, {fish,salmon}),
    sleep(Delay),

    out_test(TS, {fish,chips}), 
    sleep(Delay),

    Slave3 = spawn_in_test(TS, {any,chips}),
    sleep(Delay),

    replytest(Slave3, {any,chips}, {fish,chips}),
    sleep(Delay),

    Slave4 = spawn_in_test(TS, {any,any}),
    sleep(Delay),

    receive
	{Slave4, Tup} ->
	    io:format("Error. Empty tuplespace, but received: ~w~n",[Tup])
    after
        1000 ->   
	    io:format("Correct. Tuplespace appears to be empty.~n"),
	    exit(Slave4, this_is_it),
	    exit(TS, this_is_it),
	    collect_exits([Slave1, Slave2, Slave3, Slave4, TS]),
	    finished
    end.

%% test with more than one Tuplespace
test2() ->
Delay = 500,
    process_flag(trap_exit, true),
    TS = new(),
    TS2 = new(),
    link(TS),
    link(TS2),
    io:format("TEST: new tuplespace TS created~n", []),
    io:format("TEST: new tuplespace TS created~n", []),

    Slave1 = spawn_in_test(TS, {fish,any}),
    sleep(Delay),
    
    out_test(TS2, {fish,salmon}),
    sleep(Delay),

    Slave2 = spawn_in_test(TS2, {fish,any}),
    sleep(Delay),

    replytest(Slave2, {fish,any}, {fish,salmon}),
    sleep(Delay),


    receive
	{Slave1, Tup} ->
	    io:format("Error. Empty tuplespace, but received: ~w~n",[Tup])
    after
        1000 ->   
	    io:format("Correct. Tuplespace appears to be empty.~n"),
	    exit(Slave1, this_is_it),
	    exit(TS, this_is_it),
	    exit(TS2, this_is_it),
	    collect_exits([Slave1, Slave2, TS, TS2]),
	    finished
    end.

%% check what we receive
test3() ->
Delay = 500,
    process_flag(trap_exit, true),
    TS = new(),
    link(TS),
    io:format("TEST: new tuplespace TS created~n", []),

    Slave1 = spawn_in_test(TS, {fish,any}),
    sleep(Delay),
    
    out_test(TS, {hello,salmon}),
    sleep(Delay),

	io:format("We get:  ~w~n", [Slave1]),
    receive
	{Slave1, Tup} ->
	    io:format("Error. Empty tuplespace, but received: ~w~n",[Tup])
    after
        1000 ->   
	    io:format("Correct. Tuplespace appears to be empty.~n"),
	    exit(Slave1, this_is_it),
	    exit(TS, this_is_it),
	    collect_exits([Slave1, TS]),
	    finished
    end.

%%% test weird tuple input %%%%%%%%%%%%%%%%%%%%%%%
test4()->
    Delay = 500,
    process_flag(trap_exit, true),
    TS = new(),
    link(TS),
    io:format("TEST: new tuplespace TS created~n", []),

    Slave1 = spawn_in_test(TS, {1234,any}),
    sleep(Delay),

    Slave2 = spawn_in_test(TS, {"haha i rule okay?",any}),
    sleep(Delay),

    out_test(TS, {1234,5678}),
    sleep(Delay),

    out_test(TS, {"haha i rule okay?", " No you dont hahaha"}), 
    sleep(Delay),

    replytest(Slave2, {"haha i rule okay?",any}, {"haha i rule okay?", " No you dont hahaha"}),
    sleep(Delay),

    replytest(Slave1, {1234,any}, {1234,5678}),
    sleep(Delay),

    receive
	{Slave1, Tup} ->
	    io:format("Error. Empty tuplespace, but received: ~w~n",[Tup])
    after
        1000 ->   
	    io:format("Correct. Tuplespace appears to be empty.~n"),
	    exit(Slave1, this_is_it),
	    exit(TS, this_is_it),
	    collect_exits([Slave1, Slave2, TS]),
	    finished
    end.


%%% Helper functions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sleep(T) ->
    receive
    after
	T -> true
    end.

out_test(Tuplespace, Tup) ->
    io:format("TEST: out(TS, ~w)~n", [Tup]),
    out(Tuplespace, Tup).

% spawns a slave task to perform an in test. This function 
% returns the slave's Pid. The slave will forward the result of the 
% in operation to the caller.

spawn_in_test(Tuplespace, Pat) -> 
    S = spawn_link(test, slave, [Tuplespace, {self(), Pat}]),
    io:format("TEST: in(TS, ~w) by process ~w~n", [Pat, S]),
    S.

%% Get a tuple matching Item from Tuplespace T and send it to Pid
slave(T, {Pid,Item}) ->
    case in(T, Item) of
	R -> Pid!{self(), R}
    end.

%% Tests whether the reply from a Slave task matches the expected Tuple
replytest(Slave, Pat, Tup) -> 
    io:format("Process ~w~n", [Slave]),
    receive
	{Slave,Tup} ->
	    io:format("     Correct. in operation: ~w returned tuple: ~w~n", [Pat, Tup]);
        {Slave,Bad} ->
	    io:format("     Error. in with pattern: ~w returned tuple: ~w~n", [Pat, Bad])
    after 
        5000 ->   
	    io:format("     Error. No response for in operation with pattern: ~w~n", [Pat])
    end.

collect_exits([]) ->
    done;
collect_exits([Pid | Pids]) ->
    receive
	{'EXIT', Pid, _} ->
	    collect_exits(Pids)
    end.
