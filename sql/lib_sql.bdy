create or replace package body lib_sql is

  -- LibORA PL/SQL Library
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.07.2013 11:37:59  
  -- Purpose : SQL Reflection Library

  -- types constant
  COL_NUMBER   constant number := null;
  COL_VARCHAR2 constant varchar2(1) := null;
  COL_DATE     constant date := null;
  COL_CHAR     constant char := null;
  COL_BLOB     constant blob := null;
  COL_CLOB     constant clob := null;
  COL_ROWID    constant rowid := null;
  COL_XMLTYPE  constant xmltype := null;

  -- xmlt tags names
  XML_TAG_ROOT   constant varchar2(100) := 'root';
  XML_TAG_RECORD constant varchar2(100) := 'record';
  XML_ATTR_RECNO constant varchar2(100) := 'recNo';

  TYPE_ID   types.hash_map;
  TYPE_NAME types.hash_map;

  procedure init is
    typeName varchar2(100);
  begin
  
    -- oracle builtin types
    TYPE_ID('String') := ORA_VARCHAR2;
    TYPE_ID('Number') := ORA_NUMBER;
    TYPE_ID('Long') := ORA_LONG;
    TYPE_ID('Rowid') := ORA_ROWID;
    TYPE_ID('Date') := ORA_DATE;
    TYPE_ID('Raw') := ORA_RAW;
    TYPE_ID('LongRaw') := ORA_LONG_RAW;
    TYPE_ID('Char') := ORA_CHAR;
    TYPE_ID('Float') := ORA_BINARY_FLOAT;
    TYPE_ID('Double') := ORA_BINARY_DOUBLE;
    TYPE_ID('MLSLabel') := ORA_MLSLABEL;
    TYPE_ID('UserDefined') := ORA_USER_DEFINED;
    TYPE_ID('Ref') := ORA_REF;
    TYPE_ID('Clob') := ORA_CLOB;
    TYPE_ID('Blob') := ORA_BLOB;
    TYPE_ID('BFile') := ORA_BFILE;
    TYPE_ID('Timestamp') := ORA_TIMESTAMP;
    TYPE_ID('TimestampWithTZ') := ORA_TIMESTAMP_WITH_TZ;
    TYPE_ID('IntervalYTM') := ORA_INTERVAL_YEAR_TO_MONTH;
    TYPE_ID('IntervalDTS') := ORA_INTERVAL_DAY_TO_SECOND;
    TYPE_ID('Urowid') := ORA_UROWID;
    TYPE_ID('TimestampWithLocalTZ') := ORA_TIMESTAMP_WITH_LOCAL_TZ;
  
    -- user defined types
    TYPE_ID('Integer') := USER_INTEGER;
    TYPE_ID('XmlType') := USER_XMLTYPE;
    TYPE_ID('Boolean') := USER_BOOLEAN;
  
    -- id->name array
    typeName := TYPE_ID.first;
    while typeName is not null loop
      TYPE_NAME(TYPE_ID(typeName)) := typeName;
      typeName := TYPE_ID.next(typeName);
    end loop;
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

  function get_type_id(p_name integer) return varchar2 is
  begin
    return TYPE_ID(p_name);
  end;

  function decode_type(p_desc dbms_sql.desc_rec3) return integer is
  begin
  
    if p_desc.col_type = ORA_NUMBER and p_desc.col_scale = 0 then
    
      if p_desc.col_name like 'IS%' then
        return USER_BOOLEAN;
      else
        return USER_INTEGER;
      end if;
    elsif p_desc.col_type = ORA_USER_DEFINED and p_desc.col_type_name = 'XMLTYPE' then
      return USER_XMLTYPE;
    else
      return p_desc.col_type;
    end if;
  end;

  function get_type_name(p_type integer) return varchar2 is
  begin
  
    return TYPE_NAME(p_type);
  end;

  function describe_cursor(p_cursor# integer) return t_describe is
  
    col_cnt   integer;
    desc_rec3 dbms_sql.desc_rec3;
    desc_tab3 dbms_sql.desc_tab3;
    column    t_column;
    describe  t_describe := t_describe();
  begin
  
    dbms_sql.describe_columns3(c => p_cursor#, col_cnt => col_cnt, desc_t => desc_tab3);
  
    lib_log.debug('*** Describe cursor ***');
  
    for i in 1 .. desc_tab3.count loop
    
      desc_rec3 := desc_tab3(i);
    
      column          := null;
      column.position := i;
      column.typeId   := decode_type(desc_rec3);
      column.typeName := get_type_name(column.typeId);
      column.name     := desc_rec3.col_name;
      column.maxlen   := desc_rec3.col_max_len;
      column.scale    := desc_rec3.col_scale;
      column.isNull   := desc_rec3.col_null_ok;
    
      describe.extend;
      describe(i) := column;
    
      lib_log.debug('(%s) name=%s', i, column.name);
      lib_log.debug('(%s) type=%s/%s', i, column.typeId, column.typeName);
      lib_log.debug('(%s) maxlen=%s', i, column.maxlen);
      lib_log.debug('(%s) scale=%s', i, column.scale);
      lib_log.debug('(%s) is_null=%s', i, to_int(column.isNull));
    end loop;
  
    return describe;
  end;

  procedure define_column(p_cursor#  integer,
                          p_column   t_column,
                          p_position integer default null) is
    i integer := nvl(p_position, p_column.position);
  begin
  
    if p_column.typeId = ORA_VARCHAR2 then
      dbms_sql.define_column(p_cursor#, i, COL_VARCHAR2, p_column.maxlen);
    elsif p_column.typeId in (ORA_NUMBER, USER_INTEGER, USER_BOOLEAN) then
      dbms_sql.define_column(p_cursor#, i, COL_NUMBER);
    elsif p_column.typeId = ORA_DATE then
      dbms_sql.define_column(p_cursor#, i, COL_DATE);
    elsif p_column.typeId = ORA_BLOB then
      dbms_sql.define_column(p_cursor#, i, COL_BLOB);
    elsif p_column.typeId = ORA_CLOB then
      dbms_sql.define_column(p_cursor#, i, COL_CLOB);
    elsif p_column.typeId = ORA_CHAR then
      dbms_sql.define_column_char(p_cursor#, i, COL_CHAR, p_column.maxlen);
    elsif p_column.typeId = ORA_ROWID then
      dbms_sql.define_column_rowid(p_cursor#, i, COL_ROWID);
    elsif p_column.typeId = USER_XMLTYPE then
      dbms_sql.define_column(p_cursor#, i, COL_XMLTYPE);
    else
      throw('[%s/%s] Unsupported column type', p_column.typeId, p_column.typeName);
    end if;
  end;

  procedure define_columns(p_cursor#  integer,
                           p_describe t_describe) is
  begin
  
    for i in 1 .. p_describe.count loop
      define_column(p_cursor#, p_describe(i));
    end loop;
  end;

  procedure check_type(p_type integer,
                       p_t1   integer,
                       p_t2   integer default null,
                       p_t3   integer default null,
                       p_t4   integer default null) is
  begin
    if p_type in (p_t1, p_t2, p_t3, p_t4) then
      null;
    else
      throw('[%s] Type is not compatible: %s!=(%s,%s,%s,%s)',
            get_type_name(p_type),
            p_type,
            p_t1,
            p_t2,
            p_t3,
            p_t4);
    end if;
  end;

  function get_string(p_cursor# integer,
                      p_column  t_column) return varchar2 is
  
    string_value varchar2(32767);
  begin
  
    check_type(p_column.typeId, ORA_VARCHAR2);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => string_value);
    return string_value;
  end;

  function get_number(p_cursor# integer,
                      p_column  t_column) return number is
  
    number_value number;
  begin
  
    check_type(p_column.typeId, ORA_NUMBER, USER_INTEGER, USER_BOOLEAN);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => number_value);
    return number_value;
  end;

  function get_integer(p_cursor# integer,
                       p_column  t_column) return integer is
  
    int_value number;
  begin
  
    check_type(p_column.typeId, USER_INTEGER, USER_BOOLEAN);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => int_value);
    return int_value;
  end;

  function get_boolean(p_cursor# integer,
                       p_column  t_column) return boolean is
  
    bool_value number;
  begin
  
    check_type(p_column.typeId, USER_BOOLEAN);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => bool_value);
    return bool_value != 0;
  end;

  function get_date(p_cursor# integer,
                    p_column  t_column) return date is
  
    date_value date;
  begin
  
    check_type(p_column.typeId, ORA_DATE);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => date_value);
    return date_value;
  end;

  function get_char(p_cursor# integer,
                    p_column  t_column) return char is
  
    char_value char;
  begin
  
    check_type(p_column.typeId, ORA_CHAR);
  
    dbms_sql.column_value_char(c => p_cursor#, position => p_column.position, value => char_value);
    return char_value;
  end;

  function get_blob(p_cursor# integer,
                    p_column  t_column) return blob is
  
    blob_value blob;
  begin
  
    check_type(p_column.typeId, ORA_BLOB);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => blob_value);
    return blob_value;
  end;

  function get_clob(p_cursor# integer,
                    p_column  t_column) return clob is
  
    clob_value    clob;
    xmltype_value xmltype;
  begin
  
    check_type(p_column.typeId, ORA_BLOB, USER_XMLTYPE);
  
    if p_column.typeId = ORA_CLOB then
    
      dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => clob_value);
      return clob_value;
    
    elsif p_column.typeId = USER_XMLTYPE then
    
      dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => xmltype_value);
    
      if xmltype_value is not null then
        return xmltype_value.getclobval;
      else
        return null;
      end if;
    
    else
      throw('[%s] Column type is not compatible', p_column.typeName);
    end if;
  end;

  function get_rowid(p_cursor# integer,
                     p_column  t_column) return rowid is
  
    rowid_value rowid;
  begin
  
    check_type(p_column.typeId, ORA_ROWID);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => rowid_value);
    return rowid_value;
  end;

  function get_xmltype(p_cursor# integer,
                       p_column  t_column) return xmltype is
  
    xmltype_value xmltype;
  begin
  
    check_type(p_column.typeId, USER_XMLTYPE);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => xmltype_value);
    return xmltype_value;
  end;

  function get_value(p_cursor# integer,
                     p_column  t_column) return t_value is
    value t_value;
  begin
  
    value.typeId   := p_column.typeId;
    value.typeName := p_column.typeName;
  
    if p_column.typeId = ORA_VARCHAR2 then
    
      value.text := get_string(p_cursor#, p_column);
    
    elsif p_column.typeId = ORA_NUMBER then
    
      value.text := xml.xmlNumber(get_number(p_cursor#, p_column));
    
    elsif p_column.typeId = USER_INTEGER then
    
      value.text := get_integer(p_cursor#, p_column);
    
    elsif p_column.typeId = USER_BOOLEAN then
    
      value.text := xml.xmlBool(get_boolean(p_cursor#, p_column));
    
    elsif p_column.typeId = ORA_DATE then
    
      value.text := xml.xmlDateTime(get_date(p_cursor#, p_column));
    
    elsif p_column.typeId = ORA_CHAR then
    
      value.text := get_char(p_cursor#, p_column);
    
    elsif p_column.typeId = ORA_ROWID then
    
      value.text := get_rowid(p_cursor#, p_column);
    
    elsif p_column.typeId = ORA_BLOB then
    
      value.lob   := lib_lob.b64_encode(get_blob(p_cursor#, p_column));
      value.isLob := true;
    
    elsif p_column.typeId in (ORA_CLOB, USER_XMLTYPE) then
    
      value.lob   := get_clob(p_cursor#, p_column);
      value.isLob := true;
    
    else
      throw('[%s] Unsupported column type', p_column.typeId, p_column.typeName);
    end if;
  
    return value;
  end;

  procedure close_cursor(p_cursor# integer) is
    cursor# integer := p_cursor#;
  begin
    dbms_sql.close_cursor(cursor#);
  end;

  procedure close_cursor(p_cursor t_cursor) is
  begin
    close_cursor(get_cursor#(p_cursor));
  end;

  function serialize(p_cursor# integer,
                     p_name    varchar2 default null) return xmltype is
  
    n          integer;
    describe   t_describe;
    column     t_column;
    value      t_value;
    doc        dbms_xmldom.DOMDocument;
    rootNode   dbms_xmldom.DOMNode;
    recordNode dbms_xmldom.DOMNode;
    valueNode  dbms_xmldom.DOMNode;
  begin
  
    describe := describe_cursor(p_cursor#);
    define_columns(p_cursor#, describe);
  
    doc := xml.createDoc(rootNode, nvl(p_name, XML_TAG_ROOT));
  
    n := 0;
    loop
      exit when dbms_sql.fetch_rows(p_cursor#) = 0;
    
      inc(n);
      recordNode := xml.createNode(rootNode, XML_TAG_RECORD);
      xml.setAttrValue(recordNode, XML_ATTR_RECNO, n);
    
      for i in 1 .. describe.count loop
      
        column := describe(i);
        value  := get_value(p_cursor#, column);
      
        -- node      
        valueNode := xml.createNode(recordNode, lib_text.lower_camel(column.name));
      
        -- value
        if value.isLob then
          xml.setClob(valueNode, value.lob);
        else
          xml.setText(valueNode, value.text);
        end if;
      
        -- attributes
        xml.setAttrValue(valueNode, 'type', value.typeName);
      
        if column.scale != 0 then
          xml.setAttrValue(valueNode, 'scale', column.scale);
        end if;
      
      end loop;
    end loop;
  
    close_cursor(p_cursor#);
  
    return dbms_xmldom.getxmltype(doc);
  end;

  function serialize(p_cursor in out t_cursor,
                     p_name   varchar2 default null) return xmltype is
    cursor# integer;
  begin
  
    cursor# := dbms_sql.to_cursor_number(p_cursor);
  
    return serialize(cursor#, p_name);
  end;

  function execute_query(p_query varchar2) return integer is
    cursor# integer;
  begin
  
    cursor# := dbms_sql.open_cursor;
  
    dbms_sql.parse(cursor#, p_query, dbms_sql.native);
    callf(dbms_sql.execute(cursor#));
  
    return cursor#;
  end;

  function execute_to_xml(p_query varchar2,
                          p_name  varchar2 default null) return xmltype is
  begin
  
    return serialize(execute_query(p_query), p_name);
  end;

  function parse_as_keyval(p_cursor t_cursor) return types.hash_map is
  
    cursor#  integer;
    describe t_describe;
    key      t_value;
    val      t_value;
    data     types.hash_map;
  begin
  
    cursor#  := get_cursor#(p_cursor);
    describe := describe_cursor(cursor#);
    define_columns(cursor#, describe);
  
    loop
      exit when dbms_sql.fetch_rows(cursor#) = 0;
    
      key := get_value(cursor#, describe(1));
      val := get_value(cursor#, describe(2));
    
      data(key.text) := val.text;
    end loop;
  
    close_cursor(cursor#);
  
    return data;
  end;

  function parse_as_keyval(p_cursor t_cursor,
                           p_name   varchar2) return xmltype is
  
    key  varchar2(1000);
    data types.hash_map;
    doc  dbms_xmldom.DOMDocument;
    root dbms_xmldom.DOMNode;
  begin
  
    data := parse_as_keyval(p_cursor);
  
    doc := xml.createDoc(root, nvl(p_name, XML_TAG_ROOT));
  
    key := data.first;
    while key is not null loop
    
      xml.createNode(root, key, data(key));
      key := data.next(key);
    end loop;
  
    return dbms_xmldom.getxmltype(doc);
  end;

  function parse_to_map_list(p_cursor t_cursor,
                             p_rows#  integer default null) return types.map_list is
  
    n        integer;
    cursor#  integer;
    column   t_column;
    describe t_describe;
    rec      types.hash_map;
    rec_list types.map_list;
    val      t_value;
  begin
  
    cursor#  := get_cursor#(p_cursor);
    describe := describe_cursor(cursor#);
    define_columns(cursor#, describe);
  
    n := 0;
    loop
      exit when dbms_sql.fetch_rows(cursor#) = 0;
    
      inc(n);
      rec.delete;
    
      for i in 1 .. describe.count loop
      
        column := describe(i);
        val := get_value(cursor#, column);
        rec(column.name) := val.text;
      end loop;
    
      rec_list(n) := rec;
    
      exit when n >= p_rows#;
    end loop;
  
    close_cursor(cursor#);
  
    return rec_list;
  end;

  function parse_to_map_list(p_cursor t_cursor,
                             p_name   varchar2,
                             p_rows#  integer default null) return xmltype is
  
    rec      types.hash_map;
    rec_list types.map_list;
    col      varchar2(1000);
    doc      dbms_xmldom.DOMDocument;
    rootNode dbms_xmldom.DOMNode;
    recNode  dbms_xmldom.DOMNode;
  begin
  
    rec_list := parse_to_map_list(p_cursor, p_rows#);
  
    doc := xml.createDoc(rootNode, nvl(p_name, XML_TAG_ROOT));
  
    if p_rows# = 1 then
    
      rec := rec_list(1);
      col := rec.first;
      while col is not null loop
      
        xml.createNode(rootNode, lib_text.lower_camel(col), rec(col));
        col := rec.next(col);
      end loop;
    
    else
    
      for n in 1 .. rec_list.count loop
      
        rec     := rec_list(n);
        recNode := xml.createNode(rootNode, XML_TAG_RECORD);
      
        col := rec.first;
        while col is not null loop
        
          xml.createNode(recNode, lib_text.lower_camel(col), rec(col));
          col := rec.next(col);
        end loop;
      
        xml.setAttrValue(recNode, XML_ATTR_RECNO, n);
      end loop;
    end if;
  
    return dbms_xmldom.getxmltype(doc);
  end;

begin
  init();
end;
/

