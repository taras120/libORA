create or replace procedure throw(text varchar2,
                                  arg1 varchar2 default null,
                                  arg2 varchar2 default null,
                                  arg3 varchar2 default null,
                                  arg4 varchar2 default null,
                                  arg5 varchar2 default null,
                                  arg6 varchar2 default null,
                                  arg7 varchar2 default null,
                                  arg8 varchar2 default null) is

  -- Raise an exception with formating
  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- (c) 1981-2014 Taras Lyuklyanchuk

begin

  raise_application_error(-20000,
                          sprintf(text => text,
                                  arg1 => arg1,
                                  arg2 => arg2,
                                  arg3 => arg3,
                                  arg4 => arg4,
                                  arg5 => arg5,
                                  arg6 => arg6,
                                  arg7 => arg7,
                                  arg8 => arg8));
end;
/

