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
    io:format("~p~n",[{node(),?MODULE,?FUNCTION_NAME,?LINE,
			AppId,HostId}]),
    io:format("~p~n",[{node(),?MODULE,?FUNCTION_NAME,?LINE,
		      Node,ApplicationDir,App,Ebin,GitPath}]),
    Xtrue=rpc:call(Node,filelib,is_dir,[ApplicationDir],5*1000),
    io:format("is_dir ~p~n",[{node(),?MODULE,?FUNCTION_NAME,?LINE,
			      Xtrue}]),
    Xrm1=rpc:call(Node,os,cmd,["rm -rf "++AppDir],5*1000),
    io:format("Xrm1 ~p~n",[{node(),?MODULE,?FUNCTION_NAME,?LINE,
			   Xrm1}]),
    Xrm2=rpc:call(Node,os,cmd,["rm -rf "++filename:join(ApplicationDir,AppDir)],5*1000),
    io:format("Xrm2 ~p~n",[{node(),?MODULE,?FUNCTION_NAME,?LINE,
			      Xrm2}]),
    Clone=rpc:call(Node,os,cmd,["git clone "++GitPath],5*1000),
    io:format("Clone ~p~n",[{node(),?MODULE,?FUNCTION_NAME,?LINE,
			      Clone}]),
    Mv=rpc:call(Node,os,cmd,["mv "++AppDir++" "++ApplicationDir],5*1000),
    io:format("Mv ~p~n",[{node(),?MODULE,?FUNCTION_NAME,?LINE,
			      Mv}]),
    Xpatha=rpc:call(Node,code,add_patha,[Ebin],5*1000),
    io:format("Xpatha ~p~n",[{node(),?MODULE,?FUNCTION_NAME,?LINE,
			      Xpatha}]),
    AppFile=filename:join(Ebin,AppDir++".app"),
    io:format("AppFile ~p~n",[{node(),?MODULE,?FUNCTION_NAME,?LINE,
			       AppFile}]),
    WhereIsFile=rpc:call(Node,code,where_is_file,[AppDir++".app"],5*1000),
    io:format("WhereIsFile ~p~n",[{node(),?MODULE,?FUNCTION_NAME,?LINE,
				   WhereIsFile}]),
    case  rpc:call(Node,application,start,[App],15*1000) of
	ok->
	    io:format("appstart ~p~n",[{node(),?MODULE,?FUNCTION_NAME,?LINE,
			      ok}]),
	    db_host:update_status(HostId,active);
	Reason->
	      io:format("appstart ~p~n",[{node(),?MODULE,?FUNCTION_NAME,?LINE,
			      error,Reason}])
    end,
   
    {ok,App,Node}.
    


%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
