%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(dbase).  
   
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

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
dynamic_db_init([])->
    mnesia:stop(),
    mnesia:del_table_copy(schema,node()),
    mnesia:delete_schema([node()]),
    mnesia:start(),
    %% First to start
    ok=db_lock:create_table(),
    {atomic,ok}=db_lock:create(lock1,0,node()),    
    ok;

dynamic_db_init([DbaseNode|T])->
    mnesia:stop(),
    mnesia:del_table_copy(schema,node()),
    mnesia:delete_schema([node()]),
    mnesia:start(),
    Added=node(),
    StorageType=ram_copies,
    case mnesia:change_config(extra_db_nodes, [Added]) of
	{ok,[Added]}->
	    mnesia:add_table_copy(schema, node(),StorageType),
	    % Application db_xx
	    db_lock:add_table(Added,StorageType),
	    Tables=mnesia:system_info(tables),
	    mnesia:wait_for_tables(Tables,20*1000);
	Reason ->
	    io:format("Error~p~n",[{error,Reason,DbaseNode,node(),?FUNCTION_NAME,?MODULE,?LINE}]),
	    dynamic_db_init(T) 
    end.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
