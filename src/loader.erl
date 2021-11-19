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
	 load_services/0,
	 allocate/1,
	 deallocate/2
	]).



%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
deallocate(Node,App)->
    stopped=rpc:call(Node,application,stop,[App],5*1000),
    slave:stop(Node),
    ok.

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
allocate(App)-> % The calling shall monitor and take actions if node or application dies
    %% Start the needed Node 
    ServiceFile=atom_to_list(App)++".beam",
    ServiceFullFileName=code:where_is_file(ServiceFile),
    ServiceEbinDir=filename:dirname(ServiceFullFileName),
    Cookie=atom_to_list(erlang:get_cookie()),
    %% Infra functions needed [sd
    SdFileName=code:where_is_file("sd.beam"),
    SdEbinDir=filename:dirname(SdFileName),
    % start slave 
    Name =list_to_atom(lists:flatten(io_lib:format("~p",[erlang:system_time()]))),
    {ok,Host}=net:gethostname(),
    Args="-pa "++ServiceEbinDir++" "++"-pa "++SdEbinDir++" "++"-setcookie "++Cookie,
    {ok,Node}=slave:start(Host,Name,Args),
 %   io:format("Node nodes() ~p~n",[{Node,nodes()}]),
    true=net_kernel:connect_node(Node),
%    true=erlang:monitor_node(Node,true),
    %% Start application 
    ok=rpc:call(Node,application,start,[App],5*1000),
   
     %% Start the gen_server and monitor it instead of using superviosur  
%    {ok,PidApp}=rpc:call(Node,App,start,[],5000),
 %   AppMonitorRef=erlang:monitor(process,PidApp),
    {ok,Node}.
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
load_services()->
    EnvVar=service_catalog,
    Env=appfile:read("kublet.app",env),
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
load_service(RootDir,{App,Vsn,GitPath})->
    AppId=atom_to_list(App),
    SourceDir=AppId,
    DestDir=filename:join(RootDir,AppId++"-"++Vsn),
    os:cmd("rm -rf "++DestDir),
    os:cmd("git clone "++GitPath),
    os:cmd("mv "++SourceDir++" "++DestDir),
    case code:add_patha(filename:join(DestDir,"ebin")) of
	true->
	    ok=application:start(App),
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
