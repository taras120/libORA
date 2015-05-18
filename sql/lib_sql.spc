create or replace package lib_sql is

  -- LibORA PL/SQL Library
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.07.2013 11:37:59  
  -- Purpose : SQL Reflection Library

  -- oracle builtin types
  ORA_VARCHAR2                constant integer := 1;
  ORA_NUMBER                  constant integer := 2;
  ORA_LONG                    constant integer := 8;
  ORA_ROWID                   constant integer := 11;
  ORA_DATE                    constant integer := 12;
  ORA_RAW                     constant integer := 23;
  ORA_LONG_RAW                constant integer := 24;
  ORA_CHAR                    constant integer := 96;
  ORA_BINARY_FLOAT            constant integer := 100;
  ORA_BINARY_DOUBLE           constant integer := 101;
  ORA_MLSLABEL                constant integer := 106;
  ORA_USER_DEFINED            constant integer := 109;
  ORA_REF                     constant integer := 111;
  ORA_CLOB                    constant integer := 112;
  ORA_BLOB                    constant integer := 113;
  ORA_BFILE                   constant integer := 114;
  ORA_TIMESTAMP               constant integer := 180;
  ORA_TIMESTAMP_WITH_TZ       constant integer := 181;
  ORA_INTERVAL_YEAR_TO_MONTH  constant integer := 182;
  ORA_INTERVAL_DAY_TO_SECOND  constant integer := 183;
  ORA_UROWID                  constant integer := 208;
  ORA_TIMESTAMP_WITH_LOCAL_TZ constant integer := 231;

  -- user defined types
  USER_INTEGER constant integer := 20001;
  USER_XMLTYPE constant integer := 20002;
  USER_BOOLEAN constant integer := 20003;

  type t_cursor is ref cursor;

  type t_column is record(
    name     varchar2(1000),
    typeId   integer,
    typeName varchar2(32),
    maxlen   integer,
    scale    integer,
    isNull   boolean,
    position integer);

  type t_describe is table of t_column;

  type t_value is record(
    text     varchar2(32767),
    typeId   integer,
    typeName varchar2(32),
    lob      clob,
    isLob    boolean := false);

  function get_cursor(p_cursor# integer) return t_cursor;

  function get_cursor#(p_cursor t_cursor) return integer;

  function get_type_id(p_name integer) return varchar2;

  function get_type_name(p_type integer) return varchar2;

  function get_string(p_cursor# integer,
                      p_column  t_column) return varchar2;

  function get_number(p_cursor# integer,
                      p_column  t_column) return number;

  function get_integer(p_cursor# integer,
                       p_column  t_column) return integer;

  function get_boolean(p_cursor# integer,
                       p_column  t_column) return boolean;

  function get_date(p_cursor# integer,
                    p_column  t_column) return date;

  function get_char(p_cursor# integer,
                    p_column  t_column) return char;

  function get_blob(p_cursor# integer,
                    p_column  t_column) return blob;

  function get_clob(p_cursor# integer,
                    p_column  t_column) return clob;

  function get_rowid(p_cursor# integer,
                     p_column  t_column) return rowid;

  function get_xmltype(p_cursor# integer,
                       p_column  t_column) return xmltype;

  function get_value(p_cursor# integer,
                     p_column  t_column) return t_value;

  procedure close_cursor(p_cursor# integer);

  procedure close_cursor(p_cursor t_cursor);

  function serialize(p_cursor# integer,
                     p_name    varchar2 default null) return xmltype;

  function serialize(p_cursor in out t_cursor,
                     p_name   varchar2 default null) return xmltype;

  function execute_query(p_query varchar2) return integer;

  function execute_to_xml(p_query varchar2,
                          p_name  varchar2 default null) return xmltype;

  function parse_as_keyval(p_cursor t_cursor) return types.hash_map;

  function parse_as_keyval(p_cursor t_cursor,
                           p_name   varchar2) return xmltype;

  function parse_to_map_list(p_cursor t_cursor,
                             p_rows#  integer default null) return types.map_list;

  function parse_to_map_list(p_cursor t_cursor,
                             p_name   varchar2,
                             p_rows#  integer default null) return xmltype;

end;
/

