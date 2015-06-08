create or replace function enum(arg# integer,
                                arg1 varchar2,
                                arg2 varchar2,
                                arg3 varchar2 default null,
                                arg4 varchar2 default null,
                                arg5 varchar2 default null,
                                arg6 varchar2 default null,
                                arg7 varchar2 default null,
                                arg8 varchar2 default null)
/*
  $Id$
  */

 return varchar2 is

  result varchar2(32767);
begin

  result := case arg#
              when 1 then
               arg1
              when 2 then
               arg2
              when 3 then
               arg3
              when 4 then
               arg4
              when 5 then
               arg5
              when 6 then
               arg6
              when 7 then
               arg7
              when 8 then
               arg8
              else
               null
            end;

  return result;
end;
/

