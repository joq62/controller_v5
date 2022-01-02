%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(init_test).    
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

-include("controller.hrl").
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
  %  io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start pass0()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=pass0(),
    io:format("~p~n",[{"Stop pass0()",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start pass1()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=pass1(),
%    io:format("~p~n",[{"Stop pass1()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start pass2()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=pass2(),
    io:format("~p~n",[{"Stop pass2()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start add_node()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=add_node(),
 %   io:format("~p~n",[{"Stop add_node()",?MODULE,?FUNCTION_NAME,?LINE}]),

 %   io:format("~p~n",[{"Start node_status()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=node_status(),
 %   io:format("~p~n",[{"Stop node_status()",?MODULE,?FUNCTION_NAME,?LINE}]),

%   io:format("~p~n",[{"Start start_args()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=start_args(),
 %   io:format("~p~n",[{"Stop start_args()",?MODULE,?FUNCTION_NAME,?LINE}]),

%   io:format("~p~n",[{"Start detailed()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok=detailed(),
%    io:format("~p~n",[{"Stop detailed()",?MODULE,?FUNCTION_NAME,?LINE}]),

%   io:format("~p~n",[{"Start start_stop()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=start_stop(),
 %   io:format("~p~n",[{"Stop start_stop()",?MODULE,?FUNCTION_NAME,?LINE}]),



 %   
      %% End application tests
  %  io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
  %  io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.

    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
pass0()->

    ok.
    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
pass2()->
    case sd:get(dbase_infra) of
	[]->
	    io:format("{error = ~p~n",[{error,[],?MODULE,?FUNCTION_NAME,?LINE}]),
	    timer:sleep(3000),
	    pass2();
	[N|_]->
	    Ids=rpc:call(N,db_logger,ids,[],3000),
	    case Ids of
		[]->
		    io:format("{No Ids = ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
		    timer:sleep(3000),
		    pass2();
		Ids->
		    OldNew=q_sort:sort(Ids),
		    Latest=lists:last(OldNew),
		%    SortedIds=lists:reverse(q_sort:sort(Ids)),
		   % io:format("SortedIds = ~p~n",[{SortedIds,?MODULE,?FUNCTION_NAME,?LINE}]),
		    X=[{Id,rpc:cast(N,db_logger,nice_print,[Id])}||Id<-OldNew],
		 %   io:format("{X = ~p~n",[{X,?MODULE,?FUNCTION_NAME,?LINE}]),
		    spawn(fun()->print_log(Latest) end)
	    end
    end,   
    ok.
%1640895289526372,
%1640895289488269,
%1640895277391540

print_log(Latest)->
    NewLatest=case sd:get(dbase_infra) of
		  []->
		      io:format("{error, = ~p~n",[{error,[],?MODULE,?FUNCTION_NAME,?LINE}]),
		      Latest;
		  [N|_]->
		      Ids=rpc:call(N,db_logger,ids,[],3000),
		      case Ids of
			  []->
			      io:format("{No Ids = ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
			      Latest;
			  Ids->
			      OldNew=q_sort:sort(Ids),
			      XLatest=lists:last(OldNew),
			   %   SortedIds=lists:reverse(q_sort:sort(Ids)),
			   %   io:format("SortedIds = ~p~n",[{SortedIds,?MODULE,?FUNCTION_NAME,?LINE}]),
			      [rpc:cast(N,db_logger,nice_print,[Id])||Id<-OldNew,
									   Id>Latest],
			      XLatest
		      end
	      end,   
    timer:sleep(2000),
    print_log(NewLatest).
		     
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
pass1()->
    AllHostIdNodes=[{HostId,db_host:node(HostId)}||HostId<-db_host:ids()],
    [{{"c100","host1"},host1@c100},
     {{"c100","host2"},host2@c100},
     {{"c100","host3"},host3@c100}, 
     {{"c100","host4"},host4@c100}]=lists:sort(AllHostIdNodes),
    
    AllDepIds=db_deployment:all_id(),
    WantedState=[{DepId,db_deployment:pod_specs(DepId)}||DepId<-AllDepIds],
    io:format("WantedState ~p~n",[{WantedState,?MODULE,?FUNCTION_NAME,?LINE}]),

    AllDeployStates=lists:append([db_deploy_state:deployment(Id)||Id<-db_deploy_state:deploy_id()]),
    io:format("AllDeployStates ~p~n",[{AllDeployStates,?MODULE,?FUNCTION_NAME,?LINE}]),
    %{Id,DeploymentId,Pods}
    MissingDeployments=[{DepId,PodSpecs}||{DepId,PodSpecs}<-WantedState,
					  false=:=lists:keymember(DepId,2,AllDeployStates)],
    MissingControllers=[{DepId,PodSpecs}||{DepId,PodSpecs}<-MissingDeployments,
					  lists:member({"controller","1.0.0"},PodSpecs)],
    io:format("MissingControllers ~p~n",[{MissingControllers,?MODULE,?FUNCTION_NAME,?LINE}]),
    MissingWorkers=[{DepId,PodSpecs}||{DepId,PodSpecs}<-MissingDeployments,
					  lists:member({"worker","1.0.0"},PodSpecs)],
    io:format("MissingWorkers ~p~n",[{MissingWorkers,?MODULE,?FUNCTION_NAME,?LINE}]),
    MissingRest=[{DepId,PodSpecs}||{DepId,PodSpecs}<-MissingDeployments,
				   false=:=lists:member({DepId,PodSpecs},MissingControllers),
				   false=:=lists:member({DepId,PodSpecs},MissingWorkers)],
    io:format("MissingRest ~p~n",[{MissingRest,?MODULE,?FUNCTION_NAME,?LINE}]),

    R1=deploy(MissingControllers),
    io:format("Res MissingControllers ~p~n",[{R1,?MODULE,?FUNCTION_NAME,?LINE}]),
    R2=deploy(MissingWorkers),
    io:format("Res MissingWorkers ~p~n",[{R2,?MODULE,?FUNCTION_NAME,?LINE}]),
    R3=deploy(MissingRest),
    io:format("Res MissingRest ~p~n",[{R3,?MODULE,?FUNCTION_NAME,?LINE}]),
 %   SortedDepIdPodSpecs=pod_specs(WantedState),
 %   io:format("SortedDepIdPodSpecs ~p~n",[{SortedDepIdPodSpecs,?MODULE,?FUNCTION_NAME,?LINE}]),
 %   SortedDepIdPodSpecsApps=app_specs(SortedDepIdPodSpecs),
 %   io:format("SortedDepIdPodSpecsApps ~p~n",[{SortedDepIdPodSpecsApps,?MODULE,?FUNCTION_NAME,?LINE}]),
   % DeployIds=db_deploy_state:deploy_id(),
    %Check that all controllers or workers are loaded 
  %  gl=DeployIds,

    ok.

deploy(MissingDepIdPodSpecs)->
    deploy(MissingDepIdPodSpecs,[]).
deploy([],StartRes)->
   StartRes;
deploy([{DepId,PodSpecs}|T],Acc)->
    HostId=case db_deployment:affinity(DepId) of
	       []->
		   random_host();
	       [XId] ->
		      % HostNode=db_host:node(HostId),
		   XId
	   end,
    DepInstanceId=db_deploy_state:create(DepId,[]),
    R=start_pod(PodSpecs,HostId,DepInstanceId,[]),
    deploy(T,[R|Acc]).

start_pod([],HostId,DepInstanceId,StartRes)->
    StartRes;
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
				 db_deploy_state:add_pod_status(DepInstanceId,{PodNode,PodDir,PodId}),
				 {ok,PodAppInfo}
				     
			 end
		 end,
    start_pod(T,HostId,DepInstanceId,[LoadStartRes|Acc]).
	      
    

random_host()->
    StartedNodes=lib_status:node_started(),
    N1=length_list(StartedNodes),
    N2=rand:uniform(N1),
    HostId=lists:nth(N2,StartedNodes).
  

length_list(L)->
    length_list(L,0).
length_list([],L)->
    L;
length_list([_|T],L)->
    length_list(T,L+1).



app_specs(SortedDepIdPodSpecs)->
    app_specs(SortedDepIdPodSpecs,[]).
app_specs([],SortedDepIdPodSpecsApps)->
    SortedDepIdPodSpecsApps;
app_specs([{DepId,PodId}|T],Acc) ->
    R={DepId,PodId,db_pods:application(PodId)},
  %  R=[{DepId,PodId,AppInfo}||AppInfo<-db_pods:application(PodId)],
    NewAcc=[R|Acc],
    app_specs(T,NewAcc).

pod_specs(DepIdPodSpecs)->
    pod_specs(DepIdPodSpecs,[]).
pod_specs([],SortedDepIdPodSpecs)->
    SortedDepIdPodSpecs;
pod_specs([{DepId,PodSpecs}|T],Acc) ->
%    io:format("DepId,PodSpecs ~p~n",[{DepId,PodSpecs,?MODULE,?FUNCTION_NAME,?LINE}]),
    R=[{DepId,PodId}||PodId<-PodSpecs],
    NewAcc=lists:append(R,Acc),
    pod_specs(T,NewAcc).

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
    %% 
 %   [CtrlNode|_]=[N||{{"controller","1.0.0"},N,_Dir,_App,Vsn}<-AppInfo],
    
  %  io:format("CtrlNode, sd:all() ~p~n",[{rpc:call(CtrlNode,sd,all,[],5*1000),?MODULE,?FUNCTION_NAME,?LINE}]),
  %  timer:sleep(1000),
  % io:format(" who_is_leader ~p~n",[{rpc:call(CtrlNode,bully,who_is_leader,[],5*1000),?MODULE,?FUNCTION_NAME,?LINE}]),

    
    %%
 %   DbaseNodes=rpc:call(CtrlNode,sd,get,[dbase_infra],5*1000),
 %   io:format("DbaseNodes ~p~n",[{DbaseNodes,?MODULE,?FUNCTION_NAME,?LINE}]),
 %   X1=[{N,rpc:call(N,db_service_catalog,read_all,[],5*1000)}||N<-DbaseNodes],
  %  io:format("db_service_catalog ~p~n",[{X1,?MODULE,?FUNCTION_NAME,?LINE}]),
  %  X2=[{N,rpc:call(N,mnesia,system_info,[],5*1000)}||N<-DbaseNodes],
  %  io:format("mnesia:system_info ~p~n",[{X2,?MODULE,?FUNCTION_NAME,?LINE}]),
    
    %%
 %   io:format("db_deploy_state ~p~n",[{db_deploy_state:read_all(),?MODULE,?FUNCTION_NAME,?LINE}]),
    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
    
%get_nodes()->
 %   [host1@c100,host2@c100,host3@c100,host4@c100].
    
%start_slave(NodeName)->
 %   HostId=net_adm:localhost(),
  %  Node=list_to_atom(NodeName++"@"++HostId),
   % rpc:call(Node,init,stop,[]),
    
   % Cookie=atom_to_list(erlang:get_cookie()),
   % gl=Cookie,
  %  Args="-pa ebin -setcookie "++Cookie,
  %  io:format("Node Args ~p~n",[{Node,Args}]),
  %  {ok,Node}=slave:start(HostId,NodeName,Args).

setup()->

 
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
  
    ok.
