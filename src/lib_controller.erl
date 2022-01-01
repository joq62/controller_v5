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
	 load_configs/0,
	 load_configs/1,
	 delete_configs/0,
	 connect/0,
	 start_needed_apps/0,
	 initiate_dbase/0,
	 initiate_dbase/1,
	 load_services/0
	]).
    


%% ====================================================================
%% External functions
%% ====================================================================
load_configs()->
    {TestDir,TestPath}=?TestConfig,
    {Dir,Path}=?Config,
    os:cmd("rm -rf "++TestDir),
    os:cmd("rm -rf "++Dir),
    os:cmd("git clone "++TestPath),
    os:cmd("git clone "++Path),
    ok.
delete_configs()->
    {TestDir,_TestPath}=?TestConfig,
    {Dir,_Path}=?Config,
    os:cmd("rm -rf "++TestDir),
    os:cmd("rm -rf "++Dir),
    ok.
    

load_configs(Root)->
    {TestDir,TestPath}=?TestConfig,
    {ProductionDir,Path}=?Config,
    TDir=filename:join(Root,TestDir),
    PDir=filename:join(Root,ProductionDir),
    os:cmd("rm -rf "++TDir),
    os:cmd("rm -rf "++PDir),
    os:cmd("git clone "++TestPath),
    os:cmd("mv "++TestDir++" "++Root),
    os:cmd("git clone "++Path),
    os:cmd("mv "++ProductionDir++" "++Root),
    
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
 %   ok=initiate_dbase(),
    ok=application:start(sd),
    ok=application:start(logger_infra),
    ControllerNodes=connect:get(?ControllerNodes),
    application:set_env([{bully,[{nodes,ControllerNodes}]}]),
    ok=application:start(bully),
    ok=application:start(host),

    timer:sleep(1000),
    ok.

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
initiate_dbase()->
    initiate_dbase(".").    
initiate_dbase(Root)->
    ControllerNodesSpecFile=filename:join(Root,?ControllerNodes),
    RunningNodes=lists:delete(node(),connect:start(ControllerNodesSpecFile)),
    NodesMnesiaStarted=[Node||Node<-RunningNodes,
			      yes=:=rpc:call(Node,mnesia,system_info,[is_running],1000)],
    DbaseSpecs=dbase_infra:get_dbase_specs(),
    Result=case NodesMnesiaStarted of
	       []-> % initial start
		   DbaseSpecs_2=[{Module,filename:join(Root,Dir),Directive}||{Module,Dir,Directive}<-DbaseSpecs],
		   LoadResult=[{Module,dbase_infra:load_from_file(Module,Dir,Directive)}||{Module,Dir,Directive}<-DbaseSpecs_2],
		   case [{Module,R}||{Module,R}<-LoadResult,R/=ok] of
		       []->
			   ok;
		       ReasonList->
			   {error,ReasonList}
		   end;
	       [Node0|_]->
		   ok=rpc:call(node(),dbase_infra,add_dynamic,[Node0],3*1000),
		   timer:sleep(500),
		   _R=[rpc:call(node(),dbase_infra,dynamic_load_table,[node(),Module],3*1000)||{Module,_}<-DbaseSpecs],
		   
		   timer:sleep(500),
		   ok
	   end,
    Result.


%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
load_services()->
    EnvVar=service_catalog,
    Env=appfile:read("controller.app",env),
    {EnvVar,Info}=lists:keyfind(EnvVar,1,Env),
    Dir=proplists:get_value(dir,Info),
    FileName=proplists:get_value(filename,Info),
    GitPath=proplists:get_value(git_path,Info),
    RootDir="my_services",

    os:cmd("rm -rf "++RootDir),
    ok=file:make_dir(RootDir),
    
    ok=clone(Dir,GitPath),
    {ok,CatalogInfo}=catalog_info(Dir,FileName),
    [load_service(RootDir,ServiceInfo)||ServiceInfo<-CatalogInfo].
    

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
load_service(RootDir,{App,_Vsn,GitPath})->
    AppId=atom_to_list(App),
    SourceDir=AppId,
    DestDir=filename:join(RootDir,AppId),
    os:cmd("rm -rf "++DestDir),
    os:cmd("git clone "++GitPath),
    os:cmd("mv "++SourceDir++" "++DestDir),
    case code:add_patha(filename:join(DestDir,"ebin")) of
	true->
	    ok=application:load(App),
	    {ok,App};
	Reason->
	    {error,[Reason,App,DestDir]}
    end.
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
clone(Dir,GitPath)->
    os:cmd("rm -rf "++Dir),
    os:cmd("git clone "++GitPath),

    ok.
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
catalog_info(Dir,FileName)->
    {ok,CatalogInfo}=file:consult(filename:join([Dir,FileName])),    
    {ok,CatalogInfo}.
