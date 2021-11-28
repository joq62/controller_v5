%% Author: joqerlang
%% Created: 2021-11-18 
%% Connect/keep connections to other nodes
%% clean up of computer (removes all applications but keeps log file
%% git loads or remove an application ,loadand start application
%%  
%% Starts either as controller or worker node, given in application env 
%% Controller:
%%   git clone and starts 
%% 
%% Description: TODO: Add description to application_org
%% 
-module(deploy).
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("kernel/include/logger.hrl").
%% --------------------------------------------------------------------
%% Behavioural exports
%% --------------------------------------------------------------------
-export([
         create/1
        ]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% API Functions
%% --------------------------------------------------------------------

%% ====================================================================!
%% External functions
%% ====================================================================!
%% --------------------------------------------------------------------
%% Func: start/2
%% Returns: {ok, Pid}        |
%%          {ok, Pid, State} |
%%          {error, Reason}
%% --------------------------------------------------------------------
%,[{myamath,"1.0.0",1,["C200"]}],
%%---------------------------------------------------------------------

create(DeplomentInfo)->
    OrderedHostsList=kublet:available_hosts(),
    R=[pair_app_host(AppDeployInfo,OrderedHostsList,[])||AppDeployInfo<-DeplomentInfo],
    {ok,R}.
    
pair_app_host({_App,_Vsn,0,_HostList},OrderedHostsList,Result)->
    {Result,OrderedHostsList};

pair_app_host({App,Vsn,N,[]},OrderedHostsList,Acc)->
    {Host,KubletNode}=lists:last(OrderedHostsList),
    NewOrderedHostsList=[{Host,KubletNode}|lists:delete({Host,KubletNode},OrderedHostsList)],
    NewAcc=[{ok,KubletNode,App,Vsn}|Acc],
    pair_app_host({App,Vsn,N-1,[]},NewOrderedHostsList,NewAcc);

pair_app_host({App,Vsn,N,[WantedHost|T]},OrderedHostsList,Acc)->
    case lists:keyfind(WantedHost,1,OrderedHostsList) of
	false->
	    NewAcc=[{error,[eexists,WantedHost,App,Vsn]}|Acc],
	    NewOrderedHostsList=OrderedHostsList;
	{WantedHost,KubletNode}->
	    NewOrderedHostsList=[{WantedHost,KubletNode}|lists:delete({WantedHost,KubletNode},OrderedHostsList)],
	    NewAcc=[{ok,KubletNode,App,Vsn}|Acc]
    end,
    pair_app_host({App,Vsn,N-1,T},NewOrderedHostsList,NewAcc).
