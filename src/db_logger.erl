-module(db_logger).
-import(lists, [foreach/2]).
-compile(export_all).

-include_lib("stdlib/include/qlc.hrl").


-define(TABLE, sys_log).
-define(RECORD,sys_log).
-record(sys_log,{
		node,      %
		log_id,
		date_time, % {date(),time()}
		severity, %alarm, warning,log 
		header,   % eexists, 
		msg,      % detailed description , Reason 
		mfa       %{?MODULE,?FUNCTIO_NAME,?LINE}
		
	       }).

% support



% End Special 
create_table()->
    {atomic,ok}=mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
				 {type,bag}]),
    mnesia:wait_for_tables([?TABLE], 20000).

create_table(NodeList)->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
				 {disc_copies,NodeList}]),
    mnesia:wait_for_tables([?TABLE], 20000).


delete_table_copy(Dest)->
    mnesia:del_table_copy(?TABLE,Dest).
add_table(Node,StorageType)->
    mnesia:add_table_copy(?TABLE, Node, StorageType).

add_node(Node,StorageType)->
    Result=case mnesia:change_config(extra_db_nodes, [Node]) of
	       {ok,[Node]}->
		   mnesia:add_table_copy(schema, node(),StorageType),
		   mnesia:add_table_copy(?TABLE, node(), StorageType),
		   Tables=mnesia:system_info(tables),
		   mnesia:wait_for_tables(Tables,20*1000);
	       Reason ->
		   Reason
	   end,
    Result.

%%-------------------------------------------------------------------
create(Severity,Header,Msg,MFA)->
    create(node(),{date(),time()},Severity,Header,Msg,MFA).

create(Node,DateTime,Severity,Header,Msg,MFA)->
    LogId=erlang:system_time(nanosecond),
    Record=#?RECORD{
		    node=Node,      %
		    log_id=LogId,
		    date_time=DateTime, % {date(),time()}
		    severity=Severity, %alarm, warning,log 
		    header=Header,   % eexists, 
		    msg=Msg,      % detailed description , Reason 
		    mfa=MFA       %{?MODULE,?FUNCTIO_NAME,?LINE}
		   },
    F = fun() -> mnesia:write(Record) end,
    mnesia:transaction(F).

delete(Object)->
    F = fun() -> 
		RecordList=do(qlc:q([X || X <- mnesia:table(?TABLE),
					  X#?RECORD.log_id==Object])),
		case RecordList of
		    []->
			mnesia:abort({error,[eexists,Object,?FUNCTION_NAME,?MODULE,?LINE]});
		    _->
			[mnesia:delete_object(S1)||S1<-RecordList]			
		end
		    
	end,
    mnesia:transaction(F).

%----------------

read_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    [{Node,LogId,DateTime,Sverity,Header,Msg,MFA}||{?RECORD,Node,LogId,DateTime,Sverity,Header,Msg,MFA}<-Z].


%---------------
node(Node)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.node==Node])),
    [{XNode,LogId,DateTime,Sverity,Header,Msg,MFA}||{?RECORD,XNode,LogId,DateTime,Sverity,Header,Msg,MFA}<-Z].
    
node(Node,Severity)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
		     X#?RECORD.node==Node,
		     X#?RECORD.severity==Severity])),
    [{XNode,LogId,DateTime,Sverity,Header,Msg,MFA}||{?RECORD,XNode,LogId,DateTime,Sverity,Header,Msg,MFA}<-Z].
    


%read(Object)->
%    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),
%		     X#?RECORD.name==Object])),
%    [{Name,HostId,Node,Dir,App}||{?RECORD,Name,HostId,Node,Dir,App}<-Z].


do(Q) ->
  F = fun() -> qlc:e(Q) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.

%%-------------------------------------------------------------------------
