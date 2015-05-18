create or replace package body lib_log is

  -- LibORA PL/SQL Library
  -- Author  : Taras Lyuklyanchuk
  -- Created : 15.05.2015 0:11:57
  -- Purpose : Logger Library

  -- constants
  FMT_DATE constant varchar2(32) := 'yyyy-mm-dd';
  FMT_TIME constant varchar2(32) := 'hh24:mi:ss';

  -- global variables
  g_level  integer := LEV_INFO;
  g_format integer := FMT_BRIEF;

  type t_list is table of varchar2(1000);

  LEVEL_NAMES constant t_list := t_list('FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE');

  function is_level(p_level integer) return boolean is
  begin
    return p_level <= g_level;
  end;

  function get_level return integer is
  begin
    return g_level;
  end;

  function get_level_name(p_level integer) return varchar2 is
  begin
    return LEVEL_NAMES(p_level);
  end;

  function this_level_name return varchar2 is
  begin
    return LEVEL_NAMES(g_level);
  end;

  procedure set_level(p_level integer) is
  begin
    g_format := p_level;
  end;

  function get_format return integer is
  begin
    return g_format;
  end;

  procedure set_format(p_format integer) is
  begin
    g_format := p_format;
  end;

  procedure print(p_text varchar2,
                  p_arg1 varchar2 default null,
                  p_arg2 varchar2 default null,
                  p_arg3 varchar2 default null,
                  p_arg4 varchar2 default null,
                  p_arg5 varchar2 default null,
                  p_arg6 varchar2 default null,
                  p_arg7 varchar2 default null,
                  p_arg8 varchar2 default null) is
  begin
    printf(p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
  end;

  procedure print(p_level integer,
                  p_text  varchar2) is
  begin
  
    if g_format = FMT_NONE then
    
      print(p_text);
    
    elsif g_format = FMT_BRIEF then
    
      print('%s: %s', get_level_name(p_level), p_text);
    
    elsif g_format = FMT_FULL then
    
      print('%s %s %s',
            rpad(get_level_name(p_level), 5, const.SPC),
            to_char(sysdate, FMT_TIME),
            p_text);
    end if;
  
  end;

  procedure log(p_level integer,
                p_text  varchar2,
                p_arg1  varchar2 default null,
                p_arg2  varchar2 default null,
                p_arg3  varchar2 default null,
                p_arg4  varchar2 default null,
                p_arg5  varchar2 default null,
                p_arg6  varchar2 default null,
                p_arg7  varchar2 default null,
                p_arg8  varchar2 default null) is
  begin
    print(p_level, sprintf(p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8));
  end;

  procedure fatal(p_text varchar2,
                  p_arg1 varchar2 default null,
                  p_arg2 varchar2 default null,
                  p_arg3 varchar2 default null,
                  p_arg4 varchar2 default null,
                  p_arg5 varchar2 default null,
                  p_arg6 varchar2 default null,
                  p_arg7 varchar2 default null,
                  p_arg8 varchar2 default null) is
  begin
    log(LEV_FATAL, p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
  end;

  procedure error(p_text varchar2,
                  p_arg1 varchar2 default null,
                  p_arg2 varchar2 default null,
                  p_arg3 varchar2 default null,
                  p_arg4 varchar2 default null,
                  p_arg5 varchar2 default null,
                  p_arg6 varchar2 default null,
                  p_arg7 varchar2 default null,
                  p_arg8 varchar2 default null) is
  begin
    log(LEV_ERROR, p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
  end;

  procedure warn(p_text varchar2,
                 p_arg1 varchar2 default null,
                 p_arg2 varchar2 default null,
                 p_arg3 varchar2 default null,
                 p_arg4 varchar2 default null,
                 p_arg5 varchar2 default null,
                 p_arg6 varchar2 default null,
                 p_arg7 varchar2 default null,
                 p_arg8 varchar2 default null) is
  begin
    log(LEV_WARN, p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
  end;

  procedure info(p_text varchar2,
                 p_arg1 varchar2 default null,
                 p_arg2 varchar2 default null,
                 p_arg3 varchar2 default null,
                 p_arg4 varchar2 default null,
                 p_arg5 varchar2 default null,
                 p_arg6 varchar2 default null,
                 p_arg7 varchar2 default null,
                 p_arg8 varchar2 default null) is
  begin
    log(LEV_INFO, p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
  end;

  procedure debug(p_text varchar2,
                  p_arg1 varchar2 default null,
                  p_arg2 varchar2 default null,
                  p_arg3 varchar2 default null,
                  p_arg4 varchar2 default null,
                  p_arg5 varchar2 default null,
                  p_arg6 varchar2 default null,
                  p_arg7 varchar2 default null,
                  p_arg8 varchar2 default null) is
  begin
    log(LEV_DEBUG, p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
  end;

  procedure trace(p_text varchar2,
                  p_arg1 varchar2 default null,
                  p_arg2 varchar2 default null,
                  p_arg3 varchar2 default null,
                  p_arg4 varchar2 default null,
                  p_arg5 varchar2 default null,
                  p_arg6 varchar2 default null,
                  p_arg7 varchar2 default null,
                  p_arg8 varchar2 default null) is
  begin
    log(LEV_TRACE, p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
  end;

end;
/

