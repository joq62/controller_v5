%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(loader).   
 
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------


%% External exports
-export([
	 load_start/2
	]).



%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
load_start(AppId,HostId)->
    Node=db_host:node(HostId),
    ApplicationDir=db_host:application_dir(HostId),
    App=db_service_catalog:app(AppId),
    AppDir=atom_to_list(App),
    Ebin=filename:join([ApplicationDir,AppDir,"ebin"]),
    GitPath=db_service_catalog:git_path(AppId),
    rpc:call(Node,os,cmd,["rm -rf "++AppDir],5*1000),
    rpc:call(Node,os,cmd,["rm -rf "++filename:join(ApplicationDir,AppDir)],5*1000),
    rpc:call(Node,os,cmd,["git clone "++GitPath],5*1000),
    rpc:call(Node,os,cmd,["mv "++AppDir++" "++ApplicationDir],5*1000),
    rpc:call(Node,code,add_patha,[Ebin],5*1000),
    AppFile=Ebin++"AppDir"++".app",
    AppFile=rpc:call(Node,code,where_is_file,["AppDir"++".app"],5*1000),
    ok=rpc:call(Node,application,start,[App],15*1000),
    {ok,App,Node}.
    


%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
