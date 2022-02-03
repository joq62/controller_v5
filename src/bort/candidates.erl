%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(candidates).   
 
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("log.hrl").
%% --------------------------------------------------------------------


%% External exports
-export([
	 filter/1
	]).
    


%% ====================================================================
%% External functions
%% ====================================================================



%
% Rules
% Only one application instance on a node
% If too few nodes , just deploy where it is possible, partial wanted state
%
% 1. Wanted state
% Singel deployment- no constraints
%    {myadd,"1.0.0",1,[]}.
% Singel deployment- constraints
%    {conbee2,"1.0.0",1,[{hw,conbee2},{port,6523}]}.
%    {conbee2,"1.0.0",1,[{hw,conbee2},{port,3400}]}.
%    {balcony_web,"1.0.0",1,[{port,5456}]}.
%    {telldus,"1.0.0",1,[{hw,tellstick}]}.
%
% Distribuited- no constraints
% {mydivi,"1.0.0",2,[]}.
% Distribuited- constraints
% {kubelet,"1.0.0",3,[{host,"c200"},{host,"c201"},{host,"c202"}]}.
% {etcd,"1.0.0",2,[{host,"c200"},{host,"c201"},{host,"c202"}]} 
% {etcd,"1.0.0",2,[{host,"c200"},{host,"c201"}]} 
%


%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% -------------------------------------------------------------------
% 1. Wanted state
% Singel deployment- no constraints
%    {myadd,"1.0.0",1,[]}.
% Choose first available node that has not the App,Vsn
% Singel deployment- constraints
%    {conbee2,"1.0.0",1,[{hw,conbee2},{port,6523}]}.
%    {conbee2,"1.0.0",1,[{hw,conbee2},{port,3400}]}.
%    {balcony_web,"1.0.0",1,[{port,5456}]}.
%    {telldus,"1.0.0",1,[{hw,tellstick}]}.
% Choose first available node that has not the App,Vsn and fullfills the constrains

%
% Distribuited- no constraints
% {mydivi,"1.0.0",2,[]}.
% Choose N first available nodes that have not the App,Vsn
% Distribuited- constraints
% {kubelet,"1.0.0",3,[{host,"c200"},{host,"c201"},{host,"c202"}]}.
% {etcd,"1.0.0",2,[{host,"c200"},{host,"c201"},{host,"c202"}]} 
% {etcd,"1.0.0",2,[{host,"c200"},{host,"c201"}]} 
% Choose N first available nodes that have not the App,Vsn  and fullfills the constrains

% Single is a sub set of Distributed
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------



filter({App,Vsn,1,[]})->
    Result=case sd:get(App) of
	       []-> % Not deployed
		   case host:availble_host_nodes(node(),[]) of
		       []->
			   {error,[no_nodes_avaialble]};
		       [N|_] ->
			   {ok,[{App,Vsn,N}]}
		   end;
	       [N|_] ->
		   {error,[already_started,App,Vsn,N}]}
	   end,
    Result;

filter({App,Vsn,1,Constraints}) ->
    Result=case sd:get(App) of
	       []-> % Not deployed
		   case host:availble_host_nodes(node(),Constraints) of
		       []->
			   {error,[no_nodes_avaialble]};
		       [N|_] ->
			   {ok,[{App,Vsn,N}]}
		   end;
	       [N|_] ->
		   {error,[already_started,App,Vsn,N}]}
	   end,
    Result;

filter({App,Vsn,NumWanted,[]})->
    Result=case sd:get(App) of
	       []-> % Not deployed
		   case host:availble_host_nodes(node(),[]) of
		       []->
			   {error,[no_nodes_avaialble]};
		       AvailableNodes ->
			   case lists:sublist(AvailableNodes,NumWanted) of
			       []->
				   {error,[no_nodes_avaialble]};
			       AddedNodes->
				   {ok,[{App,Vsn,N}||N<-AddedNodes]}
			   end
		   end;
	       AllocatedNodes ->
		   NumActual=lists:flatlength(AllocatedNodes),
		   AvailableNodes=[N1||N1<-host:availble_host_nodes(node(),[]),
				       false=:=lists:member(N1,AllocatedNodes)],
		   Diff=NumWanted-NumActual,
		   if 
		       Diff>0->
			   {ok,lists:sublist(AvailableNodes,Diff)};
		       true->
			   {error,[already_started,App,Vsn,N}]}
		   end
	   end,
    Result;

filter({App,Vsn,NumWanted,Constraints})->
    Result=case sd:get(App) of
	       []-> % Not deployed
		   case host:availble_host_nodes(node(),Constraints) of
		       []->
			   {error,[no_nodes_avaialble]};
		       AvailableNodes ->
			   case lists:sublist(AvailableNodes,NumWanted) of
			       []->
				   {error,[no_nodes_avaialble]};
			       AddedNodes->
				   {ok,[{App,Vsn,N}||N<-AddedNodes]}
			   end
		   end;
	       AllocatedNodes ->
		   NumActual=lists:flatlength(AllocatedNodes),
		   AvailableNodes=[N1||N1<-host:availble_host_nodes(node(),Constraints),
				       false=:=lists:member(N1,AllocatedNodes)],
		   Diff=NumWanted-NumActual,
		   if 
		       Diff>0->
			   case lists:sublist(AvailableNodes,Diff) of
			       []->
				   {error,[no_nodes_avaialble]};
			       AddedNodes->
				   {ok,[{App,Vsn,N}||N<-AddedNodes]}
			   end;
		       Diff=:=0 ->
			   {ok,[]};
		       Diff<0 ->
			   {ok,[]}
		   end
	   end,
    Result.
