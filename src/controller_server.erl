%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : resource discovery accroding to OPT in Action 
%%% This service discovery is adapted to 
%%% Type = application 
%%% Instance ={ip_addr,{IP_addr,Port}}|{erlang_node,{ErlNode}}
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(controller_server).

-behaviour(gen_server).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("controller.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([
	]).


%% gen_server callbacks



-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {loaded,
		spec_list
	       }).

%% ====================================================================
%% External functions
%% ====================================================================


schedule()->
    gen_server:cast(?MODULE, {schedule}).

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

    ok=lib_controller:connect(),
    ok=lib_controller:start_needed_apps(),
    ok=lib_controller:initiate_dbase(),
    
    case bully:am_i_leader(node()) of
	false->
	    act_follower;
	true->
	    host:desired_state(self())
    end,
    S=self(),
    spawn(fun()->call_desired_state(S) end),
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
handle_call({allocate,App},_From, State) ->
    Reply=loader:allocate(App),
    {reply, Reply, State};


handle_call({loaded},_From, State) ->
    Reply=State#state.loaded,
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
    Result=rpc:call(node(),controller_desired_state,start,[],10*1000),
 %   not_implmented=Result,
%    io:format("~p~n",[{time(),node(),MyPid,Result,?MODULE,?FUNCTION_NAME,?LINE}]),
    rpc:cast(node(),controller,desired_state,[]).
		  
