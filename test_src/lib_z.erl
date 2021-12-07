%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(lib_z).   
 
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("controller.hrl").
%% --------------------------------------------------------------------


%% External exports
-export([
	 load_configs/0,
	 connect/0,
	 start_needed_apps/0,
	 initiate_dbase/0,
	 schedule/1
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

schedule(DeploymentId)->
    % podspecs
    
    % Get avaialble host candidates 
    PodSpecIds=db_deployment:pod_specs(DeploymentId),
    PrefferedHosts=check_host(PodSpecIds),
    FilteredNodesId=filtering(PrefferedHosts),
    Result=case [{error,Reason}||{error,Reason}<-FilteredNodesId] of
	       []->
		   ScoringListOfHostId=scoring(FilteredNodesId),
	           % Allocate applications on host
		   AllocatedHost=allocate_host(PodSpecIds,ScoringListOfHostId),
		   StartR=start_pod(AllocatedHost),
		   StartR;
	       ErrorList->
		   {error,[ErrorList]}
	   end,
    Result.

start_pod(AllocatedHost)->
    start_pod(AllocatedHost,[]).
start_pod([],Start)->
    Start;
start_pod([{PodId,HostId,AppsInfo}|T],Acc)->	
   
    AppsInfo=[{{App,Vsn},db_service_catalog:git_path({App,Vsn})}||{App,Vsn}<-db_pods:application(PodId)],
    HostNode=db_host:node(HostId),
    Combined=[{HostNode,AppInfo}||AppInfo<-AppsInfo],
    NewAcc=lists:append(Combined,Acc),
    start_pod(T,NewAcc).
    
    

allocate_host(PodSpecIds,ScoringListOfHostId)->
    allocate_host(PodSpecIds,ScoringListOfHostId,[]).
allocate_host([],_ScoringListOfHostId,AllocatedHost)->
    AllocatedHost;
allocate_host([PodId|T],ScoringListOfHostId,Acc)->
    AppsInfo=[{{App,Vsn},db_service_catalog:git_path({App,Vsn})}||{App,Vsn}<-db_pods:application(PodId)],
    io:format("AppsInfo ~p~n",[AppsInfo]),
    Info=[XHostInfo,XAppsInfo||{_XPodId,XHostInfo,XAppsInfo}<-Acc],
    
    io:format("Info ~p~n",[Info]),
    
    NewAcc=case [{XPodId,XHostInfo,XAppsInfo}||{XPodId,XHostInfo,XAppsInfo}<-Acc,
					       XAppsInfo=:=AppsInfo] of
	       [{XPodId,XHostInfo,XAppsInfo}]->
		   io:format("XPodId,XHostInfo,XAppsInfo ~p~n",[{XPodId,XHostInfo,XAppsInfo}]),  
		   case db_pods:host(PodId) of
		       {_,[]}->
			   [NewHostId|_]=lists:reverse([Z||Z<-ScoringListOfHostId,
							   false=:=(XHostInfo=:=Z)]),
			   [{PodId,NewHostId,AppsInfo}|Acc];
		       HostInfo->
			   case HostInfo=:=XHostInfo of
			       true->
				   Acc;
			       false ->
				   [{PodId,XHostInfo,AppsInfo}|Acc]
			   end
		   end;
	       [] ->
		   case db_pods:host(PodId) of
		       {_,[]}->
			   [NewHostId|_]=ScoringListOfHostId,
			   [{PodId,NewHostId,AppsInfo}|Acc];
		       HostInfo->
			   [{PodId,HostInfo,AppsInfo}|Acc]
		   end
	   end,
    io:format("NewAcc ~p~n",[NewAcc]),  
    allocate_host(T,ScoringListOfHostId,NewAcc).
    
    


scoring([])->
    {error,[no_nodes_available]};
scoring(FilteredNodesId)->
    NodeAdded=[{Id,db_host:node(Id)}||Id<-FilteredNodesId],
     Z=[{lists:flatlength(L),Node}||{Node,L}<-sd:all()],
    io:format("Z ~p~n",[Z]),
    S1=lists:keysort(1,Z),
    io:format("S1 ~p~n",[S1]),
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
