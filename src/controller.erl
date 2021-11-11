%% Author: uabjle
%% Created: 10 dec 2012
%% Description: TODO: Add description to application_org
-module(controller). 

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Behavioural exports
%% --------------------------------------------------------------------
-export([
	 loaded/0,
	 boot/0
	]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([start/0,
	 stop/0]).
%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------
-define(SERVER,controller_server).
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
    application:start(?SERVER).


%% --------------------------------------------------------------------
%% Func: start/2
%% Returns: {ok, Pid}        |
%%          {ok, Pid, State} |
%%          {error, Reason}
%% --------------------------------------------------------------------
start()-> gen_server:start_link({local, ?SERVER}, ?SERVER, [], []).
stop()-> gen_server:call(?SERVER, {stop},infinity).



loaded()->
    gen_server:call(?SERVER, {loaded},infinity).
    
%% ====================================================================
%% Internal functions
%% ====================================================================

