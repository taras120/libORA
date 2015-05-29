create or replace package lib_rep is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 15.05.2015 0:11:57
  -- Purpose : Simple Marker Report Engine

  OPEN_TAG  constant varchar2(16) := '#{';
  CLOSE_TAG constant varchar2(16) := '}';

  function get_tags(p_templ clob) return t_list;

  function get_data_map(p_tags t_list,
                        p_data xmltype) return types.hash_map;

  function create_report(p_templ varchar2,
                         p_data  xmltype) return varchar2;

  function create_report(p_templ clob,
                         p_data  xmltype) return clob;

end;
/

