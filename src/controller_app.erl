%% Author: uabjle
%% Created: 10 dec 2012
%% Description: TODO: Add description to application_org
-module(controller_app). 

-behaviour(application).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Behavioural exports
%% --------------------------------------------------------------------
-export([
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



%% --------------------------------------------------------------------
%% Func: start/2
%% Returns: {ok, Pid}        |
%%          {ok, Pid, State} |
%%          {error, Reason}
%% --------------------------------------------------------------------
start(_Type, _StartArgs) ->
  %  ok=init(),
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
    {support_applications,Applications}=lists:keyfind(support_applications,1,Env),
    
    [application:set_env(Application,nodes,Nodes)||Application<-Applications],

    %connect
    RunningNodes=[Node||Node<-lists:delete(node(),Nodes),
		       pong=:=net_adm:ping(Node)],
    DbaseNodes=[Node||Node<-RunningNodes,
		      yes=:=rpc:call(Node,mnesia,system_info,[is_running],1000)],
  %  io:format("node(),DbaseNodes ~p~n",[{node(),DbaseNodes,?FUNCTION_NAME,?MODULE,?LINE}]),
    ok=dbase:dynamic_db_init(DbaseNodes),

    [application:start(Application)||Application<-Applications],
    timer:sleep(1000),
    ok.
