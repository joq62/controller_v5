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
	% is_applications_started/1,
	 is_pod_running/1,
	 load_configs/0,
	 connect/0,
	 get/0,
	 start_needed_apps/0,
	 initiate_dbase/0,
	 schedule/0,
	 schedule/1,
	 scratch_workers/1
	]).
    


%% ====================================================================
%% External functions
%% ====================================================================
glurk()->
    [{ok,[{"single_mymath","1.0.0"},
	  {"c202","host"},
	  single_mymath_1639080403557668@c202,
	  [{mymath,"1.0.0",ok},
	   {myadd,"1.0.0",ok},
	   {mydivi,"1.0.0",ok},
	   {sd,"1.0.0",ok}]]},
     {ok,[{"mydivi","1.0.0"},
	  {"c202","host"},
	  mydivi_1639080410539668@c202,
	  [{mydivi,"1.0.0",ok},{sd,"1.0.0",ok}]]},
     {ok,[{"myadd","1.0.0"},
	  {"c201","host"},
	  myadd_1639080413550736@c201,
	  [{myadd,"1.0.0",ok},{sd,"1.0.0",ok}]]}].

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
schedule()->
    {ok,WantedDeployments}=file:consult(?DeploymentSpec),
    %%
    
    [schedule(DeploymentId)||DeploymentId<-WantedDeployments].
   


wanted_state(DeploymentId)->
    DeployStateIds=db_deploy_state:deployment(DeploymentId),
    
    case gl:are_hosts_running(DeploymentId) of
	true->
	    case gl:are_pods_running(DeploymentId) of
		true->
		    ok;
		ErrorList->
						%delete and restart deployment
		    {error,ErrorList}
	    end;
	ErrorList->
	    {error,ErrorList}
    end.
		    
	    

remove_deployment(DeploymentId)->
    %%
    
    ok.


is_pod_running(DeploymentId)->
    case  db_deployment:deploy_node(DeploymentId) of
	[]->
	    {error,[?MODULE,?FUNCTION_NAME,?LINE,eexists,DeploymentId]};
	stopped ->
	    false;	   
	WantedPodIdNodes->
	    Check=[{net_adm:ping(Node),PodId,Node}||{PodId,Node}<-WantedPodIdNodes],
	    case [{error,[PodId,Node]}||{pang,PodId,Node}<-Check] of
		[]->
		    true;
		ErrorList->
		    {error,ErrorList}
	    end
    end.

is_applications_started(Node,AppList)->
    Result=case rpc:call(Node,application,which_applications,[],5*1000) of
	       {badrpc,Reason}->
		   {error,[?MODULE,?FUNCTION_NAME,?LINE,badrpc,Reason]};
	       Applications->
		   case [{App,Vsn}||{App,Vsn}<-AppList,
			      true/=lists:keymember(App,1,Applications)] of
		       []->
			   true;
		       _MissingApps->
			   false
		   end
	   end,
    Result.

is_nodes_running(DeploymentId)->
    case  db_deployment:deploy_node(DeploymentId) of
	[]->
	    {error,[?MODULE,?FUNCTION_NAME,?LINE,eexists,DeploymentId]};
	stopped ->
	    {error,[?MODULE,?FUNCTION_NAME,?LINE,stopped,DeploymentId]};
	Nodes->
	    PingR=[{Node,net_adm:ping(Node)}||Node<-Nodes],
	    case [{error,Node}||{Node,pang}<-PingR] of
		[]->
		    true;
		ErrorList ->
		    {error,[ErrorList]}
	    end
    end.
		
    
is_deployed(DeploymentId)->
    db_deployment:is_deployed(DeploymentId).

