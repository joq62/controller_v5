%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(config_deployment).   
  
    
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-define(DeploymentConfig,"deployment.config").

-ifdef(debug_flag).
-define(DEBUG,["test_src/deployments"]).
-else.
-define(DEBUG,[]).
-endif.


%% --------------------------------------------------------------------


%% External exports
-export([
%	 load_specs/0,
	 spec_list/0,
	 all_specs/0,
	 spec_names/0,
	 get_spec/1,
	 read_spec/1
	]).



%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
spec_names()->
    SpecList=spec_list(),
    [SpecName||{SpecName,_}<-SpecList].

get_spec(SpecName)->
    SpecList=spec_list(),
    proplists:get_value(SpecName,SpecList).


%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
spec_list()->
    spec_list(?DEBUG).

spec_list([Dir])->
    {ok,AllFiles}=file:list_dir(Dir),
    SpecFiles=[filename:join(Dir,FileName)||FileName<-AllFiles,
					    ".deployment"=:=filename:extension(FileName)],
    create_list(SpecFiles,[]).

create_list([],SpecList)->
    SpecList;
create_list([FileName|T],Acc)->
    {ok,I}=file:consult(FileName),
    create_list(T,lists:append(I,Acc)).
    


%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
all_specs()->
    all_specs(?DEBUG).

all_specs([Dir])->
    {ok,AllFiles}=file:list_dir(Dir),
    DeploymentFiles=[FileName||FileName<-AllFiles,
					    ".deployment"=:=filename:extension(FileName)],
    DeploymentFiles.
   
% {ok,I}=file:consult(?DeploymentConfig),
%    proplists:get_value(host_type,I).
%host_type(Host)->
  %  lists:keyfind(Host,1,host_type()).
%type(XType)->
 %   [{Host,Node}||{Host,Node,Type}<-host_type(),
%	   XType=:=Type].
%host_node(XHost)->
 %     [Node||{Host,Node,Type}<-host_type(),
%	     XHost=:=Host].


%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
read_spec(FileName)->
    {ok,I}=file:consult(FileName),
    DeploymentInfo=proplists:get_value(deployment_spec,I),
    DeploymentInfo.


%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function:start
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------

