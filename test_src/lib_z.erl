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
	 initiate_dbase/0
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
    timer:sleep(1000),
    ok.

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
initiate_dbase()->
  
    DbaseServices=[{db_host,?HostConfiguration},
		   {db_service_catalog,?ServiceCatalog},
		   {db_deployment,?Deployments}],
    LoadR=[load_from_file(node(),Module,Source)||{Module,Source}<-DbaseServices],
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
