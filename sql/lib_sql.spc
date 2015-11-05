create or replace package lib_sql is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.07.2013 11:37:59
  -- Purpose : SQL Reflection Library

  /* Oracle Builtin Datatypes */
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

  /* User Defined Datatypes */
  UDT_ANYDATA    constant integer := 10901;
  UDT_ANYDATASET constant integer := 10902;
  UDT_XMLTYPE    constant integer := 10977;
  UDT_URITYPE    constant integer := 10978;

  /* PL/SQL Datatypes */
  PLS_VOID         constant integer := 0;
  PLS_INTEGER      constant integer := 3;
  PLS_OPAQUE       constant integer := 58;
  PLS_OBJECT       constant integer := 121;
  PLS_NESTED_TABLE constant integer := 122;
  PLS_VARRAY       constant integer := 123;
  PLS_TIME         constant integer := 178;
  PLS_TIME_WITH_TZ constant integer := 179;
  PLS_RECORD       constant integer := 250;
  PLS_TABLE        constant integer := 251;
  PLS_BOOLEAN      constant integer := 252;

  /* External Datatypes */
  EXT_VARCHAR2                constant integer := 1;
  EXT_NUMBER                  constant integer := 2;
  EXT_INTEGER                 constant integer := 3;
  EXT_FLOAT                   constant integer := 4;
  EXT_STRING                  constant integer := 5;
  EXT_VARNUM                  constant integer := 6;
  EXT_LONG                    constant integer := 8;
  EXT_VARCHAR                 constant integer := 9;
  EXT_DATE                    constant integer := 12;
  EXT_VARRAW                  constant integer := 15;
  EXT_NATIVE_FLOAT            constant integer := 21;
  EXT_NATIVE_DOUBLE           constant integer := 22;
  EXT_RAW                     constant integer := 23;
  EXT_LONG_RAW                constant integer := 24;
  EXT_UNSIGNED_INT            constant integer := 68;
  EXT_LONG_VARCHAR            constant integer := 94;
  EXT_LONG_VARRAW             constant integer := 95;
  EXT_CHAR                    constant integer := 96;
  EXT_CHARZ                   constant integer := 97;
  EXT_ROWID                   constant integer := 104;
  EXT_NAMED_DATATYPE          constant integer := 108;
  EXT_REF                     constant integer := 110;
  EXT_CLOB                    constant integer := 112;
  EXT_BLOB                    constant integer := 113;
  EXT_BFILE                   constant integer := 114;
  EXT_OCI_STRING              constant integer := 155;
  EXT_OCI_DATE                constant integer := 156;
  EXT_ANSI_DATE               constant integer := 184;
  EXT_TIMESTAMP               constant integer := 187;
  EXT_TIMESTAMP_WITH_TZ       constant integer := 188;
  EXT_INTERVAL_YEAR_TO_MONTH  constant integer := 189;
  EXT_INTERVAL_DAY_TO_SECOND  constant integer := 190;
  EXT_TIMESTAMP_WITH_LOCAL_TZ constant integer := 232;

  /* PL/SQL Parameters Constants */
  PRM_IN    constant integer := 0;
  PRM_OUT   constant integer := 1;
  PRM_INOUT constant integer := 2;

  /* Other Constants */
  FUNC_RESULT          constant varchar2(10) := 'RESULT';
  COLUMN_MAX_LEN       constant integer := 30;
  ORA_VARCHAR2_MAX_LEN constant integer := 4000;
  PLS_VARCHAR2_MAX_LEN constant integer := 32767;

  -- ref cursor
  type t_cursor is ref cursor;

  -- row hash map (column=value)
  type t_row is table of varchar2(4000) index by varchar2(30);
  type t_row$ is table of clob index by varchar2(30);

  -- rowset (array of rows)
  type t_rowset is table of t_row;
  type t_rowset$ is table of t_row$;

  -- composit value
  type t_value is record(
    text     varchar2(32767),
    type#    integer,
    ora_type varchar2(100),
    xml_type varchar2(100),
    lob      clob,
    is_lob   boolean := false);

  -- map of named composit values
  type t_values is table of t_value index by varchar2(100);

  -- table column
  type t_column is record(
    name     varchar2(1000),
    pos#     integer,
    type#    integer,
    ora_type varchar2(100),
    xml_type varchar2(100),
    length   integer,
    scale    integer,
    is_key   boolean,
    is_null  boolean);

  -- table description
  type t_describe is table of t_column;

  -- pl/sql parameter
  type t_parameter is record(
    name       varchar2(1000),
    pos#       integer,
    type#      integer,
    ora_type   varchar2(100),
    level#     integer,
    in_out     integer,
    overload   integer,
    has_defval boolean);

  -- pl/sql signature
  type t_signature is table of t_parameter;

  -- pl/sql procedure description
  type t_procedure is record(
    name      varchar2(1000),
    is_func   boolean,
    signature t_signature);

  function get_type#(p_name varchar2) return integer;

  function get_ora_type(p_type# integer) return varchar2;

  function decode_type(p_desc dbms_sql.desc_rec3) return integer;

  function get_cursor(p_cursor# integer) return t_cursor;

  function get_cursor#(p_cursor t_cursor) return integer;

  function get_column(p_describe t_describe,
                      p_name     varchar2) return t_column;

  function has_column(p_describe t_describe,
                      p_column   t_column) return boolean;

  function has_column(p_describe t_describe,
                      p_name     varchar2) return boolean;

  function describe_table(p_table varchar2,
                          p_owner varchar2 default lib_util.this_schema) return t_describe;

  function describe_cursor(p_cursor# integer) return t_describe;

  function get_key_columns(p_table varchar2,
                           p_owner varchar2 default lib_util.this_schema) return t_describe;

  procedure define_column(p_cursor# integer,
                          p_column  t_column,
                          p_pos#    integer default null);

  procedure define_columns(p_cursor#  integer,
                           p_describe t_describe);

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

  procedure print_column(p_column t_column,
                         p_pos#   integer default null);

  procedure print_parameter(p_param t_parameter);

  procedure print_row(p_row t_row);

  procedure print_rowset(p_rowset t_rowset);

  procedure close_cursor(p_cursor# integer);

  procedure close_cursor(p_cursor t_cursor);

  function fetch_as_keyval#(p_cursor# integer,
                            b_close   boolean default false) return types.hashmap;

  function fetch_as_keyval(p_cursor t_cursor,
                           b_close  boolean default false) return types.hashmap;

  function fetch_as_rowset#(p_cursor# integer,
                            p_rows#   integer default null,
                            b_close   boolean default false) return t_rowset;

  function fetch_as_rowset(p_cursor t_cursor,
                           p_rows#  integer default null,
                           b_close  boolean default false) return t_rowset;

  function fetch_as_rowset$(p_cursor t_cursor,
                            p_rows#  integer default null,
                            b_close  boolean default false) return t_rowset$;

  function execute_query#(p_stmt varchar2) return integer;

  function execute_query#(p_stmt varchar2,
                          p_args t_values) return integer;

  function execute_query#(p_stmt varchar2,
                          p_args types.hashmap) return integer;

  function execute_query#(p_stmt varchar2,
                          p_arg1 varchar2,
                          p_arg2 varchar2 default null,
                          p_arg3 varchar2 default null,
                          p_arg4 varchar2 default null,
                          p_arg5 varchar2 default null,
                          p_arg6 varchar2 default null,
                          p_arg7 varchar2 default null,
                          p_arg8 varchar2 default null) return integer;

  function execute_query(p_stmt varchar2) return t_rowset;

  function execute_query(p_stmt varchar2,
                         p_arg1 varchar2,
                         p_arg2 varchar2 default null,
                         p_arg3 varchar2 default null,
                         p_arg4 varchar2 default null,
                         p_arg5 varchar2 default null,
                         p_arg6 varchar2 default null,
                         p_arg7 varchar2 default null,
                         p_arg8 varchar2 default null) return t_rowset;

  function describe_procedure(p_name varchar2,
                              p_ovl# integer default 0) return t_procedure;

  function call_procedure(p_name varchar2,
                          p_args types.hashmap,
                          p_ovl# integer default 0) return types.hashmap;

  procedure call_procedure(p_name varchar2,
                           p_arg1 varchar2 default null,
                           p_arg2 varchar2 default null,
                           p_arg3 varchar2 default null,
                           p_arg4 varchar2 default null,
                           p_arg5 varchar2 default null,
                           p_arg6 varchar2 default null,
                           p_arg7 varchar2 default null,
                           p_arg8 varchar2 default null);

  function call_procedure$(p_name varchar2,
                           p_args t_values,
                           p_ovl# integer default 0) return t_values;

  function call_function(p_name varchar2,
                         p_args types.hashmap,
                         p_ovl# integer default 0) return varchar2;

  function call_function(p_name varchar2,
                         p_arg1 varchar2 default null,
                         p_arg2 varchar2 default null,
                         p_arg3 varchar2 default null,
                         p_arg4 varchar2 default null,
                         p_arg5 varchar2 default null,
                         p_arg6 varchar2 default null,
                         p_arg7 varchar2 default null,
                         p_arg8 varchar2 default null) return varchar2;

  function call_function$(p_name varchar2,
                          p_args t_values,
                          p_ovl# integer default 0) return t_value;

end;
/

