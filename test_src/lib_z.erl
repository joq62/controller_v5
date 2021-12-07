%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(lib_z).   
 
    
%% --------------------------------------------------------------------1
%% Include files
%% --------------------------------------------------------------------
-include("controller.hrl").
%% --------------------------------------------------------------------


%% External exports
-export([
	 load_configs/0,
	 connect/0,
	 get/0,
	 start_needed_apps/0,
	 initiate_dbase/0,
	 schedule/1,
	 scratch_workers/1
	]).
    


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% -------------------------------------------------------------------
% 
% filtering()
% scoring()
-define(ServicePodExt,".service_pod").
scratch_workers(Node)->
    {ok,Files}=rpc:call(Node,file,list_dir,["."],2000),
    [{Node,Dir,rpc:call(Node,os,cmd,["rm -r "++Dir],1000)}||Dir<-Files,
					      ?ServicePodExt=:=filename:extension(Dir)].

schedule(DeploymentId)->
    % podspecs
    
    % Get avaialble host candidates 
    PodSpecIds=db_deployment:pod_specs(DeploymentId),
   % io:format("PodSpecIds ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,PodSpecIds}]),  
    PrefferedHosts=check_host(PodSpecIds),
   % io:format("PrefferedHosts ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,PrefferedHosts}]),  
    FilteredNodesId=filtering(PrefferedHosts),
   % io:format("FilteredNodesId ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,FilteredNodesId}]),  
    Result=case [{error,Reason}||{error,Reason}<-FilteredNodesId] of
	       []->
		   ScoringListOfHostId=scoring(FilteredNodesId),
	%	   io:format("ScoringListOfHostId ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,ScoringListOfHostId}]),  
	           % Allocate applications on host
		   AllocatedHost=allocate_host(PodSpecIds,ScoringListOfHostId),
	%	   io:format("AllocatedHost ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,AllocatedHost}]),  
		   StartR=start_pod(AllocatedHost),
		   io:format("StartR ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,StartR}]),  
		   StartR;
	       ErrorList->
		   {error,[ErrorList]}
	   end,
    io:format("Result ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,Result}]),  
    Result.

start_pod(AllocatedHost)->
    start_pod(AllocatedHost,[]).
start_pod([],Start)->
    Start;
start_pod([{PodId,HostId,AppsInfo}|T],Acc)->	
    HostNode=db_host:node(HostId),
    HostName=db_host:hostname(HostId),
    PodName=db_pods:name(PodId),
    NodeName=PodName++"_"++integer_to_list(erlang:system_time(microsecond)),
    PodDir=NodeName++?ServicePodExt,
    Cookie=db_host:cookie(HostId),
    Args="-setcookie "++Cookie,   
    NewAcc=case lib_os:start_slave(HostNode,HostName,NodeName,Args,PodDir) of
		 {ok,Slave}->
		     case net_adm:ping(Slave) of
			 pong->
			     StartResult=[{App,Vsn,load_start(Slave,PodDir,{App,Vsn,GitPath})}||{{App,Vsn},GitPath}<-AppsInfo],
			     [{ok,[PodId,HostId,Slave,StartResult]}|Acc];
			 Reason->
			      [{error,[node(),?MODULE,?FUNCTION_NAME,?LINE,Reason,PodId,HostId,AppsInfo]}|Acc]
		     end;
	       Reason->
		   [{error,[node(),?MODULE,?FUNCTION_NAME,?LINE,Reason,PodId,HostId,AppsInfo]}|Acc]
	   end,
    start_pod(T,NewAcc).
    
load_start(Slave,PodDir,{App,Vsn,GitPath})->
    AppDir=filename:join(PodDir,atom_to_list(App)),
    Result=case rpc:call(Slave,os,cmd,["git clone "++GitPath++" "++AppDir],10*1000) of
		  {badrpc,Reason}->
		      {error,[node(),?MODULE,?FUNCTION_NAME,?LINE,Reason,Slave,App,Vsn,PodDir]};
		  _->
		      Ebin=filename:join([AppDir,"ebin"]),
		      case rpc:call(Slave,code,add_patha,[Ebin],5*1000) of
			  true->
			      case rpc:call(Slave,application,start,[App],5*1000) of
					 ok->
				      {ok,Slave,App,Vsn};
				  Reason ->
				      {error,[node(),?MODULE,?FUNCTION_NAME,?LINE,Reason,Slave,App,Vsn,PodDir]}
			      end;
				 Reason ->
			      {error,[node(),?MODULE,?FUNCTION_NAME,?LINE,Reason,Slave,App,Vsn,PodDir]}
		      end
	   end,	     
    Result.

allocate_host(PodSpecIds,ScoringListOfHostId)->
    allocate_host(PodSpecIds,ScoringListOfHostId,[]).
allocate_host([],_ScoringListOfHostId,AllocatedHost)->
    AllocatedHost;
allocate_host([PodId|T],ScoringListOfHostId,Acc)->
    AppsInfo=[{{App,Vsn},db_service_catalog:git_path({App,Vsn})}||{App,Vsn}<-db_pods:application(PodId)],
    NewAcc=case db_pods:host(PodId) of
	       {_,[]}->
		   [NewHostId|_]=ScoringListOfHostId,
		   [{PodId,NewHostId,AppsInfo}|Acc];
	       HostInfo->
		   [{PodId,HostInfo,AppsInfo}|Acc]
	   end,
%    io:format("NewAcc ~p~n",[NewAcc]),  
    allocate_host(T,ScoringListOfHostId,NewAcc).

    


scoring([])->
    {error,[no_nodes_available]};
scoring(FilteredNodesId)->
    NodeAdded=[{Id,db_host:node(Id)}||Id<-FilteredNodesId],
     Z=[{lists:flatlength(L),Node}||{Node,L}<-sd:all()],
 %   io:format("Z ~p~n",[Z]),
    S1=lists:keysort(1,Z),
 %   io:format("S1 ~p~n",[S1]),
    SortedList=lists:reverse([Id||{Id,Node}<-NodeAdded,
		 lists:keymember(Node,2,S1)]),
    SortedList.
    
    

filtering([])->
    lib_status:node_started();
filtering(PrefferedHosts)->
    AvailableNodesId=lib_status:node_started(),
    filtering(PrefferedHosts,AvailableNodesId,[]).

 filtering([],_AvailableNodesId,FilteredNodesId)->
    case [{error,Reason}||{error,Reason}<-FilteredNodesId] of
	[]->
	    FilteredNodesId;
	ErrorList->
	    {error,ErrorList}
    end;
filtering([Host|T],AvailableNodesId,Acc)->
    
    NewAcc=case lists:keymember(Host,1,AvailableNodesId) of
	       true->
		   [Host|Acc];
	       false->
		   [{error,[Host]}|Acc]
	   end,
    filtering(T,AvailableNodesId,NewAcc).
    


check_host(PodSpecIds)->
    check_host(PodSpecIds,[]).

check_host([],PrefferedHosts)->
    PrefferedHosts;
check_host([Id|T],Acc) ->
    NewAcc=case db_pods:host(Id) of
	       {_,[]}->
		   Acc;
	       HostInfo->
		   [HostInfo|Acc]
	   end,
    check_host(T,NewAcc).
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% -------------------------------------------------------------------
load_configs()->
    {TestDir,TestPath}=?TestConfig,
    {Dir,Path}=?Config,
    os:cmd("rm -rf "++TestDir),
    os:cmd("rm -rf "++Dir),
    os:cmd("git clone "++TestPath),
    os:cmd("git clone "++Path),
    ok.
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% -------------------------------------------------------------------
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
connect()->
    
    connect:start(?ControllerNodes),
    ok.
get()->
    connect:get(?ControllerNodes).


%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start_needed_apps()->
    ok=application:start(dbase_infra),
    ok=application:start(sd),
    timer:sleep(1000),
    ok.

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
initiate_dbase()->
    LoadR=[load_from_file(node(),Module,Source)||{Module,Source}<-?DbaseServices],
    io:format("LoadR ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,LoadR}]),
    ok.

load_from_file(Node,Module,Source)->
    LoadResult=[R||R<-rpc:call(Node,dbase_infra,load_from_file,[Module,Source],5*1000),
			   R/={atomic,ok}],
    Result=case LoadResult of
	       []-> %ok
		   {ok,[Node,Module]};
	       Reason ->
		   {error,[Node,Module,Reason]}
	   end,
    Result.
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
clone(Dir,GitPath)->
    os:cmd("rm -rf "++Dir),
    os:cmd("git clone "++GitPath),
    ok.
