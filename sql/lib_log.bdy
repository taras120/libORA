create or replace package body lib_log is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 15.05.2015 0:11:57
  -- Purpose : Logger Library

  -- constants
  FMT_DATE constant varchar2(32) := 'yyyy-mm-dd';
  FMT_TIME constant varchar2(32) := 'hh24:mi:ss';

  -- global variables
  g_level  integer;
  g_format integer := FMT_BRIEF;

  type t_list is table of varchar2(1000);

  LEVEL_NAMES constant t_list := t_list('FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE');

  procedure init is
    line   varchar2(1000);
    status integer;
  begin

    println();
    dbms_output.get_line(line => line, status => status);

    if status = 0 then
      g_level := L_DEBUG;
    else
      g_level := L_INFO;
    end if;

    -- initialization complete
    info('%s Logger initialized (%s)',
         to_char(sysdate, sprintf('%s %s', FMT_DATE, FMT_TIME)),
         this_lname());
  end;

  function is_level(p_level integer) return boolean is
  begin
    return p_level <= g_level;
  end;

  function is_debug return boolean is
  begin
    return g_level >= L_DEBUG;
  end;

  function is_trace return boolean is
  begin
    return g_level >= L_TRACE;
  end;

  function get_level return integer is
  begin
    return g_level;
  end;

  procedure set_level(p_level integer) is
  begin

    if p_level != g_level then

      g_level := p_level;

      log(g_level, 'Log level changed to "%s"', this_lname());
    end if;
  end;

  function get_lname(p_level integer) return varchar2 is
  begin
    return LEVEL_NAMES(p_level);
  end;

  function this_lname return varchar2 is
  begin
    return LEVEL_NAMES(g_level);
  end;

  function get_format return integer is
  begin
    return g_format;
  end;

  procedure set_format(p_format integer) is
  begin
    if p_format != g_format then
      g_format := p_format;
    end if;
  end;

  procedure print(p_level integer,
                  p_text  varchar2) is
  begin

    if g_format = FMT_NONE then

      println(p_text);

    elsif g_format = FMT_BRIEF then

      printlnf('%s: %s', get_lname(p_level), p_text);

    elsif g_format = FMT_FULL then

      printlnf('%s %s %s',
               rpad(get_lname(p_level), 5, const.SPC),
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
    if is_level(p_level) then
      print(p_level,
            sprintf(p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8));
    end if;
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
    log(L_FATAL, p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
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
    log(L_ERROR, p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
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
    log(L_WARN, p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
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
    log(L_INFO, p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
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
    log(L_DEBUG, p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
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
    log(L_TRACE, p_text, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
  end;

begin
  init();
end;
/

