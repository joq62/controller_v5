%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test).   
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%% --------------------------------------------------------------------

%% External exports
-export([start/0]). 


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
  %  io:format("~p~n",[{"Start setup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=setup(),
    io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),


  %  io:format("~p~n",[{"Start cluster_start_test()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=cluster_start_test:start(),
  %  io:format("~p~n",[{"Stop cluster_start_test()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start prototype_test()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=prototype_test:start(),
    io:format("~p~n",[{"Stop prototype_test()",?MODULE,?FUNCTION_NAME,?LINE}]),

  %  io:format("~p~n",[{"Start distributed_test()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=single_test:start(),
 %   io:format("~p~n",[{"Stop distributed_test()",?MODULE,?FUNCTION_NAME,?LINE}]),


 %  io:format("~p~n",[{"Start distributed_test()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=distributed_test:start(),
  %  io:format("~p~n",[{"Stop distributed_test()",?MODULE,?FUNCTION_NAME,?LINE}]),

  %  io:format("~p~n",[{"Start monkey()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=monkey(),
  %  io:format("~p~n",[{"Stop monkey()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   
      %% End application tests
 %   io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
 %   io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.




%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

setup()->
  %  ok=test_nodes:start_nodes(),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
  
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
