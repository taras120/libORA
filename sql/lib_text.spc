create or replace package lib_text is

  -- Text Functions
  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- (c) 1981-2014 Taras Lyuklyanchuk

  type t_array is table of varchar2(32767);
  type t_cube is table of t_array;

  -- fill string with a character
  function fill(p_len  integer,
                p_text varchar2) return varchar;

  function space(p_len integer) return varchar;

  function crop(p_text   varchar2,
                p_length integer) return varchar2;

  function cropb(p_text  varchar2,
                 p_bytes integer) return varchar2;

  function rcrop(p_text   varchar2,
                 p_length integer) return varchar2;

  function split(p_text  varchar2,
                 p_delim varchar2) return t_array;

  function join(p_arr   t_array,
                p_delim varchar2 default null) return varchar2;

  function join2(p_arr   t_array,
                 p_begin integer default null,
                 p_end   integer default null,
                 p_delim varchar2 default null) return varchar2;

  function wrap(p_text  varchar2,
                p_index integer,
                p_delim varchar2) return varchar2;

  function decode(p_arg1 varchar2,
                  p_arg2 varchar2,
                  p_ret1 varchar2,
                  p_ret2 varchar2 default null) return varchar2;

  -- string formatting
  function format(p_format varchar2,
                  p_arg1   varchar2 default null,
                  p_arg2   varchar2 default null,
                  p_arg3   varchar2 default null,
                  p_arg4   varchar2 default null,
                  p_arg5   varchar2 default null,
                  p_arg6   varchar2 default null,
                  p_arg7   varchar2 default null,
                  p_arg8   varchar2 default null) return varchar2;

  -- print to dbms_out
  procedure print(p_text varchar2);

  -- print line to dbms_out
  procedure println(p_text varchar2 default null);

  -- format+print to dbms_out
  procedure printf(p_format varchar2,
                   p_arg1   varchar2 default null,
                   p_arg2   varchar2 default null,
                   p_arg3   varchar2 default null,
                   p_arg4   varchar2 default null,
                   p_arg5   varchar2 default null,
                   p_arg6   varchar2 default null,
                   p_arg7   varchar2 default null,
                   p_arg8   varchar2 default null);

  -- format+print line to dbms_out
  procedure printlnf(p_format varchar2,
                     p_arg1   varchar2 default null,
                     p_arg2   varchar2 default null,
                     p_arg3   varchar2 default null,
                     p_arg4   varchar2 default null,
                     p_arg5   varchar2 default null,
                     p_arg6   varchar2 default null,
                     p_arg7   varchar2 default null,
                     p_arg8   varchar2 default null);

  function camel(p_text varchar2) return varchar2;

  function lower_camel(p_text varchar2) return varchar2;

  function upper_camel(p_text varchar2) return varchar2;

  function uncamel(p_text varchar2) return varchar2;

  function is_lower(p_text varchar2) return boolean;

  function is_upper(p_text varchar2) return boolean;

  function is_equal(p_text1       varchar2,
                    p_text2       varchar2,
                    b_case_ignore boolean default false) return boolean;

  function is_similar(p_text1 varchar2,
                      p_text2 varchar2) return boolean;

  function index_of(p_text    varchar2,
                    p_pattern varchar2,
                    p_offset  integer) return integer;

  -- substring(text,from,to)
  function substring(p_text  varchar2,
                     p_begin integer,
                     p_end   integer) return varchar2;

  -- substring+trim
  function subtrim(p_text  varchar2,
                   p_begin integer,
                   p_end   integer) return varchar2;

  function b64_encode(p_text in varchar2) return varchar2;

  function b64_decode(p_text in varchar2) return varchar2;

  function repeat(p_text  varchar2,
                  p_times integer) return varchar2;

  function repeat(p_text  varchar2,
                  p_delim varchar2,
                  p_times integer) return varchar2;

  function is_alpha(p_text varchar2) return boolean;

  function is_number(p_text varchar2) return boolean;

  function is_alphanum(p_text varchar2) return boolean;

  function only_alphas(p_text varchar2) return varchar2;

  function only_numbers(p_text varchar2) return varchar2;

  function only_alphanum(p_text varchar2) return varchar2;

  function split_array(p_arr   t_array,
                       p_delim varchar2) return t_cube;

  function singularity(p_arr   t_array,
                       p_delim varchar2) return integer;

end;
/

