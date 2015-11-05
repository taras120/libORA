create or replace package body lib_sql is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.07.2013 11:37:59
  -- Purpose : SQL Reflection Library

  -- exceptions
  BIND_NOT_FOUND exception;
  pragma exception_init(BIND_NOT_FOUND, -1006);

  -- additional constants
  ORA_UNKNOWN constant integer := -1;

  -- datatype values constant
  VAL_NUMBER   constant number := null;
  VAL_VARCHAR2 constant varchar2(1) := null;
  VAL_DATE     constant date := null;
  VAL_CHAR     constant char := null;
  VAL_BLOB     constant blob := null;
  VAL_CLOB     constant clob := null;
  VAL_ROWID    constant rowid := null;
  VAL_XMLTYPE  constant xmltype := null;

  -- datatypes map
  ORA_TYPE  types.StringTable;
  ORA_TYPE# types.IntegerMap;

  cursor c_tab_columns(p_table varchar2,
                       p_owner varchar2 default lib_util.this_schema) is
    select t.*
      from all_tab_columns t
     where t.table_name = upper(p_table)
       and t.owner = upper(p_owner)
     order by t.column_id;

  cursor c_key_columns(p_table varchar2,
                       p_owner varchar2 default lib_util.this_schema) is
    select i.column_name, i.column_position, i.column_length
      from all_constraints c, all_ind_columns i
     where c.table_name = upper(p_table)
       and c.owner = upper(p_owner)
       and c.constraint_type = 'P'
       and i.index_owner = c.index_owner
       and i.index_name = c.index_name;

  procedure init is
  begin
  
    -- oracle builtin types
    ORA_TYPE(ORA_UNKNOWN) := 'UNKNOWN';
    ORA_TYPE(ORA_VARCHAR2) := 'VARCHAR2';
    ORA_TYPE(ORA_NUMBER) := 'NUMBER';
    ORA_TYPE(ORA_LONG) := 'LONG';
    ORA_TYPE(ORA_ROWID) := 'ROWID';
    ORA_TYPE(ORA_DATE) := 'DATE';
    ORA_TYPE(ORA_RAW) := 'RAW';
    ORA_TYPE(ORA_LONG_RAW) := 'LONG_RAW';
    ORA_TYPE(ORA_CHAR) := 'CHAR';
    ORA_TYPE(ORA_BINARY_FLOAT) := 'BINARY_FLOAT';
    ORA_TYPE(ORA_BINARY_DOUBLE) := 'BINARY_DOUBLE';
    ORA_TYPE(ORA_MLSLABEL) := 'MLSLABEL';
    ORA_TYPE(ORA_USER_DEFINED) := 'USER_DEFINED';
    ORA_TYPE(ORA_REF) := 'REF';
    ORA_TYPE(ORA_CLOB) := 'CLOB';
    ORA_TYPE(ORA_BLOB) := 'BLOB';
    ORA_TYPE(ORA_BFILE) := 'BFILE';
    ORA_TYPE(ORA_UROWID) := 'UROWID';
    ORA_TYPE(ORA_TIMESTAMP) := 'TIMESTAMP';
    ORA_TYPE(ORA_TIMESTAMP_WITH_TZ) := 'TIMESTAMP WITH TIME ZONE';
    ORA_TYPE(ORA_TIMESTAMP_WITH_LOCAL_TZ) := 'TIMESTAMP WITH LOCAL TIME ZONE';
    ORA_TYPE(ORA_INTERVAL_YEAR_TO_MONTH) := 'INTERVAL YEAR TO MONTH';
    ORA_TYPE(ORA_INTERVAL_DAY_TO_SECOND) := 'INTERVAL DAY TO SECOND';
  
    -- user defined types
    ORA_TYPE(UDT_ANYDATA) := 'ANYDATA';
    ORA_TYPE(UDT_ANYDATASET) := 'ANYDATASET';
    ORA_TYPE(UDT_XMLTYPE) := 'XMLTYPE';
    ORA_TYPE(UDT_URITYPE) := 'URITYPE';
  
    -- pl/sql types
    ORA_TYPE(PLS_VOID) := 'VOID';
    ORA_TYPE(PLS_INTEGER) := 'INTEGER';
    ORA_TYPE(PLS_OPAQUE) := 'OPAQUE';
    ORA_TYPE(PLS_OBJECT) := 'OBJECT';
    ORA_TYPE(PLS_VARRAY) := 'VARRAY';
    ORA_TYPE(PLS_RECORD) := 'RECORD';
    ORA_TYPE(PLS_TABLE) := 'TABLE';
    ORA_TYPE(PLS_BOOLEAN) := 'BOOLEAN';
  
    -- datatype reverse array
    ORA_TYPE# := lib_map.turn(ORA_TYPE);
  end;

  function get_type#(p_name varchar2) return integer is
  begin
  
    return ORA_TYPE#(p_name);
  
  exception
    when NO_DATA_FOUND then
      return null;
    
    when others then
      lib_log.print_stack;
      raise;
  end;

  function get_ora_type(p_type# integer) return varchar2 is
  begin
  
    return ORA_TYPE(p_type#);
  
  exception
    when NO_DATA_FOUND then
      return ORA_TYPE(ORA_UNKNOWN);
    
    when others then
      lib_log.print_stack;
      raise;
  end;

  procedure check_type(p_t# integer,
                       p_t1 integer,
                       p_t2 integer default null,
                       p_t3 integer default null,
                       p_t4 integer default null) is
  begin
  
    if p_t# in (p_t1, p_t2, p_t3, p_t4) then
      null;
    else
      throw('[%s] Type is not compatible: %s!=(%s,%s,%s,%s)',
            get_ora_type(p_t#),
            p_t1,
            p_t2,
            p_t3,
            p_t4);
    end if;
  end;

  function decode_type(p_desc dbms_sql.desc_rec3) return integer is
  begin
  
    if p_desc.col_type = ORA_NUMBER and p_desc.col_scale = 0 then
    
      if lower(p_desc.col_name) like 'is%' then
        return PLS_BOOLEAN;
      else
        return PLS_INTEGER;
      end if;
    
    elsif p_desc.col_type = ORA_USER_DEFINED and p_desc.col_type_name = ORA_TYPE(UDT_XMLTYPE) then
    
      return UDT_XMLTYPE;
    
    else
      return p_desc.col_type;
    end if;
  end;

  function get_cursor(p_cursor# integer) return t_cursor is
    cursor# integer := p_cursor#;
  begin
    return dbms_sql.to_refcursor(cursor#);
  end;

  function get_cursor#(p_cursor t_cursor) return integer is
    v_cursor t_cursor := p_cursor;
  begin
    return dbms_sql.to_cursor_number(v_cursor);
  end;

  function get_column(p_describe t_describe,
                      p_name     varchar2) return t_column is
  begin
  
    for i in 1 .. p_describe.count loop
    
      if p_describe(i).name = p_name then
        return p_describe(i);
      end if;
    end loop;
  
    throw('Column not found in table description: %s', p_name);
  end;

  function has_column(p_describe t_describe,
                      p_column   t_column) return boolean is
  begin
  
    for i in 1 .. p_describe.count loop
    
      if p_describe(i).name = p_column.name then
        return true; /* nvl(p_describe(i).type# = p_column.type#, true); */
      end if;
    end loop;
  
    return false;
  end;

  function has_column(p_describe t_describe,
                      p_name     varchar2) return boolean is
  begin
  
    for i in 1 .. p_describe.count loop
    
      if p_describe(i).name = p_name then
        return true;
      end if;
    end loop;
  
    return false;
  end;

  function describe_table(p_table varchar2,
                          p_owner varchar2 default lib_util.this_schema) return t_describe is
  
    i        integer;
    column   t_column;
    describe t_describe := t_describe();
  begin
  
    lib_log.debug('*** Describe table %s.%s ***', p_owner, p_table);
  
    for q in c_tab_columns(p_table, p_owner) loop
    
      inc(i);
      column          := null;
      column.pos#     := q.column_id;
      column.type#    := ORA_TYPE#(q.data_type);
      column.ora_type := q.data_type;
      column.name     := q.column_name;
      column.length   := q.data_length;
      column.scale    := q.data_scale;
      column.is_null  := q.nullable = 'Y';
    
      -- check is key
      column.is_key := false;
      for key in c_key_columns(p_table, p_owner) loop
      
        column.is_key := column.name = key.column_name;
        exit when column.is_key;
      end loop;
    
      describe.extend;
      describe(i) := column;
    
      print_column(column, i);
    end loop;
  
    return describe;
  end;

  function describe_cursor(p_cursor# integer) return t_describe is
  
    col_cnt   integer;
    desc_rec3 dbms_sql.desc_rec3;
    desc_tab3 dbms_sql.desc_tab3;
    column    t_column;
    describe  t_describe := t_describe();
  begin
  
    lib_log.debug('*** Describe cursor #%s ***', p_cursor#);
  
    dbms_sql.describe_columns3(c => p_cursor#, col_cnt => col_cnt, desc_t => desc_tab3);
  
    for i in 1 .. desc_tab3.count loop
    
      desc_rec3 := desc_tab3(i);
    
      column          := null;
      column.pos#     := i;
      column.type#    := decode_type(desc_rec3);
      column.ora_type := get_ora_type(column.type#);
      column.name     := desc_rec3.col_name;
      column.length   := desc_rec3.col_max_len;
      column.scale    := desc_rec3.col_scale;
      column.is_null  := desc_rec3.col_null_ok;
    
      describe.extend;
      describe(i) := column;
    
      print_column(column, i);
    end loop;
  
    return describe;
  end;

  function get_key_columns(p_table varchar2,
                           p_owner varchar2 default lib_util.this_schema) return t_describe is
    descr t_describe;
  begin
  
    descr := describe_table(p_table => p_table, p_owner => p_owner);
  
    for i in 1 .. descr.count loop
      if descr(i).is_key then
        null;
      else
        descr.delete(i);
      end if;
    end loop;
  
    return descr;
  end;

  procedure define_column(p_cursor# integer,
                          p_column  t_column,
                          p_pos#    integer default null) is
  
    i integer := nvl(p_pos#, p_column.pos#);
  begin
  
    if p_column.type# = ORA_VARCHAR2 then
      dbms_sql.define_column(p_cursor#, i, VAL_VARCHAR2, p_column.length);
    elsif p_column.type# in (ORA_NUMBER, PLS_INTEGER, PLS_BOOLEAN) then
      dbms_sql.define_column(p_cursor#, i, VAL_NUMBER);
    elsif p_column.type# = ORA_DATE then
      dbms_sql.define_column(p_cursor#, i, VAL_DATE);
    elsif p_column.type# = ORA_BLOB then
      dbms_sql.define_column(p_cursor#, i, VAL_BLOB);
    elsif p_column.type# = ORA_CLOB then
      dbms_sql.define_column(p_cursor#, i, VAL_CLOB);
    elsif p_column.type# = ORA_CHAR then
      dbms_sql.define_column_char(p_cursor#, i, VAL_CHAR, p_column.length);
    elsif p_column.type# = ORA_ROWID then
      dbms_sql.define_column_rowid(p_cursor#, i, VAL_ROWID);
    elsif p_column.type# = UDT_XMLTYPE then
      dbms_sql.define_column(p_cursor#, i, VAL_XMLTYPE);
    else
      throw('[%s/%s] Unsupported column type', p_column.type#, p_column.ora_type);
    end if;
  end;

  procedure define_columns(p_cursor#  integer,
                           p_describe t_describe) is
  begin
  
    for i in 1 .. p_describe.count loop
      define_column(p_cursor#, p_describe(i));
    end loop;
  end;

  function get_string(p_cursor# integer,
                      p_column  t_column) return varchar2 is
  
    string_value varchar2(32767);
  begin
  
    check_type(p_column.type#, ORA_VARCHAR2);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.pos#, value => string_value);
    return string_value;
  end;

  function get_string(p_cursor# integer,
                      p_param   t_parameter) return varchar2 is
  
    string_value varchar2(32767);
  begin
  
    check_type(p_param.type#, ORA_VARCHAR2);
  
    dbms_sql.variable_value(c => p_cursor#, name => to_char(p_param.pos#), value => string_value);
    return string_value;
  end;

  function get_number(p_cursor# integer,
                      p_column  t_column) return number is
  
    number_value number;
  begin
  
    check_type(p_column.type#, ORA_NUMBER, PLS_INTEGER, PLS_BOOLEAN);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.pos#, value => number_value);
    return number_value;
  end;

  function get_number(p_cursor# integer,
                      p_param   t_parameter) return number is
  
    number_value number;
  begin
  
    check_type(p_param.type#, ORA_NUMBER, PLS_INTEGER, PLS_BOOLEAN);
  
    dbms_sql.variable_value(c => p_cursor#, name => to_char(p_param.pos#), value => number_value);
    return number_value;
  end;

  function get_integer(p_cursor# integer,
                       p_column  t_column) return integer is
  
    int_value number;
  begin
  
    check_type(p_column.type#, PLS_INTEGER, PLS_BOOLEAN);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.pos#, value => int_value);
    return int_value;
  end;

  function get_integer(p_cursor# integer,
                       p_param   t_parameter) return integer is
  
    int_value number;
  begin
  
    check_type(p_param.type#, PLS_INTEGER, PLS_BOOLEAN);
  
    dbms_sql.variable_value(c => p_cursor#, name => to_char(p_param.pos#), value => int_value);
    return int_value;
  end;

  function get_boolean(p_cursor# integer,
                       p_column  t_column) return boolean is
  
    bool_value number;
  begin
  
    check_type(p_column.type#, PLS_BOOLEAN);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.pos#, value => bool_value);
    return bool_value != 0;
  end;

  function get_boolean(p_cursor# integer,
                       p_param   t_parameter) return boolean is
  
    bool_value number;
  begin
  
    check_type(p_param.type#, PLS_BOOLEAN);
  
    dbms_sql.variable_value(c => p_cursor#, name => to_char(p_param.pos#), value => bool_value);
    return bool_value != 0;
  end;

  function get_date(p_cursor# integer,
                    p_column  t_column) return date is
  
    date_value date;
  begin
  
    check_type(p_column.type#, ORA_DATE);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.pos#, value => date_value);
    return date_value;
  end;

  function get_date(p_cursor# integer,
                    p_param   t_parameter) return date is
  
    date_value date;
  begin
  
    check_type(p_param.type#, ORA_DATE);
  
    dbms_sql.variable_value(c => p_cursor#, name => to_char(p_param.pos#), value => date_value);
    return date_value;
  end;

  function get_char(p_cursor# integer,
                    p_column  t_column) return char is
  
    char_value char;
  begin
  
    check_type(p_column.type#, ORA_CHAR);
  
    dbms_sql.column_value_char(c => p_cursor#, position => p_column.pos#, value => char_value);
    return char_value;
  end;

  function get_char(p_cursor# integer,
                    p_param   t_parameter) return char is
  
    char_value char;
  begin
  
    check_type(p_param.type#, ORA_CHAR);
  
    dbms_sql.variable_value_char(c     => p_cursor#,
                                 name  => to_char(p_param.pos#),
                                 value => char_value);
    return char_value;
  end;

  function get_blob(p_cursor# integer,
                    p_column  t_column) return blob is
  
    blob_value blob;
  begin
  
    check_type(p_column.type#, ORA_BLOB);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.pos#, value => blob_value);
    return blob_value;
  end;

  function get_blob(p_cursor# integer,
                    p_param   t_parameter) return blob is
  
    blob_value blob;
  begin
  
    check_type(p_param.type#, ORA_BLOB);
  
    dbms_sql.variable_value(c => p_cursor#, name => to_char(p_param.pos#), value => blob_value);
    return blob_value;
  end;

  function get_clob(p_cursor# integer,
                    p_column  t_column) return clob is
  
    clob_value    clob;
    string_value  varchar2(32767);
    xmltype_value xmltype;
  begin
  
    if p_column.type# = ORA_CLOB then
    
      dbms_sql.column_value(c => p_cursor#, position => p_column.pos#, value => clob_value);
      return clob_value;
    
    elsif p_column.type# = ORA_VARCHAR2 then
    
      dbms_sql.column_value(c => p_cursor#, position => p_column.pos#, value => string_value);
      return string_value;
    
    elsif p_column.type# = UDT_XMLTYPE then
    
      dbms_sql.column_value(c => p_cursor#, position => p_column.pos#, value => xmltype_value);
    
      if xmltype_value is not null then
        return xmltype_value.getclobval;
      else
        return null;
      end if;
    
    else
      throw('Column type is not CLOB compatible: %s', p_column.ora_type);
    end if;
  end;

  function get_clob(p_cursor# integer,
                    p_param   t_parameter) return clob is
  
    clob_value    clob;
    string_value  varchar2(32767);
    xmltype_value xmltype;
  begin
  
    if p_param.type# = ORA_CLOB then
    
      dbms_sql.variable_value(c => p_cursor#, name => to_char(p_param.pos#), value => clob_value);
      return clob_value;
    
    elsif p_param.type# = ORA_VARCHAR2 then
    
      dbms_sql.variable_value(c => p_cursor#, name => to_char(p_param.pos#), value => string_value);
      return string_value;
    
    elsif p_param.type# in (UDT_XMLTYPE) then
    
      dbms_sql.variable_value(c     => p_cursor#,
                              name  => to_char(p_param.pos#),
                              value => xmltype_value);
    
      if xmltype_value is not null then
        return xmltype_value.getclobval();
      else
        return null;
      end if;
    
    else
      throw('Parameter type is not CLOB compatible: %s', p_param.ora_type);
    end if;
  end;

  function get_rowid(p_cursor# integer,
                     p_column  t_column) return rowid is
  
    rowid_value rowid;
  begin
  
    check_type(p_column.type#, ORA_ROWID);
  
    dbms_sql.column_value_rowid(c => p_cursor#, position => p_column.pos#, value => rowid_value);
    return rowid_value;
  end;

  function get_rowid(p_cursor# integer,
                     p_param   t_parameter) return rowid is
  
    rowid_value rowid;
  begin
  
    check_type(p_param.type#, ORA_ROWID);
  
    dbms_sql.variable_value_rowid(c     => p_cursor#,
                                  name  => to_char(p_param.pos#),
                                  value => rowid_value);
    return rowid_value;
  end;

  function get_xmltype(p_cursor# integer,
                       p_column  t_column) return xmltype is
  
    xmltype_value xmltype;
  begin
  
    check_type(p_column.type#, UDT_XMLTYPE);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.pos#, value => xmltype_value);
    return xmltype_value;
  end;

  function get_xmltype(p_cursor# integer,
                       p_param   t_parameter) return xmltype is
  
    xmltype_value xmltype;
  begin
  
    check_type(p_param.type#, UDT_XMLTYPE);
  
    dbms_sql.variable_value(c => p_cursor#, name => to_char(p_param.pos#), value => xmltype_value);
    return xmltype_value;
  end;

  function get_value(p_cursor# integer,
                     p_column  t_column) return t_value is
    value t_value;
  begin
  
    value.type#    := p_column.type#;
    value.ora_type := p_column.ora_type;
  
    if p_column.type# = ORA_VARCHAR2 then
    
      value.text := get_string(p_cursor#, p_column);
    
    elsif p_column.type# = ORA_NUMBER then
    
      value.text := lib_xml.xmlNumber(get_number(p_cursor#, p_column));
    
    elsif p_column.type# = PLS_INTEGER then
    
      value.text := get_integer(p_cursor#, p_column);
    
    elsif p_column.type# = PLS_BOOLEAN then
    
      value.text := lib_xml.xmlBool(get_boolean(p_cursor#, p_column));
    
    elsif p_column.type# = ORA_DATE then
    
      value.text := lib_xml.xmlDateTime(get_date(p_cursor#, p_column));
    
    elsif p_column.type# = ORA_CHAR then
    
      value.text := get_char(p_cursor#, p_column);
    
    elsif p_column.type# = ORA_ROWID then
    
      value.text := get_rowid(p_cursor#, p_column);
    
    elsif p_column.type# = ORA_BLOB then
    
      value.lob    := lib_lob.b64_encode(get_blob(p_cursor#, p_column));
      value.is_lob := true;
    
    elsif p_column.type# in (ORA_CLOB, UDT_XMLTYPE) then
    
      value.lob    := get_clob(p_cursor#, p_column);
      value.is_lob := true;
    
    else
      throw('Unsupported column type: %s/%s', p_column.type#, p_column.ora_type);
    end if;
  
    return value;
  end;

  function get_value(p_cursor# integer,
                     p_param   t_parameter) return t_value is
    value t_value;
  begin
  
    value.type#    := p_param.type#;
    value.ora_type := p_param.ora_type;
  
    if p_param.type# = ORA_VARCHAR2 then
    
      value.text := get_string(p_cursor#, p_param);
    
    elsif p_param.type# = ORA_NUMBER then
    
      value.text := lib_xml.xmlNumber(get_number(p_cursor#, p_param));
    
    elsif p_param.type# = PLS_INTEGER then
    
      value.text := get_integer(p_cursor#, p_param);
    
    elsif p_param.type# = PLS_BOOLEAN then
    
      value.text := lib_xml.xmlBool(get_boolean(p_cursor#, p_param));
    
    elsif p_param.type# = ORA_DATE then
    
      value.text := lib_xml.xmlDateTime(get_date(p_cursor#, p_param));
    
    elsif p_param.type# = ORA_CHAR then
    
      value.text := get_char(p_cursor#, p_param);
    
    elsif p_param.type# = ORA_ROWID then
    
      value.text := get_rowid(p_cursor#, p_param);
    
    elsif p_param.type# = ORA_BLOB then
    
      value.lob    := lib_lob.b64_encode(get_blob(p_cursor#, p_param));
      value.is_lob := true;
    
    elsif p_param.type# in (ORA_CLOB, UDT_XMLTYPE) then
    
      value.lob    := get_clob(p_cursor#, p_param);
      value.is_lob := true;
    
    else
      throw('Unsupported parameter type: %s/%s', p_param.type#, p_param.ora_type);
    end if;
  
    return value;
  end;

  procedure print_column(p_column t_column,
                         p_pos#   integer default null) is
  
    i integer := nvl(p_pos#, p_column.pos#);
  begin
  
    lib_log.debug('(%s) name=%s', i, p_column.name);
    lib_log.debug('(%s) type=%s/%s', i, p_column.type#, p_column.ora_type);
    lib_log.debug('(%s) length=%s', i, p_column.length);
    lib_log.debug('(%s) scale=%s', i, p_column.scale);
    lib_log.debug('(%s) is_key=%s', i, to_int(p_column.is_key));
    lib_log.debug('(%s) is_null=%s', i, to_int(p_column.is_null));
  end;

  procedure print_parameter(p_param t_parameter) is
  begin
  
    lib_log.debug('(%s) name=%s', p_param.pos#, p_param.name);
    lib_log.debug('(%s) type#=%s/%s', p_param.pos#, p_param.type#, p_param.ora_type);
    lib_log.debug('(%s) level#=%s', p_param.pos#, p_param.level#);
    lib_log.debug('(%s) in_out=%s', p_param.pos#, p_param.in_out);
    lib_log.debug('(%s) overload=%s', p_param.pos#, p_param.overload);
    lib_log.debug('(%s) has_defval=%s', p_param.pos#, to_int(p_param.has_defval));
  end;

  procedure print_row(p_row t_row) is
    col varchar2(30);
  begin
  
    col := p_row.first;
    while col is not null loop
    
      lib_log.debug('%s=%s', col, p_row(col));
      col := p_row.next(col);
    end loop;
  end;

  procedure print_rowset(p_rowset t_rowset) is
  begin
  
    for i in 1 .. p_rowset.count loop
    
      lib_log.debug('ROW #%s:', i);
      print_row(p_rowset(i));
    end loop;
  end;

  function parse_bindings(p_stmt varchar2) return types.list is
  
    j    integer;
    arr  lib_text.t_array;
    list types.list := types.list();
  begin
  
    if p_stmt is not null and instr(p_stmt, ':') != 0 then
    
      arr := lib_text.split(p_stmt, ':');
    
      for n in 2 .. arr.count loop
      
        j := 0;
        for i in 1 .. length(arr(n)) loop
          exit when not lib_text.is_alphanum(substr(arr(n), i, 1));
        
          j := i;
        end loop;
      
        if j > 0 then
          list.extend;
        
          list(list.last) := substr(arr(n), 1, j);
        end if;
      end loop;
    end if;
  
    return list;
  end;

  function execute_cursor#(p_cursor# integer) return integer is
    rows# integer;
  begin
  
    rows# := dbms_sql.execute(p_cursor#);
  
    lib_log.debug('#%s: %s row(s) processed', lpad(p_cursor#, 16, 0), rows#);
  
    return rows#;
  end;

  procedure execute_cursor#(p_cursor# integer) is
  begin
    callf(execute_cursor#(p_cursor#));
  end;

  procedure close_cursor(p_cursor# integer) is
    cursor# integer := p_cursor#;
  begin
  
    if cursor# is not null and dbms_sql.is_open(cursor#) then
      dbms_sql.close_cursor(cursor#);
    end if;
  end;

  procedure close_cursor(p_cursor t_cursor) is
  begin
    if p_cursor is not null then
      close_cursor(get_cursor#(p_cursor));
    end if;
  end;

  function fetch_as_keyval#(p_cursor# integer,
                            b_close   boolean default false) return types.hashmap is
  
    describe t_describe;
    key      t_value;
    val      t_value;
    data     types.hashmap;
  begin
  
    describe := describe_cursor(p_cursor#);
    define_columns(p_cursor#, describe);
  
    loop
      exit when dbms_sql.fetch_rows(p_cursor#) = 0;
    
      key := get_value(p_cursor#, describe(1));
      val := get_value(p_cursor#, describe(2));
    
      data(key.text) := val.text;
    end loop;
  
    if b_close then
      close_cursor(p_cursor#);
    end if;
  
    return data;
  end;

  function fetch_as_keyval(p_cursor t_cursor,
                           b_close  boolean default false) return types.hashmap is
  begin
    return fetch_as_keyval#(p_cursor# => get_cursor#(p_cursor), b_close => b_close);
  end;

  function fetch_as_rowset#(p_cursor# integer,
                            p_rows#   integer default null,
                            b_close   boolean default false) return t_rowset is
  
    n        integer;
    column   t_column;
    describe t_describe;
    rec      t_row;
    rowset   t_rowset := t_rowset();
    val      t_value;
  begin
  
    describe := describe_cursor(p_cursor#);
    define_columns(p_cursor#, describe);
  
    n := 0;
    loop
      exit when dbms_sql.fetch_rows(p_cursor#) = 0;
    
      inc(n);
      rec.delete;
    
      for i in 1 .. describe.count loop
      
        column := describe(i);
        val := get_value(p_cursor#, column);
        rec(column.name) := val.text;
      end loop;
    
      rowset.extend;
      rowset(rowset.last) := rec;
    
      exit when n >= p_rows#;
    end loop;
  
    if b_close then
      close_cursor(p_cursor#);
    end if;
  
    return rowset;
  end;

  function fetch_as_rowset(p_cursor t_cursor,
                           p_rows#  integer default null,
                           b_close  boolean default false) return t_rowset is
  
  begin
    
    return fetch_as_rowset#(p_cursor# => get_cursor#(p_cursor),
                            p_rows#   => p_rows#,
                            b_close   => b_close);
  end;
  
  function fetch_as_rowset$(p_cursor t_cursor,
                            p_rows#   integer default null,
                            b_close   boolean default false) return t_rowset$ is
  
    n        integer;
    column   t_column;
    describe t_describe;
    rec$     t_row$;
    rowset$  t_rowset$ := t_rowset$();
    val      t_value;
    cursor#  integer := get_cursor#(p_cursor);
  begin
  
    describe := describe_cursor(cursor#);
    define_columns(cursor#, describe);
  
    n := 0;
    loop
      exit when dbms_sql.fetch_rows(cursor#) = 0;
    
      inc(n);
      rec$.delete;
    
      for i in 1 .. describe.count loop
      
        column := describe(i);
        val := get_value(cursor#, column);
        
        if val.is_lob then        
          rec$(column.name) := val.lob;
        else
          rec$(column.name) := val.text;
        end if;    
      end loop;
    
      rowset$.extend;
      rowset$(rowset$.last) := rec$;
    
      exit when n >= p_rows#;
    end loop;
  
    if b_close then
      close_cursor(cursor#);
    end if;
  
    return rowset$;
  end;

  procedure bind_variable(p_cursor# integer,
                          p_name    varchar2,
                          p_value   t_value) is
  begin
  
    -- bind
    if p_value.type# = ORA_CLOB then
    
      dbms_sql.bind_variable(c => p_cursor#, name => p_name, value => p_value.lob);
    
    elsif p_value.type# = ORA_BLOB then
    
      dbms_sql.bind_variable(c     => p_cursor#,
                             name  => p_name,
                             value => lib_lob.b64_decode(p_value.lob));
    
    elsif p_value.type# in (UDT_XMLTYPE) then
    
      dbms_sql.bind_variable(c => p_cursor#, name => p_name, value => xmltype(p_value.lob));
    
    else
    
      -- all others bins as varchar2
      dbms_sql.bind_variable(c => p_cursor#, name => p_name, value => p_value.text);
    end if;
  
  exception
    when BIND_NOT_FOUND then
      lib_log.debug('%s: %s', sqlerrm, p_name);
  end;

  function prepare_values(p_args types.hashmap) return t_values is
    key   varchar2(1000);
    val   t_value;
    args$ t_values;
  begin
  
    key := p_args.first;
    while key is not null loop
    
      val        := null;
      val.type#  := ORA_VARCHAR2;
      val.text   := p_args(key);
      val.is_lob := false;
    
      args$(key) := val;
    
      key := p_args.next(key);
    end loop;
  
    return args$;
  end;

  function prepare_statemet(p_proc t_procedure) return varchar2 is
  
    n            integer;
    param        t_parameter;
    result       varchar2(4000);
    is_func      boolean;
    is_bool_func boolean;
  
    procedure add(text varchar2,
                  arg1 varchar2 default null,
                  arg2 varchar2 default null) is
    begin
      result := result || sprintf(text, arg1, arg2);
    end;
  
  begin
  
    is_func := p_proc.is_func;
  
    if is_func then
      is_bool_func := p_proc.signature(1).type# = PLS_BOOLEAN;
    else
      is_bool_func := false;
    end if;
  
    if is_func then
    
      if is_bool_func then
        add('begin :0 := sys.diutil.bool_to_int(%s(', p_proc.name);
      else
        add('begin :0 := %s(', p_proc.name);
      end if;
    
    else
      add('begin %s(', p_proc.name);
    end if;
  
    n := iif(is_func, 2, 1);
  
    for i in n .. p_proc.signature.count loop
    
      param := p_proc.signature(i);
    
      if i = n then
        add(':%s', param.pos#);
      else
        add(',:%s', param.pos#);
      end if;
    
    end loop;
  
    if is_bool_func then
      add(')); end;');
    else
      add('); end;');
    end if;
  
    return result;
  end;

  function describe_procedure(p_name varchar2,
                              p_ovl# integer default 0) return t_procedure is
  
    overload      dbms_describe.number_table;
    position      dbms_describe.number_table;
    level         dbms_describe.number_table;
    argument_name dbms_describe.varchar2_table;
    datatype      dbms_describe.number_table;
    default_value dbms_describe.number_table;
    in_out        dbms_describe.number_table;
    length        dbms_describe.number_table;
    precision     dbms_describe.number_table;
    scale         dbms_describe.number_table;
    radix         dbms_describe.number_table;
    spare         dbms_describe.number_table;
    param         t_parameter;
    proc          t_procedure;
  begin
  
    if p_name is null then
      throw('Procedure name is required');
    end if;
  
    proc.name      := p_name;
    proc.is_func   := false;
    proc.signature := t_signature();
  
    dbms_describe.describe_procedure(object_name                => p_name,
                                     reserved1                  => null,
                                     reserved2                  => null,
                                     overload                   => overload,
                                     position                   => position,
                                     level                      => level,
                                     argument_name              => argument_name,
                                     datatype                   => datatype,
                                     default_value              => default_value,
                                     in_out                     => in_out,
                                     length                     => length,
                                     precision                  => precision,
                                     scale                      => scale,
                                     radix                      => radix,
                                     spare                      => spare,
                                     include_string_constraints => false);
  
    for i in 1 .. overload.count loop
    
      if overload(i) = p_ovl# then
      
        lib_log.debug('Parameter #%s:', i);
      
        param          := null;
        param.pos#     := position(i);
        param.name     := argument_name(i);
        param.type#    := datatype(i);
        param.ora_type := get_ora_type(param.type#);
      
        -- xmltype fix
        if param.type# = PLS_OPAQUE then
          param.type# := UDT_XMLTYPE;
        end if;
      
        param.level#     := level(i);
        param.in_out     := in_out(i);
        param.overload   := overload(i);
        param.has_defval := default_value(i) != 0;
      
        if param.pos# = 0 then
          proc.is_func := true;
          param.name   := FUNC_RESULT;
        end if;
      
        print_parameter(param);
      
        if param.type# != PLS_VOID then
          proc.signature.extend;
          proc.signature(proc.signature.last) := param;
        end if;
      end if;
    end loop;
  
    return proc;
  end;

  function execute_query#(p_stmt varchar2) return integer is
  
    cursor# integer;
  begin
  
    cursor# := dbms_sql.open_cursor;
  
    dbms_sql.parse(cursor#, p_stmt, dbms_sql.native);
    execute_cursor#(cursor#);
  
    return cursor#;
  
  exception
    when others then
    
      close_cursor(cursor#);
      lib_log.print_stack;
      raise;
  end;

  function execute_query#(p_stmt varchar2,
                          p_args t_values) return integer is
  
    cursor#  integer;
    arg_name varchar2(1000);
  begin
  
    -- log statement
    lib_log.debug(p_stmt);
  
    -- open cursor
    cursor# := dbms_sql.open_cursor;
  
    -- parse statement
    dbms_sql.parse(cursor#, p_stmt, dbms_sql.native);
  
    -- bind
    arg_name := p_args.first;
    for i in 1 .. p_args.count loop
    
      bind_variable(p_cursor# => cursor#, p_name => arg_name, p_value => p_args(arg_name));
    
      arg_name := p_args.next(arg_name);
    end loop;
  
    -- execute
    execute_cursor#(cursor#);
  
    return cursor#;
  
  exception
    when others then
    
      close_cursor(cursor#);
      lib_log.print_stack;
      raise;
  end;

  function execute_query#(p_stmt varchar2,
                          p_args types.hashmap) return integer is
  begin
    return execute_query#(p_stmt => p_stmt, p_args => prepare_values(p_args));
  end;

  function execute_query#(p_stmt varchar2,
                          p_arg1 varchar2,
                          p_arg2 varchar2 default null,
                          p_arg3 varchar2 default null,
                          p_arg4 varchar2 default null,
                          p_arg5 varchar2 default null,
                          p_arg6 varchar2 default null,
                          p_arg7 varchar2 default null,
                          p_arg8 varchar2 default null) return integer is
  
    args  types.hashmap;
    binds types.list;
  begin
  
    -- parse bindings
    binds := parse_bindings(p_stmt);
  
    for i in 1 .. binds.count loop
    
      args(binds(i)) := enum(i, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
    end loop;
  
    return execute_query#(p_stmt, args);
  end;

  function execute_query(p_stmt varchar2) return t_rowset is
  
    cursor# integer;
  begin
  
    cursor# := execute_query#(p_stmt);
  
    return fetch_as_rowset#(p_cursor# => cursor#, b_close => true);
  
  exception
    when others then
    
      close_cursor(cursor#);
      lib_log.print_stack;
      raise;
  end;

  function execute_query(p_stmt varchar2,
                         p_arg1 varchar2,
                         p_arg2 varchar2 default null,
                         p_arg3 varchar2 default null,
                         p_arg4 varchar2 default null,
                         p_arg5 varchar2 default null,
                         p_arg6 varchar2 default null,
                         p_arg7 varchar2 default null,
                         p_arg8 varchar2 default null) return t_rowset is
  
    cursor# integer;
  begin
  
    cursor# := execute_query#(p_stmt,
                              p_arg1,
                              p_arg2,
                              p_arg3,
                              p_arg4,
                              p_arg5,
                              p_arg6,
                              p_arg7,
                              p_arg8);
  
    return fetch_as_rowset#(p_cursor# => cursor#, b_close => true);
  
  exception
    when others then
    
      close_cursor(cursor#);
      lib_log.print_stack;
      raise;
  end;

  function call_procedure#(p_proc t_procedure,
                           p_args t_values) return integer is
  
    param   t_parameter;
    stmt    varchar2(32767);
    value   t_value;
    cursor# integer;
  begin
  
    -- prepare statement
    stmt := prepare_statemet(p_proc);
  
    -- log statement
    lib_log.debug(stmt);
  
    -- open cursor
    cursor# := dbms_sql.open_cursor;
  
    -- parse
    dbms_sql.parse(cursor#, stmt, dbms_sql.native);
  
    -- bind parameters
    for i in 1 .. p_proc.signature.count loop
    
      param := p_proc.signature(i);
    
      if param.in_out in (PRM_IN, PRM_INOUT) then
      
        if p_args.exists(param.name) then
        
          value := p_args(param.name);
        
        elsif p_args.exists(param.pos#) then
        
          value := p_args(param.pos#);
        
        elsif not param.has_defval then
        
          throw('Parameter is missing: %s', param.name);
        
        end if;
      
        -- bind
        bind_variable(p_cursor# => cursor#, p_name => to_char(param.pos#), p_value => value);
      
      elsif param.in_out = PRM_OUT then
      
        -- register output parameters
        if param.type# in (ORA_NUMBER, PLS_INTEGER, PLS_BOOLEAN) then
        
          dbms_sql.bind_variable(c => cursor#, name => to_char(param.pos#), value => VAL_NUMBER);
        
        elsif param.type# = ORA_DATE then
        
          dbms_sql.bind_variable(c => cursor#, name => to_char(param.pos#), value => VAL_DATE);
        
        elsif param.type# = ORA_CLOB then
        
          dbms_sql.bind_variable(c => cursor#, name => to_char(param.pos#), value => VAL_CLOB);
        
        elsif param.type# = ORA_BLOB then
        
          dbms_sql.bind_variable(c => cursor#, name => to_char(param.pos#), value => VAL_BLOB);
        
        elsif param.type# in (UDT_XMLTYPE) then
        
          dbms_sql.bind_variable(c => cursor#, name => to_char(param.pos#), value => VAL_XMLTYPE);
        
        else
        
          -- all others map as varchar2
          dbms_sql.bind_variable(c              => cursor#,
                                 name           => to_char(param.pos#),
                                 value          => VAL_VARCHAR2,
                                 out_value_size => PLS_VARCHAR2_MAX_LEN);
        end if;
      end if;
    end loop;
  
    -- execute
    execute_cursor#(cursor#);
  
    return cursor#;
  
  exception
    when others then
    
      close_cursor(cursor#);
      lib_log.print_stack;
      raise;
  end;

  function call_procedure#(p_proc t_procedure,
                           p_args types.hashmap) return integer is
  begin
  
    return call_procedure#(p_proc => p_proc, p_args => prepare_values(p_args));
  end;

  function call_procedure(p_name varchar2,
                          p_args types.hashmap,
                          p_ovl# integer default 0) return types.hashmap is
  
    cursor#   integer;
    proc      t_procedure;
    param     t_parameter;
    out_value t_value;
    results   types.hashmap;
  begin
  
    -- describe procedure
    proc := describe_procedure(p_name, p_ovl#);
  
    -- call procedure
    cursor# := call_procedure#(p_proc => proc, p_args => p_args);
  
    -- fetch result
    for i in 1 .. proc.signature.count loop
    
      param := proc.signature(i);
    
      if param.in_out in (PRM_OUT, PRM_INOUT) then
      
        out_value := get_value(cursor#, param);
      
        if out_value.is_lob then
        
          if dbms_lob.getLength(out_value.lob) <= PLS_VARCHAR2_MAX_LEN then
            results(param.name) := out_value.lob;
          else
            throw('Result length is too big: %s, size = %s',
                  param.name,
                  dbms_lob.getLength(out_value.lob));
          end if;
        
        else
          results(param.name) := out_value.text;
        end if;
      
      end if;
    end loop;
  
    -- close cursor
    close_cursor(cursor#);
  
    return results;
  
  exception
    when others then
    
      close_cursor(cursor#);
      lib_log.print_stack;
      raise;
  end;

  procedure call_procedure(p_name varchar2,
                           p_arg1 varchar2 default null,
                           p_arg2 varchar2 default null,
                           p_arg3 varchar2 default null,
                           p_arg4 varchar2 default null,
                           p_arg5 varchar2 default null,
                           p_arg6 varchar2 default null,
                           p_arg7 varchar2 default null,
                           p_arg8 varchar2 default null) is
  
    args types.hashmap;
  begin
  
    for i in 1 .. 8 loop
      args(i) := enum(i, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
    end loop;
  
    callf(call_procedure(p_name, args).count);
  end;

  function call_procedure$(p_name varchar2,
                           p_args t_values,
                           p_ovl# integer default 0) return t_values is
  
    proc    t_procedure;
    param   t_parameter;
    cursor# integer;
    results t_values;
  begin
  
    -- describe procedure
    proc := describe_procedure(p_name, p_ovl#);
  
    -- call procedure
    cursor# := call_procedure#(p_proc => proc, p_args => p_args);
  
    -- fetch result
    for i in 1 .. proc.signature.count loop
    
      param := proc.signature(i);
    
      if param.in_out in (PRM_OUT, PRM_INOUT) then
      
        results(param.name) := get_value(cursor#, param);
      end if;
    end loop;
  
    -- close cursor
    close_cursor(cursor#);
  
    return results;
  
  exception
    when others then
    
      close_cursor(cursor#);
      lib_log.print_stack;
      raise;
  end;

  function call_function(p_name varchar2,
                         p_args types.hashmap,
                         p_ovl# integer default 0) return varchar2 is
  
    results types.hashmap;
  begin
  
    results := call_procedure(p_name, p_args, p_ovl#);
  
    return results(FUNC_RESULT);
  end;

  function call_function(p_name varchar2,
                         p_arg1 varchar2 default null,
                         p_arg2 varchar2 default null,
                         p_arg3 varchar2 default null,
                         p_arg4 varchar2 default null,
                         p_arg5 varchar2 default null,
                         p_arg6 varchar2 default null,
                         p_arg7 varchar2 default null,
                         p_arg8 varchar2 default null) return varchar2 is
  
    args    types.hashmap;
    results types.hashmap;
  begin
  
    for i in 1 .. 8 loop
      args(i) := enum(i, p_arg1, p_arg2, p_arg3, p_arg4, p_arg5, p_arg6, p_arg7, p_arg8);
    end loop;
  
    results := call_procedure(p_name, args);
  
    return results(FUNC_RESULT);
  end;

  function call_function$(p_name varchar2,
                          p_args t_values,
                          p_ovl# integer default 0) return t_value is
  
    results t_values;
  begin
  
    results := call_procedure$(p_name, p_args, p_ovl#);
  
    if results.exists(FUNC_RESULT) then
      return results(FUNC_RESULT);
    else
      return null;
    end if;
  
  end;

begin
  init();
end;
/

