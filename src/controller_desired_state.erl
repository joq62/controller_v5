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
-include("logger_infra.hrl").
%%---------------------------------------------------------------------
%% Records for test
%%

%% --------------------------------------------------------------------
%-compile(export_all).
-export([
	 start/0
	]).

%% ====================================================================
%% External functions
%% ====================================================================
start()->
 %   io:format("********* ~p",[{time(),node(),"*********"}]),
  %  io:format("~n"),
    
    AllDepIds=db_deployment:all_id(),
    WantedState=[{DepId,db_deployment:pod_specs(DepId)}||DepId<-AllDepIds],
   % io:format("WantedState ~p~n",[{WantedState,?MODULE,?FUNCTION_NAME,?LINE}]),
    
   % {InstanceId,DepId,[{PodNode,PodDir,PodId}]}
    [check_pods_status(Status)||Status<-db_deploy_state:read_all()],	
  %  io:format("check_pods_status ~p~n",[{X,?MODULE,?FUNCTION_NAME,?LINE}]),
    timer:sleep(2000),    
    AllDeployStates=db_deploy_state:read_all(),		
%    log:log(?logger_info(info,"AllDeployStates = ",[AllDeployStates])), 
   % io:format("AllDeployStates ~p~n",[{AllDeployStates,?MODULE,?FUNCTION_NAME,?LINE}]),
    MissingDeployments=[{DepId,PodSpecs}||{DepId,PodSpecs}<-WantedState,
					  false=:=lists:keymember(DepId,2,AllDeployStates)],
  %  io:format("MissingDeployments ~p~n",[{MissingDeployments,?MODULE,?FUNCTION_NAME,?LINE}]),
    MissingControllers=[{DepId,PodSpecs}||{DepId,PodSpecs}<-MissingDeployments,
					  lists:member({"controller","1.0.0"},PodSpecs)],
  %  io:format("MissingControllers ~p~n",[{MissingControllers,?MODULE,?FUNCTION_NAME,?LINE}]),
    MissingWorkers=[{DepId,PodSpecs}||{DepId,PodSpecs}<-MissingDeployments,
					  lists:member({"worker","1.0.0"},PodSpecs)],
   % io:format("MissingWorkers ~p~n",[{MissingWorkers,?MODULE,?FUNCTION_NAME,?LINE}]),
    MissingRest=[{DepId,PodSpecs}||{DepId,PodSpecs}<-MissingDeployments,
				   false=:=lists:member({DepId,PodSpecs},MissingControllers),
				   false=:=lists:member({DepId,PodSpecs},MissingWorkers)],
  %  io:format("MissingRest ~p~n",[{MissingRest,?MODULE,?FUNCTION_NAME,?LINE}]),
    case MissingControllers of
	[]->
	    ok;
	MissingControllers->
	    deploy(MissingControllers),
	    log:log(?logger_info(info,"Missing  controllers",[MissingControllers])),
	    ok
    end,
    case MissingWorkers of
	[]->
	    ok;
	MissingWorkers->
	    deploy(MissingWorkers),
	    log:log(?logger_info(info,"Missing  workers",[MissingWorkers])),
	    ok
		
    end,
    case MissingRest of
	[]->
	    ok;
	MissingRest->
	    deploy(MissingRest),
	    log:log(?logger_info(info,"Missing  Rest",[MissingRest])),
	    ok
    end,
    ok.

