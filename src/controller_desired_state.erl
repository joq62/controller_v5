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


    ControllerHostsToStart=[Id||{Id,host_started}<-host:host_status(),
				auto_erl_controller=:=db_host:type(Id)],
    
    io:format("~p~n",[{time(),node(),bully:who_is_leader(),?MODULE,?FUNCTION_NAME,?LINE,host:host_status()}]),
    io:format("ControllerHostsToStart ~p~n",[{time(),node(),?MODULE,?FUNCTION_NAME,?LINE,ControllerHostsToStart}]),
    ok.
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


