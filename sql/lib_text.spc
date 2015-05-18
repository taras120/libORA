create or replace package lib_text is

  -- LibORA PL/SQL Library
  -- Text Functions
  -- (c) 1981-2014
  -- Taras Lyuklyanchuk

  type t_array is table of varchar2(32767) index by binary_integer;

  function crop(p_text   varchar2,
                p_length integer) return varchar2;

  function split(p_text  varchar2,
                 p_delim char) return t_array;

  function join(p_arr   t_array,
                p_delim varchar2 default null) return varchar2;

  function wrap(p_text  varchar2,
                p_index integer,
                p_delim char) return varchar2;

  function camel(p_text varchar2) return varchar2;

  function lower_camel(p_text varchar2) return varchar2;

  function is_lower(p_text varchar2) return boolean;

  function is_upper(p_text varchar2) return boolean;

  function uncamel(p_text varchar2) return varchar2;

  function index_of(p_text    clob,
                    p_pattern varchar2,
                    p_offset  integer) return integer;

  function substring(p_text  clob,
                     p_begin integer,
                     p_end   integer) return varchar2;

end;
/

