%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(app_start_test).    
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("controller.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([start/0]).

%-define(PodDir,"test.pod").
-define(PodDir,".").

%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
    ?debugMsg("Start setup"),
    ?assertEqual(ok,setup()),
    ?debugMsg("stop setup"),

 %   ?debugMsg("Start testXXX"),
 %   ?assertEqual(ok,single_node()),
 %   ?debugMsg("stop single_node"),
    
      %% End application tests
    ?debugMsg("Start cleanup"),
    ?assertEqual(ok,cleanup()),
    ?debugMsg("Stop cleanup"),

    ?debugMsg("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
setup()->
    %load configas
    ok=application:start(sd),
    ok=application:start(bully),
    ok=application:start(dbase_infra),
    
    Ids=lists:sort(db_host:ids()),
    Ids=[{"c100","host1"},
	 {"c100","host2"},
	 {"c100","host3"},
	 {"c100","host4"}],

    Nodes=[db_host:node(Id)||Id<-Ids],
    [host1@c100,host2@c100,host3@c100,host4@c100]=Nodes,
    [rpc:call(Node,init,stop,[],1000)||Node<-Nodes],
    timer:sleep(1000),
    {ok,AppInfo}=host_desired_state:start(),
    [{{"c100","host1"},host1@c100},
     {{"c100","host2"},host2@c100},
     {{"c100","host3"},host3@c100}, 
     {{"c100","host4"},host4@c100}]=lists:keysort(2,AppInfo),
    ok=application:start(host),
    Date=date(),
    [Date,Date,Date,Date]=[rpc:call(Node,erlang,date,[],1000)||Node<-Nodes],
    ok=application:start(controller),
    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
  
  %  init:stop(),
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
