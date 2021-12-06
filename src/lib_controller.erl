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
	 connect/0,
	 start_needed_apps/0,
	 initiate_dbase/0,
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
    RunningNodes=lists:delete(node(),connect:start(?ControllerNodes)),
    NodesMnesiaStarted=[Node||Node<-RunningNodes,
			      yes=:=rpc:call(Node,mnesia,system_info,[is_running],1000)],
   % io:format("NodesMnesiaStarted ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,node(),NodesMnesiaStarted}]),
    DbaseServices=?DbaseServices,
  %  io:format("DbaseServices ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,node(),DbaseServices}]),
    case NodesMnesiaStarted of
	[]-> % initial start
	    case [{error,Reason}||{error,Reason}<-[load_from_file(node(),Module,Source)||{Module,Source}<-DbaseServices]] of
		[]->
		    ok;
		ReasonList->
		    {error,ReasonList}
	    end;
	[Node0|_]->
%	    io:format("Node0 ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,Node0}]),
	    ok=rpc:call(node(),dbase_infra,add_dynamic,[Node0],3*1000),
	    timer:sleep(500),
	    _R=[rpc:call(node(),dbase_infra,dynamic_load_table,[node(),Module],3*1000)||{Module,_}<-DbaseServices],
	    
	    timer:sleep(500),
	    ok
    end,
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
