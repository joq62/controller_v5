%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : resource discovery accroding to OPT in Action 
%%% This service discovery is adapted to 
%%% Type = application 
%%% Instance ={ip_addr,{IP_addr,Port}}|{erlang_node,{ErlNode}}
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(z).

-behaviour(gen_server).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("controller.hrl").
%% --------------------------------------------------------------------
-define(SERVER,?MODULE).
%% External exports
-export([
	 call/5,
	 sd/0,
	 start/1,
	 load/1,
	 restart/1,
	 leader/0,
	 schedule/1,
	 s/0
	 
	]).


%% gen_server callbacks
-export([
	 start/0,
	 stop/0
	]).



-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {loaded,
		spec_list
	       }).

%% ====================================================================
%% External functions
%% ====================================================================
start()-> gen_server:start_link({local, ?SERVER}, ?SERVER, [], []).
stop()-> gen_server:call(?SERVER, {stop},infinity).

call(Host,M,F,A,T)->
    gen_server:call(?SERVER, {call,Host,M,F,A,T},infinity).
leader()->
    gen_server:call(?SERVER, {leader},infinity).
sd()->
    gen_server:call(?SERVER, {sd},infinity).
load(Host)->
    gen_server:call(?SERVER, {load,Host},infinity).
start(Host)->
    gen_server:call(?SERVER, {start,Host},infinity).
restart(Host)->
    gen_server:call(?SERVER, {restart,Host},infinity).
schedule(DepId)->
    gen_server:call(?SERVER, {schedule,DepId},infinity).
s()->
    gen_server:call(?SERVER, {s},infinity).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    ok=lib_z:load_configs(),
    ok=lib_z:connect(),
    
    ok=lib_z:start_needed_apps(),
    ok=lib_z:initiate_dbase(),
    
    % kill orphans
    KilledNodes=[{Node,rpc:call(Node,init,stop,[],100)}||Node<-nodes(),
				     false=:=lists:member(Node,[host@c203|lib_z:get()])],
    
    timer:sleep(3000),
    ScratchDirs=[lib_z:scratch_workers(Node)||Node<-nodes()],
    io:format("ScratchDirs ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,ScratchDirs}]),
    io:format("KilledNodes ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,KilledNodes}]),
    io:format("sd(stdlib) ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE,sd:get(stdlib)}]),
    
    {ok, #state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call({call,Host,M,F,A,T},_From, State) ->
    Reply=rpc:call(db_host:node({Host,"host"}),M,F,A,T),
    {reply, Reply, State};


handle_call({s},_From, State) ->
   
%    Reply=lib_z:schedule({"math","1.0.0"}),
    Deployments=lib_z:schedule(),
    Reply=case [{error,Reason}||{error,Reason}<-Deployments] of
	      []->
		  [{db_deployment:update_status(DeploymentId,Pods),DeploymentId,Pods}||{ok,DeploymentId,Pods}<-Deployments];
	      ErrorList->
		  {error,[ErrorList]}
	  end,
       {reply, Reply, State};

handle_call({schedule,Id},_From, State) ->
    Reply=lib_z:schedule(Id),
    {reply, Reply, State};

handle_call({start,Host},_From, State) ->
   
    Reply=lib_os:start({Host,"host"}),
    {reply, Reply, State};

handle_call({load,Host},_From, State) ->
    
    Reply=loader:load_start({controller,"0.1.0"},{Host,"host"}),
    {reply, Reply, State};


handle_call({leader},_From, State) ->
    Reply=case sd:get(bully) of
	      []->
		  [];
	      [Node|_]->
		  rpc:call(Node,bully,who_is_leader,[],2000)
	  end,
    {reply, Reply, State};
handle_call({sd},_From, State) ->
    Reply=sd:all(),
    {reply, Reply, State};

handle_call({restart,Host},_From, State) ->
    Id={Host,"host"},
    Reply=lib_os:restart(Id),
    {reply, Reply, State};
handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    Reply = {unmatched_signal,?MODULE,Request,From},
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({deallocate,Node,App}, State) ->
    loader:deallocate(Node,App),
    {noreply, State};

handle_cast({desired_state}, State) ->
    S=self(),
   %  io:format("~p~n",[{time(),S,node(),bully:am_i_leader(node()),?MODULE,?FUNCTION_NAME,?LINE}]),
    spawn(fun()->call_desired_state(S) end),
    {noreply, State};

handle_cast(Msg, State) ->
    io:format("unmatched match cast ~p~n",[{Msg,?MODULE,?LINE}]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({Id, desired_state_ret,ResultList}, State) ->
    io:format("~p~n",[{time(),node(),?MODULE,?FUNCTION_NAME,?LINE,
		      Id,desired_state_ret,ResultList}]), 
    {noreply, State};

handle_info(Info, State) ->
    io:format("unmatched handle_info ~p~n",[{Info,?MODULE,?LINE}]), 
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
call_desired_state(MyPid)->
  %  io:format("~p~n",[{time(),node(),MyPid,bully:am_i_leader(node()),?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=host:desired_state(MyPid),	      
   % io:format("~p~n",[{time(),node(),?MODULE,?FUNCTION_NAME,?LINE,R}]),
    timer:sleep(?ScheduleInterval),
    Result=rpc:call(node(),controller_desired_state,start,[],1*60*1000),
 %   not_implmented=Result,
%    io:format("~p~n",[{time(),node(),MyPid,Result,?MODULE,?FUNCTION_NAME,?LINE}]),
    rpc:cast(node(),controller,desired_state,[]).
		  
