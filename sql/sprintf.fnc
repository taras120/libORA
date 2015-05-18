create or replace function sprintf(text varchar2,
                                   arg1 varchar2 default null,
                                   arg2 varchar2 default null,
                                   arg3 varchar2 default null,
                                   arg4 varchar2 default null,
                                   arg5 varchar2 default null,
                                   arg6 varchar2 default null,
                                   arg7 varchar2 default null,
                                   arg8 varchar2 default null) return varchar2 is

  -- String formatting
  -- LibORA PL/SQL Library
  -- (c) 1981-2014 Taras Lyuklyanchuk 

begin

  return utl_lms.format_message(text,
                                nvl(arg1, 'NULL'),
                                nvl(arg2, 'NULL'),
                                nvl(arg3, 'NULL'),
                                nvl(arg4, 'NULL'),
                                nvl(arg5, 'NULL'),
                                nvl(arg6, 'NULL'),
                                nvl(arg7, 'NULL'),
                                nvl(arg8, 'NULL'));
end;
/

