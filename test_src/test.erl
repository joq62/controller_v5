%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test).    
     
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
%-include_lib("eunit/include/eunit.hrl").
%% --------------------------------------------------------------------



%% External exports
-export([start/0]). 


%% ====================================================================
%% External functions
%% ====================================================================


%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
start()->
    io:format("~p~n",[{"Start setup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=setup(),
    io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

  %  io:format("~p~n",[{"Start init_start()",?MODULE,?FUNCTION_NAME,?LINE}]),
  %  ok=init_start(),
  %  io:format("~p~n",[{"Stop init_start()",?MODULE,?FUNCTION_NAME,?LINE}]),
    
 %   io:format("~p~n",[{"Start pass_0()",?MODULE,?FUNCTION_NAME,?LINE}]),
 %   ok=pass_0(),
 %   io:format("~p~n",[{"Stop pass_0()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start pass_1()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=pass_1(),
    io:format("~p~n",[{"Stop pass_1()",?MODULE,?FUNCTION_NAME,?LINE}]),
 
     %% End application tests
    io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
    io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.



%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
backup_log_dir()->
    os:cmd("rm -rf  logs"),
    file:make_dir("logs"),
    os:cmd("cp apps/*/log/* logs"),
    
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
init_start()->
    % This is according to normal start on a host
  %  backup_log_dir(),
    % git clone ...controller.git
    ok=application:start(controller),
    
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_0()->
    [{application,controller,
     [{description,"Controller application and cluster"},
      {vsn,"0.1.0"},
      {modules,[controller,controller_sup,controller_server]},
      {registered,[controller]},
      {applications,[kernel,stdlib]},
      {mod,{controller,[]}},
      {start_phases,[]},
      {git_path,"https://github.com/joq62/controller.git"},
      {env,[{nodes,['controller@c0',
		    'controller@c2',
		    'controller@joq62-X550CA'
		   ]}
	   ]
      }
     ]
     }
    ]=appfile:read("controller.app",all),
    "https://github.com/joq62/controller.git"=appfile:read("controller.app",git_path),
    [{nodes,['controller@c0',
	     'controller@c2',
	     'controller@joq62-X550CA']}]=appfile:read("controller.app",env),
    {error,[eexists,glurk,read_app_file,appfile,_Line]}=appfile:read("controller.app",glurk),
    {error,enoent}=appfile:read("glurk.app",git_path),
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------




%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_1()->
    
    dbase:dynamic_db_init([]),
    [{myadd,"1.0.0","https://github.com/joq62/myadd.git",2,[]},
     {mydivi,"1.0.0","https://github.com/joq62/mydivi.git",1,
      [controller@c0]}]=db_deployment:read_all(),
    WantedState=db_deployment:wanted_state(),
    
    FormatWantedState1=[format_wanted(AppInfo)||AppInfo<-WantedState],
    FormatWantedState=lists:append(FormatWantedState1),
    io:format("FormatWantedState ~p~n",[FormatWantedState]),
    WantedWithHost=[{App,Host}||{App,Host}<-FormatWantedState],
    WantedNoHosts=[App||{App}<-FormatWantedState],
    io:format("WantedWithHost ~p~n",[WantedWithHost]),
    io:format("WantedNoHosts ~p~n",[WantedNoHosts]),
    SdAllApps=sd:all(), %[{Node,[{App,Info,Vsn}]}]
    FormatActualState1=[format_sd(SdAppInfo)||SdAppInfo<-SdAllApps],
    FormatActualState=lists:append(FormatActualState1),
    io:format("FormatActualState ~p~n",[FormatActualState]),
    {[{mydivi,[controller@c0]}],UpdatedActualState}=missing_w_hosts(WantedWithHost,FormatActualState,[]),
    gl=missing_no_hosts(WantedNoHosts,UpdatedActualState,[]),
    
    ok.


with_hosts([],FormatActualState,MissingAcc)->
    {MissingAcc,FormatActualState};
with_hosts([{App,Host}|T],FormatActualState,MissingAcc)->
    case lists:member({App,Host},FormatActualState) of
	true->
	    NewMissingAcc=MissingAcc,
	    NewActualAcc=lists:delete({App,Host},FormatActualState);
	false ->
	    NewMissingAcc=[{App,Host}|MissingAcc],
	    NewActualAcc=FormatActualState
    end,
    with_hosts(T,NewActualAcc,NewMissingAcc).

format_sd({Node,AppInfoList})->
    [{App,[Node]}||{App,_,_}<-AppInfoList].

format_wanted({App,Replicas,[]})->
    format_wanted(Replicas,App,[]);
format_wanted({App,Replicas,Hosts})->
    Diff=Replicas-lists:flatlength(Hosts),
    Result=if
	       Diff==0-> % onetoone
		   [{App,[Host]}||Host<-Hosts];
	       Diff>0-> % more replicas then Hosts
		   L1=[{App,[Host]}||Host<-Hosts],
		   L2=format_wanted({App,Diff,[]}),
		   lists:append([L1,L2]);
	       Diff<0 ->
		   {error,[to_few_replicas,Diff]}
	   end,
    Result.

format_wanted(0,_App,Result)->
    Result;
format_wanted(N,App,Acc)->
    format_wanted(N-1,App,[{App}|Acc]).

    
check_1({App,Replicas,[]})->
    NumDeployed=lists:flatlength(sd:get(App)),
    {App,get_diff(Replicas,NumDeployed)};
check_1({App,Replicas,Hosts})->
    DeployedNodes=sd:get(App),
    NumDeployed=lists:flatlength(DeployedNodes),
   
    % Cehck if all hosts are deployed
    NotDeployedHost=[Host||Host<-Hosts,
			   false=:=lists:member(Host,DeployedNodes)],
    Result=case NotDeployedHost of
	       []-> % All are deployed
		   Diff=lists:flatlength(DeployedNodes)-lists:flatlength(Replicas),
		   if
		       Diff==0->
			   wanted_state;
		       Diff>0->
			   {missing_replicas,Diff};
		       Diff<0 ->
			   {too_many_replicas,(0-Diff)}
		   end;
	       NotDeployedHost->
		   {missing_hosts,NotDeployedHost}
	   end,
    {App,Result}.


get_diff(Replicas,NumDeployed)->
    Diff=Replicas-NumDeployed,
    State=if
	      Diff==0->
		  {ok,Diff};
	      Diff>0->
		  {missing_replicas,Diff};
	      Diff<0 ->
		  {too_many_replicas,0-Diff}
	  end,
    State. 
    



    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_2()->

    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_3()->

    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_4()->
  
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
pass_5()->
  
    ok.




%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

setup()->

  
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------    

cleanup()->
  
    ok.
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
