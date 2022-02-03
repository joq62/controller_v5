%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description :  1
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(prototype_test).   
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("log.hrl").
-include("controller.hrl").
-include("configs.hrl").
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
  %  io:format("~p~n",[{"Start setup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=setup(),
    io:format("~p~n",[{"Stop setup",?MODULE,?FUNCTION_NAME,?LINE}]),

%    io:format("~p~n",[{"Start boot()",?MODULE,?FUNCTION_NAME,?LINE}]),
%    ok= boot(),
%    io:format("~p~n",[{"Stop  boot()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start start_script()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=start_script(),
    io:format("~p~n",[{"Stop  start_script()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start controller_init()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=controller_init(),
    io:format("~p~n",[{"Stop  controller_init()",?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("~p~n",[{"Start deploy1()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=deploy1(),
    io:format("~p~n",[{"Stop  deploy1()",?MODULE,?FUNCTION_NAME,?LINE}]),

   io:format("~p~n",[{"Start deploy2()",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=deploy2(),
    io:format("~p~n",[{"Stop  deploy2()",?MODULE,?FUNCTION_NAME,?LINE}]),

      %% End application tests
  %  io:format("~p~n",[{"Start cleanup",?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=cleanup(),
  %  io:format("~p~n",[{"Stop cleaup",?MODULE,?FUNCTION_NAME,?LINE}]),
   
    io:format("------>"++atom_to_list(?MODULE)++" ENDED SUCCESSFUL ---------"),
    ok.
 %  io:format("application:which ~p~n",[{application:which_applications(),?FUNCTION_NAME,?MODULE,?LINE}]),


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
deploy1()->  
    [{{"add","1.0.0"},{3,[]}},
     {{"divi_1","1.0.0"},{2,[]}},
     {{"math","1.0.0"},{1,[]}}]=lists:sort(controller:actual_state()),
    
    %Deploy  first add 

    



    [LoaderVm]=sd:get(loader),
    {ok,AddVm1}=controller_start_service_("add","1.0.0",LoaderVm),
    42=rpc:call(AddVm1,myadd,add,[20,22],1000),

    [{{"add","1.0.0"},{2,[AddVm1]}},
     {{"divi_1","1.0.0"},{2,[]}},
     {{"math","1.0.0"},{1,[]}}]=lists:sort(controller:actual_state()),

    {ok,Add2}=controller_start_service_("add","1.0.0",LoaderVm),
    {ok,Math}=controller_start_service_("math","1.0.0",LoaderVm),
    
    222=rpc:call(Add2,myadd,add,[200,22],1000),
    20.0=rpc:call(Math,mydivi,divi,[200,10],1000),
    
    
    [{{"add","1.0.0"},{1,[AddVm1,Add2]}},
     {{"divi_1","1.0.0"},{2,[]}},
     {{"math","1.0.0"},{0,[Math]}}]=lists:sort(controller:actual_state()),

    {ok,Math2}=controller_start_service_("math","1.0.0",LoaderVm),
    {ok,Math3}=controller_start_service_("math","1.0.0",LoaderVm),

    [{{"add","1.0.0"},{1,[AddVm1,Add2]}},
     {{"divi_1","1.0.0"},{2,[]}},
     {{"math","1.0.0"},{-2,[Math,Math2,Math3]}}]=lists:sort(controller:actual_state()),
    
    [rpc:call(N,init,stop,[],2000)||N<-[AddVm1,Add2,Math,Math2,Math3]],
    timer:sleep(3000),
    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
deploy2()->  
    CurrentState1=lists:sort(controller:actual_state()),
    [{{"add","1.0.0"},{3,[]}},
     {{"divi_1","1.0.0"},{2,[]}},
     {{"math","1.0.0"},{1,[]}}]=CurrentState1,

   % gl=[X||X<-lists:sort(controller:actual_state())],
       
    [LoaderVm]=sd:get(loader),
 
    desired_state(CurrentState1,LoaderVm),
   
    CurrentState2=lists:sort(controller:actual_state()),

   [{{"add","1.0.0"},
     {0,
      [Add1,Add2,Add3]}},
    {{"divi_1","1.0.0"},
     {0,
      [Divi1,Divi2]}},
    {{"math","1.0.0"},
     {0,[Math1]}}]=CurrentState2,

    desired_state(CurrentState1,LoaderVm),

    CurrentState2=lists:sort(controller:actual_state()),
    
    
    

    ok.


desired_state(CurrentState,LoaderVm)->
    [X|Z]=CurrentState,
    io:format("X, ~p~n",[{X,?MODULE,?FUNCTION_NAME,?LINE}]),
    io:format("Z, ~p~n",[{Z,?MODULE,?FUNCTION_NAME,?LINE}]),
    desired_state(CurrentState,LoaderVm,[]).
    
desired_state([],_LoaderVm,StartRes)->
    StartRes;
            %   {{"add"      ,"1.0.0"   },{3,    []      }}
desired_state([ServiceState|T],LoaderVm,Acc)->
    io:format("ServiceState, ~p~n",[{ServiceState,?MODULE,?FUNCTION_NAME,?LINE}]),
    {{ServiceName,ServiceVsn},{Num,ServiceVms}}=ServiceState,
    Res=desired_state({ServiceName,ServiceVsn},{Num,ServiceVms},LoaderVm,[]),
    desired_state(T,LoaderVm,[{{ServiceName,ServiceVsn},Res}|Acc]).

desired_state({_ServiceName,_ServiceVsn},{0,_ServiceVms},_LoaderVm,Result)->
    Result;
desired_state({ServiceName,ServiceVsn},{Num,ServiceVms},LoaderVm,Acc) ->
    Res=controller_start_service_(ServiceName,ServiceVsn,LoaderVm),
    desired_state({ServiceName,ServiceVsn},{Num-1,ServiceVms},LoaderVm,[Res|Acc]).

controller_start_service_(ServiceName,ServiceVsn,LoaderVm)->
    ServiceSpec=controller:get_spec(ServiceName,ServiceVsn),
    Name=proplists:get_value(name,ServiceSpec),
    Vsn=proplists:get_value(vsn,ServiceSpec),
    Template=proplists:get_value(template,ServiceSpec),

    {ok,ServiceVm}=rpc:call(LoaderVm,loader,create,[],10000), 
    ok=rpc:call(LoaderVm,loader,load_appl,[service,ServiceVm],10000),   
    true=rpc:call(ServiceVm,code,add_patha,["ebin"],5000),
    ok=rpc:call(ServiceVm,application,set_env,[[{service,[{id,{Name,Vsn}},{template,Template},{loader_vm,LoaderVm}]}]],15*1000),
    ok=rpc:call(ServiceVm,application,start,[service],20*1000), 
    {ok,ServiceVm}.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
start_script()->
    % suppor debugging
    ok=application:start(sd),

    % Simulate host
    ok=test_nodes:start_nodes(),
    [Vm1|_]=test_nodes:get_nodes(),
    
    %simulate start script
    % rm -rf loader
    % git clone https://github.com/joq62/loader.git loader
    % erl -pa loader/ebin -sname loader -setcookie cookie_test -s boot_loader start worker -detached 
    
    LoaderDir="loader",
    LoaderGitPath="https://github.com/joq62/loader.git",
    Ebin="loader/ebin",
    
    os:cmd("rm -rf "++LoaderDir),
    os:cmd("git clone "++LoaderGitPath++" "++LoaderDir), 
    true=rpc:call(Vm1,code,add_path,[Ebin],5000),
    ok=rpc:call(Vm1,boot_loader,start,[[worker]],35000),
    
    pong=rpc:call(Vm1,loader,ping,[],2000),
    ok.
    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
controller_init()->
    ok=application:start(host),
    ok=application:start(controller),
    
    
    [{{"add","1.0.0"},{3,[]}},
     {{"divi_1","1.0.0"},{2,[]}},
     {{"math","1.0.0"},{1,[]}}]=lists:sort(controller:actual_state()),
    
    
    
   
    ok.

init(Name,Vsn,Template,LoaderVm)->
    {ok,ServiceVm}=rpc:call(LoaderVm,loader,create,[],10000),
    %Fix
    true=rpc:call(ServiceVm,code,add_patha,["ebin"],5000),
    ok=rpc:call(ServiceVm,application,set_env,[[{service,[{id,{Name,Vsn}},{template,Template},{loader_vm,LoaderVm}]}]],5000),
    ok=rpc:call(ServiceVm,application,start,[service],5000),
    {ok,{{Name,Vsn},ServiceVm}}.
  
    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
dist_1()->
    [H1,H2,H3]=test_nodes:get_nodes(),
    io:format("sd:all ~p~n",[{rpc:call(H1,sd,all,[],2000),?FUNCTION_NAME,?MODULE,?LINE}]),

    ok.
    


    
%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------



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
