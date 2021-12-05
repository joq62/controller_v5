%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(controller_desired_state).  
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%%---------------------------------------------------------------------
%% Records for test
%%

%% --------------------------------------------------------------------
-compile(export_all).


%% ====================================================================
%% External functions
%% ====================================================================
start()->
    io:format("************************** ~p~n",[{time(),node(),"*************************************"}]),

    io:format("~p~n",[{time(),node(),bully:who_is_leader(),?MODULE,?FUNCTION_NAME,?LINE,host:host_status()}]),
    
    ControllerHostsToStart=[Id||{Id,node_started}<-host:host_status(),
				auto_erl_controller=:=db_host:type(Id),
				node()/=db_host:node(Id),
				false=:=lists:member(db_host:node(Id),sd:get(controller))],
    
    HostToStart=case ControllerHostsToStart of
		    []->
			[];
		    [Node|_]->
			[Node]
		end,
    R=load_start(HostToStart),
    io:format("~p~n",[{time(),node(),bully:who_is_leader(),?MODULE,?FUNCTION_NAME,?LINE,host:host_status()}]),
    io:format("ControllerHostsToStart,R ~p~n",[{time(),node(),?MODULE,?FUNCTION_NAME,?LINE,HostToStart,R}]),
    ok.

load_start(ControllerHostsToStart)->
    load_start(ControllerHostsToStart,[]).

load_start([],StartResult)->
    StartResult;
load_start([HostId|T],Acc)->
    io:format("HostId ~p~n",[{time(),node(),?MODULE,?FUNCTION_NAME,?LINE,HostId}]),
    AppId={controller,"0.1.0"},
    R=loader:load_start(AppId,HostId),
    io:format("R ~p~n",[{time(),node(),?MODULE,?FUNCTION_NAME,?LINE,R}]),
    timer:sleep(2000),
    load_start(T,[R|Acc]).
    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------


