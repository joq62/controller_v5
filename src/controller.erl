%% Author: uabjle
%% Created: 10 dec 2012
%% Description: TODO: Add description to application_org
-module(controller). 

-behaviour(application).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Behavioural exports
%% --------------------------------------------------------------------
-export([boot/0,
	 start/2,
	 stop/1
        ]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([
	 
	]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------
-define(Lock,controller_lock).
%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% API Functions
%% --------------------------------------------------------------------


%% ====================================================================!
%% External functions
%% ====================================================================!

%% --------------------------------------------------------------------
%% Func: start/2
%% Returns: {ok, Pid}        |
%%          {ok, Pid, State} |
%%          {error, Reason}
%% --------------------------------------------------------------------
boot()->
    application:start(?MODULE).


%% --------------------------------------------------------------------
%% Func: start/2
%% Returns: {ok, Pid}        |
%%          {ok, Pid, State} |
%%          {error, Reason}
%% --------------------------------------------------------------------
start(_Type, _StartArgs) ->
    ok=init(),
    {ok,Pid}= controller_sup:start_link(),
    {ok,Pid}.
   
%% --------------------------------------------------------------------
%% Func: stop/1
%% Returns: any
%% --------------------------------------------------------------------
stop(_State) ->
    ok.

%% ====================================================================
%% Internal functions
%% ====================================================================
init()->
    Appfile=atom_to_list(?MODULE)++".app",
    Env=appfile:read(Appfile,env),
    {nodes,Nodes}=lists:keyfind(nodes,1,Env),
    {dir_logs,DirLogs}=lists:keyfind(dir_logs,1,Env),
    {support_applications,Applications}=lists:keyfind(support_applications,1,Env),
    
    [application:set_env(Application,nodes,Nodes)||Application<-Applications],

    %connect
    [net_adm:ping(Node)||Node<-Nodes],
    
    %
    DbaseNode=[lists:delete(node(),Nodes)|Nodes],
    ok=dbase:dynamic_db_init(DbaseNode),

    [application:start(Application)||Application<-Applications],
      
    ok.
