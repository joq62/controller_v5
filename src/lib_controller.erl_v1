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

%% --------------------------------------------------------------------


%% External exports
-export([
	 load_services/0
	]).



%% ====================================================================
%% External functions
%% ====================================================================

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