schedule(DeploymentId)->
    io:format("DeploymentId ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,DeploymentId}]),
    % Get avaialble host candidates 
    PodSpecIds=db_deployment:pod_specs(DeploymentId),
    %io:format("PodSpecIds ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,PodSpecIds}]),  
    PrefferedHosts=check_host(PodSpecIds),
    %io:format("PrefferedHosts ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,PrefferedHosts}]),  
    Result=case [{error,Reason}||{error,Reason}<-PrefferedHosts] of
	       []->
		   FilteredNodesId=filtering(PrefferedHosts),
		   %io:format("FilteredNodesId ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,FilteredNodesId}]),  
		   case [{error,Reason}||{error,Reason}<-FilteredNodesId] of
		       []->
			   ScoringListOfHostId=scoring(FilteredNodesId),
			   case [{error,Reason}||{error,Reason}<-ScoringListOfHostId] of
			       []->
				   %io:format("ScoringListOfHostId ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,ScoringListOfHostId}]),  
				   AllocatedHosts=[allocate_host(PodId,ScoringListOfHostId)||PodId<-PodSpecIds],
				   %io:format("AllocatedHosts ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,AllocatedHosts}]),  
				   case [{error,Reason}||{error,Reason}<-AllocatedHosts] of
				       []->
					   StartR=[start_pod(AllocatedHost)||{ok,AllocatedHost}<-AllocatedHosts],
					   case [{error,Reason}||{error,Reason}<-StartR] of
					       []->
						   R=[Info||{ok,Info}<-StartR],
						   Id=erlang:system_time(microsecond),
						   [db_deploy_state:create(Id,DeploymentId,PodInfo)||PodInfo<-R],
						   {ok,Id,DeploymentId,R};
					       ErrorList->
						   {error,[?MODULE,?FUNCTION_NAME,?LINE,starting_pods,DeploymentId,ErrorList]}
					   end;
				       ErrorList->
					   {error,[?MODULE,?FUNCTION_NAME,?LINE,no_hosts_allocated,DeploymentId,ErrorList]}
				   end;
			       ErrorList->
				   {error,[?MODULE,?FUNCTION_NAME,?LINE,no_hosts_available,DeploymentId,ErrorList]}
			   end;
		       ErrorList->
			   {error,[?MODULE,?FUNCTION_NAME,?LINE,missing_host,DeploymentId,ErrorList]}
		   end;
	       ErrorList->
		   {error,[?MODULE,?FUNCTION_NAME,?LINE,missing_preffered_host,DeploymentId,ErrorList]}
	   end,
    Result.

start_pod({PodId,HostId,AppsInfo})->	
   %   io:format("PodId,HostId,AppsInfo ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,PodId,HostId,AppsInfo}]),  
    HostNode=db_host:node(HostId),
    HostName=db_host:hostname(HostId),
    PodName=db_pods:name(PodId),
    NodeName=PodName++"_"++integer_to_list(erlang:system_time(microsecond)),
    PodDir=NodeName++?ServicePodExt,
    Cookie=db_host:cookie(HostId),
    Args="-setcookie "++Cookie,   
    case lib_os:start_slave(HostNode,HostName,NodeName,Args,PodDir) of
	{ok,Slave,PodDir}->
	    case net_adm:ping(Slave) of
		pong->
		    StartR=[{load_start(Slave,PodDir,{App,Vsn,GitPath}),App,Vsn}||{{App,Vsn},GitPath}<-AppsInfo],
		    case [{error,Reason}||{error,Reason}<-StartR] of
			[]->
			    StartResult=[{App,Vsn}||{ok,App,Vsn}<-StartR],
			    {ok,[PodId,HostId,Slave,PodDir,StartResult]};
			ErrorList->
			    {error,[node(),?MODULE,?FUNCTION_NAME,?LINE,ErrorList]}
		    end;		    
		Reason->
		    {error,[node(),?MODULE,?FUNCTION_NAME,?LINE,Reason,PodId,HostId,AppsInfo]}
	    end;
	Reason->
	    {error,[node(),?MODULE,?FUNCTION_NAME,?LINE,Reason,PodId,HostId,AppsInfo]}
    end.
    

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
				      ok;
				  Reason ->
				      {error,[node(),?MODULE,?FUNCTION_NAME,?LINE,Reason,Slave,App,Vsn,PodDir]}
			      end;
			  Reason ->
			      {error,[node(),?MODULE,?FUNCTION_NAME,?LINE,Reason,Slave,App,Vsn,PodDir]}
		      end
	   end,	     
    Result.

allocate_host(PodId,ScoringListOfHostId)->
    AppsInfo=[{{App,Vsn},db_service_catalog:git_path({App,Vsn})}||{App,Vsn}<-db_pods:application(PodId)],
    case db_pods:host(PodId) of
	{_,[]}->
	    [NewHostId|_]=ScoringListOfHostId,
	    {ok,{PodId,NewHostId,AppsInfo}};
	{_,HostIds}->
	    case [HostId||HostId<-HostIds,lists:member(HostId,ScoringListOfHostId)] of
		[]->
		    {error,[no_nodes_available,PodId,ScoringListOfHostId]};
		[NewHostId|_]->
		    {ok,{PodId,NewHostId,AppsInfo}}
	    end
    end.



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
filtering(PrefferedHostIds)->
    AvailableNodesId=lib_status:node_started(),
    [filtering(HostId,AvailableNodesId)||HostId<-PrefferedHostIds].

filtering(HostId,AvailableNodesId)->
    case lists:member(HostId,AvailableNodesId) of
	true->
	    HostId;
	false->
	    {error,[HostId]}
    end.
    


check_host(PodSpecIds)->
    check_host(PodSpecIds,[]).

check_host([],PrefferedHosts)->
    PrefferedHosts;
check_host([Id|T],Acc) ->
   % io:format("Id ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,Id}]), 
    NewAcc=case db_pods:host(Id) of
	       {_,[]}->
		   Acc;
	       {_,HostIds}->
		   lists:append(HostIds,Acc)
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
%% -------------------------------------------------------------------

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
