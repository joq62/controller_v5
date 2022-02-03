%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(lib_controller).   
 
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("controller.hrl").
%% --------------------------------------------------------------------


%% External exports
-export([
	 get_spec/3,
	 actual_state/1,
	 
	 git_clone_service_specs_files/1,
	 read_specs/0
	]).
    


%% ====================================================================
%% External functions
%% ====================================================================
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
get_spec(Name,Vsn,ServiceSpecsList)->
    S1=[ServiceSpec||ServiceSpec<-ServiceSpecsList,
		  {Name,Vsn}=:={proplists:get_value(name,ServiceSpec),
				proplists:get_value(vsn,ServiceSpec)}],
    Result=case S1 of
	       []->
		   {error,eexists};
	       [ServiceSpec] ->
		   ServiceSpec
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% -------------------------------------------------------------------
actual_state(ServiceSpecsInfoList)->
    actual_state(ServiceSpecsInfoList,[]).

actual_state([],ActualStateList)->
    ActualStateList;
actual_state([ServiceSpec|T],Acc) ->
    ServiceVmList=sd:get(service),
    Id={proplists:get_value(name,ServiceSpec),proplists:get_value(vsn,ServiceSpec)},
    ServiceVms=[Vm||Vm<-ServiceVmList,
		    Id=:=rpc:call(Vm,service,id,[],5000)],
    Deployment=proplists:get_value(deployment,ServiceSpec),
    NumInstances=proplists:get_value(instances,ServiceSpec),

    Status=status(ServiceVms,Deployment,NumInstances),
%    ToDelete=to_delete(ServiceVms,Deployment,NumInstances),
    actual_state(T,[{Id,Status}|Acc]). 
    

to_delete([],[],_NumInstances)->
    {0,[]};

to_delete([],Deployment,NumInstances)->
    {NumInstances-lists:flatlength(Deployment),Deployment};

to_delete(_ServiceVms,[],_NumInstances)->
    {0,[]};

to_delete(ServiceVms,Deployment,NumInstances)->
    SortedServiceVms=lists:sort(ServiceVms),
    SortedDeployment=lists:sort(Deployment),

    Result=case SortedServiceVms=:=SortedDeployment of
	       true->
		   {0,[]};
	       false->
		   Vms=[X||X<-SortedDeployment,
			   lists:member(X,SortedServiceVms)],
		   {NumInstances-lists:flatlength(Vms),Vms}
	   end,
    Result.
    

status([],[],NumInstances)->
    {NumInstances,[]};

status([],_Deployment,NumInstances)->
    {NumInstances,[]};

status(ServiceVms,[],NumInstances)->
    {NumInstances-lists:flatlength(ServiceVms),ServiceVms};

status(ServiceVms,Deployment,NumInstances)->
    SortedServiceVms=lists:sort(ServiceVms),
    SortedDeployment=lists:sort(Deployment),
    Result=case SortedServiceVms=:=SortedDeployment of
	       true->
		   {0,[]};
	       false->
		   Vms=[X||X<-SortedServiceVms,
			   lists:member(X,SortedDeployment)],
		   {NumInstances-lists:flatlength(Vms),Vms}
	   end,
    Result.




%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% -------------------------------------------------------------------
git_clone_service_specs_files(Node)->
    rpc:call(Node,os,cmd,["rm -rf "++?ServiceSpecsFilesDir],5000),
    rpc:call(Node,os,cmd,["git clone "++?ServiceSpecsGitPath++" "++?ServiceSpecsFilesDir],5000),
    true=rpc:call(Node,code,add_patha,[?ServiceSpecsFilesDir],5000),
    ok.
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% -------------------------------------------------------------------
read_specs()->
    {ok,Files}=file:list_dir(?ServiceSpecsFilesDir),
    ServiceSepcFiles=[filename:join(?ServiceSpecsFilesDir,File)||File<-Files,
							    ".service"=:=filename:extension(File)],
    read_specs(ServiceSepcFiles,[]).

read_specs([],List)->
    List;
read_specs([File|T],Acc) ->
    {ok,Info}=file:consult(File),
    read_specs(T,[Info|Acc]).
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

