%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(scheduler).  
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%%---------------------------------------------------------------------
%% Records for test
%%

%% --------------------------------------------------------------------
-compile(export_all).


%% ====================================================================
%% External functions
%% ====================================================================

% Wanted application state = application is deployed according to spec
% Total number of replicas = deployed
% Replicas at required host 
%  
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start()->
    WantedState=db_deployment:wanted_state(node()),
    StartResult=[start_app(StartInfo)||StartInfo<-WantedState],
    StartResult.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

start_app({App,GitPath})->
    Result=case [Z||{Z,_,_}<-application:which_applications(),
		Z=:=App] of
	       []->
		   AppDir=atom_to_list(App),
		   os:cmd("rm -rf "++AppDir),
		   os:cmd("git clone "++GitPath),
		   Ebin=filename:join(AppDir,"ebin"),
		   case code:add_patha(Ebin) of
		       {error, bad_directory}->
			   {error, bad_directory};
		       true->
			   case application:start(App) of
			       ok->
				   ok;
			       Reason->
				   {error,Reason}
			   end
		   end;
	       _->
		   {error,[already_started,App]}
	   end,
    Result.
