create or replace procedure printlnf(format varchar2,
                                     arg1   varchar2 default null,
                                     arg2   varchar2 default null,
                                     arg3   varchar2 default null,
                                     arg4   varchar2 default null,
                                     arg5   varchar2 default null,
                                     arg6   varchar2 default null,
                                     arg7   varchar2 default null,
                                     arg8   varchar2 default null) is

  -- Formatted DBMS-OUT Printing
  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- (c) 1981-2014 Taras Lyuklyanchuk

  null_val constant varchar2(50) := 'NULL';
begin

  println(sprintf(format => format,
                  arg1   => nvl(arg1, null_val),
                  arg2   => nvl(arg2, null_val),
                  arg3   => nvl(arg3, null_val),
                  arg4   => nvl(arg4, null_val),
                  arg5   => nvl(arg5, null_val),
                  arg6   => nvl(arg6, null_val),
                  arg7   => nvl(arg7, null_val),
                  arg8   => nvl(arg8, null_val)));
end;
/

