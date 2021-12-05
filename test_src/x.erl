%% Author: joqerlang
%% Created: 2021-11-18 
%% Connect/keep connections to other nodes
%% clean up of computer (removes all applications but keeps log file
%% git loads or remove an application ,loadand start application
%%  
%% Starts either as controller or worker node, given in application env 
%% Controller:
%%   git clone and starts 
%% 
%% Description: TODO: Add description to application_org
%% 
-module(x).
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("kernel/include/logger.hrl").
%% --------------------------------------------------------------------
%% Behavioural exports
%% --------------------------------------------------------------------
-export([
	 start/0,
         kill/1,
	 re/0,
	 sd/0,
	 host/0
        ]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------

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
%,[{myamath,"1.0.0",1,["C200"]}],
%%---------------------------------------------------------------------
start()->
    ok.
kill(glurk)->
    ok.

re()->
    I=access(),
    HostName=proplists:get_value(hostname,I),
    Ip=proplists:get_value(ip,I),
    Port=proplists:get_value(port,I),
    Uid=proplists:get_value(uid,I),
    Pwd=proplists:get_value(pwd,I),
    Node=proplists:get_value(node,I),
    Cookie="cookie",
    
    rpc:call(Node,init,stop,[],1000),
    timer:sleep(2000),
    io:format("~p~n",[{HostName,Ip,Port,Uid,Pwd,Node}]),
    ssh:start(),
    Msg="hostname",
    MsgR=rpc:call(node(),my_ssh,ssh_send,[Ip,Port,Uid,Pwd,Msg, 5*1000],4*1000), 
    io:format("MsgR ~p~n",[MsgR]),
   
    NodeName="host",
    Erl="/snap/erlang/current/usr/bin/erl",
    %Erl="erl ",
   % ErlCmd="erl_call -s "++"-sname "++NodeName++" "++"-c "++Cookie++" ,
    ErlCmd=Erl++" "++"-sname "++NodeName++" "++"-setcookie "++Cookie++" -detached",
    SshCmd="nohup "++ErlCmd++" &",
 %   SshResult=rpc:call(node(),my_ssh,ssh_send,[Ip,Port,Uid,Pwd,SshCmd, 6*1000],5*1000),
    SshResult=rpc:call(node(),my_ssh,ssh_send,[Ip,Port,Uid,Pwd,ErlCmd, 5*1000],4*1000),
    
    io:format("SshResult ~p~n",[SshResult]),

    io:format("ping ~p~n",[net_adm:ping(Node)]),

    
    ok.

sd()->
    ok.

host()->
    ok.

access()->
    [{hostname,"c203"},
     {ip,"192.168.0.203"},
     {port,22},
     {uid,"pi"},
     {pwd,"festum01"},
     {node,'host@c203'}
    ].
