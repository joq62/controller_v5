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
    % copy logs
    os:cmd("rm -rf  logs"),
    file:make_dir("logs"),
    os:cmd("cp apps/*/log/* logs"),
    %% Init dbase
    mnesia:stop(),
    mnesia:delete_schema([node()]),
    mnesia:start(),
    Appfile=atom_to_list(?MODULE)++".app",
    [{nodes,Nodes}]=appfile:read(Appfile,env),
    Result=case [Node||Node<-Nodes,pong=:=net_adm:ping(Node)] of
	       []-> % First Node
		   ok=db_lock:create_table(),
		   {atomic,ok}=db_lock:create(?Lock,1,node()),
		   true=db_lock:is_open(?Lock,node(),2),
		   true=db_lock:is_leader(?Lock,node()),
		   ok;
	       ConnectedNodes->
		   add_this_node(ConnectedNodes,false),
		   ok
	   end,
    Result.	    

add_this_node([],Result)->
    Result;
add_this_node(_,ok) ->
    ok;
add_this_node([Node1|T],_Acc)->
    NewAcc=case rpc:call(Node1,db_lock,add_node,[node(),ram_copies],5000) of
	       {badrpc,_}->
		   false;
	       ok->
		   ok;
	       _Error->
		   false
	   end,
    add_this_node(T,NewAcc).	    