check_pods_status({InstanceId,_DepId,PodList})->
    PingR=[{net_adm:ping(PodNode),PodNode,PodDir,PodId}||{PodNode,PodDir,PodId}<-PodList],
    case [{PodNode,PodDir,PodId}||{pang,PodNode,PodDir,PodId}<-PingR] of
	[]->
	    ok;
	ErrorList->
	    % Stop running pods and delete pod dirs
	    % Nodes is down - need to find out a node on the same host
	    AllPodInfo=db_deploy_state:pods(InstanceId), %[{PodNode,PodDir,PodId},,,]
	    HostNodes=[db_host:node(Id)||Id<-db_host:ids()],
	    %Stop running pods in 
	    [rpc:call(PodNode,init,stop,[],5*1000)||{PodNode,_,_}<-AllPodInfo],
	    delete_dirs(HostNodes,AllPodInfo),
	    
	    {atomic,ok}=db_deploy_state:delete(InstanceId),
	%    io:format("node_not_available, delete instance ~p~n",[{ErrorList,InstanceId,?MODULE,?FUNCTION_NAME,?LINE}]),
	    log:log(?logger_info(ticket,"node_not_available, delete instance",[ErrorList,InstanceId])),
	    {atomic,ok}
    end.
delete_dirs([],_AllPodInfo)->
    ok;
delete_dirs([HostNode|T],AllPodInfo)->
    [rpc:call(HostNode,os,cmd,["rm -rf "++PodDir],5*1000)||{_,PodDir,_}<-AllPodInfo],
    timer:sleep(500),
    delete_dirs(T,AllPodInfo).

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
deploy(MissingDepIdPodSpecs)->
    deploy(MissingDepIdPodSpecs,[]).
deploy([],StartRes)->
   StartRes;
deploy([{DepId,PodSpecs}|T],Acc)->
    log:log(?logger_info(info,"deploy,DepId,PodSpecs ",[DepId,PodSpecs])),
    HostId=case db_deployment:affinity(DepId) of
	       []->
		   random_host();
	       [XId] ->
		      % HostNode=db_host:node(HostId),
		   XId
	   end,
    {ok,DepInstanceId}=db_deploy_state:create(DepId,[]),
    NewAcc=case start_pod(PodSpecs,HostId,DepInstanceId,[]) of
	       {error,Reason}->
	%	   io:format("ticket,db_deploy_state:delete ~p~n",[{DepInstanceId,Reason,?MODULE,?FUNCTION_NAME,?LINE}]),
		   log:log(?logger_info(ticket,"db_deploy_state:delete",[DepInstanceId,Reason])),
		   {atomic,ok}=db_deploy_state:delete(DepInstanceId),		   
		   [{error,Reason}|Acc];
	       {ok,PodAppInfo}->
		   [{ok,PodAppInfo}|Acc]
	   end,
    
    deploy(T,NewAcc).
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

start_pod([],_HostId,_DepInstanceId,StartRes)->
    case [{error,Reason}||{error,Reason}<-StartRes] of
	[]->
	    {ok,[PodAppInfo||{ok,PodAppInfo}<-StartRes]};
	Reason->
	     {error,Reason}
    end;
start_pod([PodId|T],HostId,DepInstanceId,Acc) ->
    LoadStartRes=case pod:start_pod(PodId,HostId) of
		     {error,Reason}->
			 {error,Reason};
		     {ok,PodNode,PodDir}->
			 AppIds=db_pods:application(PodId),
			 case pod:load_start_apps(AppIds,PodId,PodNode,PodDir) of
			     {error,Reason}->
				 {error,Reason};
			     {ok,PodAppInfo}->
				 {atomic,ok}=db_deploy_state:add_pod_status(DepInstanceId,{PodNode,PodDir,PodId}),
	%			 io:format("info,add_pod_status  ~p~n",[{DepInstanceId,{PodNode,PodDir,PodId},?MODULE,?FUNCTION_NAME,?LINE}]),
				 log:log(?logger_info(info,"db_deploy_state:add_pod_status",[DepInstanceId,{PodNode,PodDir,PodId}])),
				 {ok,PodAppInfo}
				     
			 end
		 end,
    start_pod(T,HostId,DepInstanceId,[LoadStartRes|Acc]).
	      
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

random_host()->
    StartedNodes=lib_status:node_started(),
    N1=length_list(StartedNodes),
    N2=rand:uniform(N1),
    HostId=lists:nth(N2,StartedNodes),
    HostId.
  

length_list(L)->
    length_list(L,0).
length_list([],L)->
    L;
length_list([_|T],L)->
    length_list(T,L+1).



    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------


