create or replace function sqltrace
  return varchar2 is
  
  trace varchar2(32767);
begin

  -- Returns SQL trace

  trace := sys.dbms_utility.format_error_backtrace;

  if trace is null then
    trace := sys.dbms_utility.format_call_stack;  
  end if;

  return trace;
end;
/

