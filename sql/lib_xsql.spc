create or replace package lib_xsql is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.07.2013 11:37:59
  -- Purpose : XML SQL Reflection Library

  type t_cursor is ref cursor;

  function serialize#(p_cursor# integer,
                      p_name    varchar2 default null,
                      b_close   boolean default true) return xmltype;

  function serialize(p_cursor in out t_cursor,
                     p_name   varchar2 default null,
                     b_close  boolean default true) return xmltype;

  function fetch_as_keyval(p_cursor t_cursor,
                           p_name   varchar2 default null,
                           b_close  boolean default true) return xmltype;

  function fetch_as_rowset(p_cursor t_cursor,
                           p_name   varchar2,
                           p_rows#  integer default null,
                           b_close  boolean default true) return xmltype;

  function describe_xml(p_doc xmltype) return lib_sql.t_describe;

  -- SQL-совместимое содержимое ноды
  function get_value(p_node  dbms_xmldom.DOMNode,
                     p_type# integer) return varchar2;

  function camelize(p_doc xmltype) return xmltype;

  function decamelize(p_doc xmltype) return xmltype;

  -- вставить записи в таблицу
  function insert_xml(p_doc   xmltype,
                      p_table varchar2) return integer;

  -- обновить записи в таблице
  function update_xml(p_doc   xmltype,
                      p_table varchar2,
                      p_key   varchar2 default null) return integer;

  -- удалить записи из таблицы
  function delete_xml(p_doc   xmltype,
                      p_table varchar2,
                      p_key   varchar2 default null) return integer;

  function execute_query(p_stmt varchar2,
                         p_name varchar2 default null) return xmltype;

  function execute_query(p_stmt  varchar2,
                         p_xargs xmltype) return xmltype;

  function execute_query$(p_stmt  varchar2,
                          p_xargs clob) return clob;

  function call_procedure(p_name  varchar2,
                          p_xargs xmltype default null) return xmltype;

  function call_procedure$(p_name  varchar2,
                           p_xargs clob default null) return clob;

  function call_function(p_name  varchar2,
                         p_xargs xmltype default null) return xmltype;

  function call_function$(p_name  varchar2,
                          p_xargs clob default null) return clob;

end;
/

