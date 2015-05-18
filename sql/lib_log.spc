create or replace package lib_log is

  -- LibORA PL/SQL Library
  -- Author  : Taras Lyuklyanchuk
  -- Created : 15.05.2015 0:11:57
  -- Purpose : Logger Library

  -- levels
  LEV_FATAL constant integer := 1; -- the most serious
  LEV_ERROR constant integer := 2;
  LEV_WARN  constant integer := 3;
  LEV_INFO  constant integer := 4;
  LEV_DEBUG constant integer := 5;
  LEV_TRACE constant integer := 6; -- the least serious

  -- formats
  FMT_NONE  constant integer := 0;
  FMT_BRIEF constant integer := 1;
  FMT_FULL  constant integer := 2;

  function is_level(p_level integer) return boolean;

  function get_level return integer;

  procedure set_level(p_level integer);

  function get_format return integer;

  procedure set_format(p_format integer);

  procedure log(p_level integer,
                p_text  varchar2,
                p_arg1  varchar2 default null,
                p_arg2  varchar2 default null,
                p_arg3  varchar2 default null,
                p_arg4  varchar2 default null,
                p_arg5  varchar2 default null,
                p_arg6  varchar2 default null,
                p_arg7  varchar2 default null,
                p_arg8  varchar2 default null);

  procedure fatal(p_text varchar2,
                  p_arg1 varchar2 default null,
                  p_arg2 varchar2 default null,
                  p_arg3 varchar2 default null,
                  p_arg4 varchar2 default null,
                  p_arg5 varchar2 default null,
                  p_arg6 varchar2 default null,
                  p_arg7 varchar2 default null,
                  p_arg8 varchar2 default null);

  procedure error(p_text varchar2,
                  p_arg1 varchar2 default null,
                  p_arg2 varchar2 default null,
                  p_arg3 varchar2 default null,
                  p_arg4 varchar2 default null,
                  p_arg5 varchar2 default null,
                  p_arg6 varchar2 default null,
                  p_arg7 varchar2 default null,
                  p_arg8 varchar2 default null);

  procedure warn(p_text varchar2,
                 p_arg1 varchar2 default null,
                 p_arg2 varchar2 default null,
                 p_arg3 varchar2 default null,
                 p_arg4 varchar2 default null,
                 p_arg5 varchar2 default null,
                 p_arg6 varchar2 default null,
                 p_arg7 varchar2 default null,
                 p_arg8 varchar2 default null);

  procedure info(p_text varchar2,
                 p_arg1 varchar2 default null,
                 p_arg2 varchar2 default null,
                 p_arg3 varchar2 default null,
                 p_arg4 varchar2 default null,
                 p_arg5 varchar2 default null,
                 p_arg6 varchar2 default null,
                 p_arg7 varchar2 default null,
                 p_arg8 varchar2 default null);

  procedure debug(p_text varchar2,
                  p_arg1 varchar2 default null,
                  p_arg2 varchar2 default null,
                  p_arg3 varchar2 default null,
                  p_arg4 varchar2 default null,
                  p_arg5 varchar2 default null,
                  p_arg6 varchar2 default null,
                  p_arg7 varchar2 default null,
                  p_arg8 varchar2 default null);

  procedure trace(p_text varchar2,
                  p_arg1 varchar2 default null,
                  p_arg2 varchar2 default null,
                  p_arg3 varchar2 default null,
                  p_arg4 varchar2 default null,
                  p_arg5 varchar2 default null,
                  p_arg6 varchar2 default null,
                  p_arg7 varchar2 default null,
                  p_arg8 varchar2 default null);

end;
/

