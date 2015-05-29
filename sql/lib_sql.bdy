create or replace package body lib_sql is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.07.2013 11:37:59  
  -- Purpose : SQL Reflection Library

  -- dml actions  
  DML_INSERT constant integer := 1;
  DML_UPDATE constant integer := 2;
  DML_DELETE constant integer := 3;

  -- sql types constant
  COL_NUMBER   constant number := null;
  COL_VARCHAR2 constant varchar2(1) := null;
  COL_DATE     constant date := null;
  COL_CHAR     constant char := null;
  COL_BLOB     constant blob := null;
  COL_CLOB     constant clob := null;
  COL_ROWID    constant rowid := null;
  COL_XMLTYPE  constant xmltype := null;

  -- sql types map
  ORA_TYPE   types.hmap_iv;
  ORA_TYPE#  types.hmap_vi;
  JAVA_TYPE  types.hmap_iv;
  JAVA_TYPE# types.hmap_vi;

  -- ora xml tags
  ORA_ROWSET_TAG constant varchar2(100) := dbms_xmlquery.DEFAULT_ROWSETTAG;
  ORA_ROW_TAG    constant varchar2(100) := dbms_xmlquery.DEFAULT_ROWTAG;
  ORA_ROW#_ATTR  constant varchar2(100) := dbms_xmlquery.DEFAULT_ROWIDATTR;

  -- java xml tags
  JAVA_ROWSET_TAG constant varchar2(100) := lower(ORA_ROWSET_TAG);
  JAVA_ROW_TAG    constant varchar2(100) := lower(ORA_ROW_TAG);
  JAVA_ROW#_ATTR  constant varchar2(100) := lower(ORA_ROW#_ATTR);

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
  
    typeId integer;
  begin
  
    -- oracle builtin types
    ORA_TYPE(ORA_NUMBER) := 'NUMBER';
    ORA_TYPE(ORA_VARCHAR2) := 'VARCHAR2';
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
    ORA_TYPE(USER_INTEGER) := 'INTEGER';
    ORA_TYPE(USER_XMLTYPE) := 'XMLTYPE';
    ORA_TYPE(USER_BOOLEAN) := 'BOOLEAN';
  
    -- java compatible types
    JAVA_TYPE(ORA_NUMBER) := 'Number';
    JAVA_TYPE(ORA_VARCHAR2) := 'String';
    JAVA_TYPE(ORA_ROWID) := 'Rowid';
    JAVA_TYPE(ORA_DATE) := 'Date';
    JAVA_TYPE(ORA_RAW) := 'Raw';
    JAVA_TYPE(ORA_LONG_RAW) := 'LongRaw';
    JAVA_TYPE(ORA_CHAR) := 'Char';
    JAVA_TYPE(ORA_BINARY_FLOAT) := 'Float';
    JAVA_TYPE(ORA_BINARY_DOUBLE) := 'Double';
    JAVA_TYPE(ORA_USER_DEFINED) := 'UserDefined';
    JAVA_TYPE(ORA_REF) := 'Ref';
    JAVA_TYPE(ORA_CLOB) := 'Clob';
    JAVA_TYPE(ORA_BLOB) := 'Blob';
    JAVA_TYPE(ORA_TIMESTAMP) := 'Timestamp';
    JAVA_TYPE(USER_INTEGER) := 'Integer';
    JAVA_TYPE(USER_XMLTYPE) := 'XmlType';
    JAVA_TYPE(USER_BOOLEAN) := 'Boolean';
  
    -- reverse arrays
    typeId := ORA_TYPE.first;
    while typeId is not null loop
      ORA_TYPE#(ORA_TYPE(typeId)) := typeId;
      typeId := ORA_TYPE.next(typeId);
    end loop;
  
    typeId := JAVA_TYPE.first;
    while typeId is not null loop
      JAVA_TYPE#(JAVA_TYPE(typeId)) := typeId;
      typeId := JAVA_TYPE.next(typeId);
    end loop;
  end;

  function get_type#(p_name varchar2) return integer is
    type# integer;
  begin
  
    begin
      type# := ORA_TYPE#(p_name);
    
    exception
      when NO_DATA_FOUND then
      
        if type# is null then
          type# := JAVA_TYPE#(p_name);
        end if;
      
      when others then
        raise;
    end;
  
    return type#;
  
  exception
    when NO_DATA_FOUND then
      return null;
    
    when others then
      raise;
  end;

  function get_type_name(p_type# integer) return varchar2 is
  begin
    return ORA_TYPE(p_type#);
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

  function decode_type(p_desc dbms_sql.desc_rec3) return integer is
  begin
  
    if p_desc.col_type = ORA_NUMBER and p_desc.col_scale = 0 then
    
      if lower(p_desc.col_name) like 'is%' then
        return USER_BOOLEAN;
      else
        return USER_INTEGER;
      end if;
    
    elsif p_desc.col_type = ORA_USER_DEFINED and p_desc.col_type_name = ORA_TYPE(USER_XMLTYPE) then
    
      return USER_XMLTYPE;
    
    else
      return p_desc.col_type;
    end if;
  end;

  procedure print_column(p_column t_column,
                         p_index  integer default null) is
    i integer := nvl(p_index, p_column.position);
  begin
  
    lib_log.debug('(%s) name=%s', i, p_column.name);
    lib_log.debug('(%s) type=%s/%s', i, p_column.type#, p_column.ora_type);
    lib_log.debug('(%s) length=%s', i, p_column.length);
    lib_log.debug('(%s) scale=%s', i, p_column.scale);
    lib_log.debug('(%s) is_key=%s', i, to_int(p_column.is_key));
    lib_log.debug('(%s) is_null=%s', i, to_int(p_column.is_null));
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
      column           := null;
      column.position  := q.column_id;
      column.type#     := ORA_TYPE#(q.data_type);
      column.ora_type  := q.data_type;
      column.java_type := JAVA_TYPE(column.type#);
      column.name      := q.column_name;
      column.length    := q.data_length;
      column.scale     := q.data_scale;
      column.is_null   := q.nullable = 'Y';
    
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
    
      column           := null;
      column.position  := i;
      column.type#     := decode_type(desc_rec3);
      column.ora_type  := get_type_name(column.type#);
      column.java_type := JAVA_TYPE(column.type#);
      column.name      := desc_rec3.col_name;
      column.length    := desc_rec3.col_max_len;
      column.scale     := desc_rec3.col_scale;
      column.is_null   := desc_rec3.col_null_ok;
    
      describe.extend;
      describe(i) := column;
    
      print_column(column, i);
    end loop;
  
    return describe;
  end;

  function describe_xml(p_doc xmltype) return t_describe is
  
    doc      dbms_xmldom.DOMDocument;
    root     dbms_xmldom.DOMNode;
    rowList  dbms_xmldom.DOMNodeList;
    colList  dbms_xmldom.DOMNodeList;
    rowNode  dbms_xmldom.DOMNode;
    colNode  dbms_xmldom.DOMNode;
    colName  varchar2(1000);
    colText  varchar2(32767);
    column   t_column;
    describe t_describe := t_describe();
  begin
  
    doc  := lib_xml.createDoc(p_doc);
    root := lib_xml.getRootNode(doc);
  
    lib_log.debug('*** Describe XML <%s> ***', lib_xml.getNodeName(root));
  
    rowList := dbms_xmldom.getChildNodes(root);
  
    -- rows
    for r in 0 .. dbms_xmldom.getLength(rowList) - 1 loop
    
      rowNode := dbms_xmldom.item(rowList, r);
      colList := dbms_xmldom.getChildNodes(rowNode);
    
      -- columns
      for c in 0 .. dbms_xmldom.getLength(colList) - 1 loop
      
        colNode := dbms_xmldom.item(colList, c);
        colName := lib_xml.getNodeName(colNode);
        colText := lib_xml.getText(colNode);
      
        -- column record
        column           := null;
        column.position  := c + 1;
        column.java_type := lib_xml.getAttrValue(colNode, 'type');
      
        if column.java_type is not null then
          column.type#    := get_type#(column.java_type);
          column.ora_type := get_type_name(column.type#);
        end if;
      
        -- if column type is not recognized
        if column.type# is null then
        
          if lower(colName) like 'is%' and lib_xml.toBool(colText) is not null then
            column.type# := USER_BOOLEAN;
          elsif lower(colName) like '%date%' and colText like '____-__-__T%' then
            column.type# := ORA_DATE;
          else
            column.type# := ORA_VARCHAR2;
          end if;
        
          column.ora_type := get_type_name(column.type#);
        end if;
      
        column.name   := colName;
        column.length := lib_xml.getAttrValue(colNode, 'length');
        column.scale  := lib_xml.getAttrValue(colNode, 'scale');
      
        describe.extend;
        describe(column.position) := column;
      
        print_column(column);
      end loop;
    
      exit;
    end loop;
  
    return describe;
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
                      p_col_name varchar2) return boolean is
  begin
  
    for i in 1 .. p_describe.count loop
    
      if p_describe(i).name = p_col_name then
        return true;
      end if;
    end loop;
  
    return false;
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

  procedure define_column(p_cursor#  integer,
                          p_column   t_column,
                          p_position integer default null) is
  
    i integer := nvl(p_position, p_column.position);
  begin
  
    if p_column.type# = ORA_VARCHAR2 then
      dbms_sql.define_column(p_cursor#, i, COL_VARCHAR2, p_column.length);
    elsif p_column.type# in (ORA_NUMBER, USER_INTEGER, USER_BOOLEAN) then
      dbms_sql.define_column(p_cursor#, i, COL_NUMBER);
    elsif p_column.type# = ORA_DATE then
      dbms_sql.define_column(p_cursor#, i, COL_DATE);
    elsif p_column.type# = ORA_BLOB then
      dbms_sql.define_column(p_cursor#, i, COL_BLOB);
    elsif p_column.type# = ORA_CLOB then
      dbms_sql.define_column(p_cursor#, i, COL_CLOB);
    elsif p_column.type# = ORA_CHAR then
      dbms_sql.define_column_char(p_cursor#, i, COL_CHAR, p_column.length);
    elsif p_column.type# = ORA_ROWID then
      dbms_sql.define_column_rowid(p_cursor#, i, COL_ROWID);
    elsif p_column.type# = USER_XMLTYPE then
      dbms_sql.define_column(p_cursor#, i, COL_XMLTYPE);
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
  
    check_type(p_column.type#, ORA_VARCHAR2);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => string_value);
    return string_value;
  end;

  function get_number(p_cursor# integer,
                      p_column  t_column) return number is
  
    number_value number;
  begin
  
    check_type(p_column.type#, ORA_NUMBER, USER_INTEGER, USER_BOOLEAN);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => number_value);
    return number_value;
  end;

  function get_integer(p_cursor# integer,
                       p_column  t_column) return integer is
  
    int_value number;
  begin
  
    check_type(p_column.type#, USER_INTEGER, USER_BOOLEAN);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => int_value);
    return int_value;
  end;

  function get_boolean(p_cursor# integer,
                       p_column  t_column) return boolean is
  
    bool_value number;
  begin
  
    check_type(p_column.type#, USER_BOOLEAN);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => bool_value);
    return bool_value != 0;
  end;

  function get_date(p_cursor# integer,
                    p_column  t_column) return date is
  
    date_value date;
  begin
  
    check_type(p_column.type#, ORA_DATE);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => date_value);
    return date_value;
  end;

  function get_char(p_cursor# integer,
                    p_column  t_column) return char is
  
    char_value char;
  begin
  
    check_type(p_column.type#, ORA_CHAR);
  
    dbms_sql.column_value_char(c => p_cursor#, position => p_column.position, value => char_value);
    return char_value;
  end;

  function get_blob(p_cursor# integer,
                    p_column  t_column) return blob is
  
    blob_value blob;
  begin
  
    check_type(p_column.type#, ORA_BLOB);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => blob_value);
    return blob_value;
  end;

  function get_clob(p_cursor# integer,
                    p_column  t_column) return clob is
  
    clob_value    clob;
    string_value  varchar2(32767);
    xmltype_value xmltype;
  begin
  
    check_type(p_column.type#, ORA_BLOB, USER_XMLTYPE);
  
    if p_column.type# = ORA_CLOB then
    
      dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => clob_value);
      return clob_value;
    
    elsif p_column.type# = ORA_VARCHAR2 then
    
      dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => string_value);
      return string_value;
    
    elsif p_column.type# = USER_XMLTYPE then
    
      dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => xmltype_value);
    
      if xmltype_value is not null then
        return xmltype_value.getclobval;
      else
        return null;
      end if;
    
    else
      throw('[%s] Column type is not CLOB compatible', p_column.ora_type);
    end if;
  end;

  function get_rowid(p_cursor# integer,
                     p_column  t_column) return rowid is
  
    rowid_value rowid;
  begin
  
    check_type(p_column.type#, ORA_ROWID);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => rowid_value);
    return rowid_value;
  end;

  function get_xmltype(p_cursor# integer,
                       p_column  t_column) return xmltype is
  
    xmltype_value xmltype;
  begin
  
    check_type(p_column.type#, USER_XMLTYPE);
  
    dbms_sql.column_value(c => p_cursor#, position => p_column.position, value => xmltype_value);
    return xmltype_value;
  end;

  function get_value(p_cursor# integer,
                     p_column  t_column) return t_value is
    value t_value;
  begin
  
    value.type#     := p_column.type#;
    value.ora_type  := p_column.ora_type;
    value.java_type := p_column.java_type;
  
    if p_column.type# = ORA_VARCHAR2 then
    
      value.text := get_string(p_cursor#, p_column);
    
    elsif p_column.type# = ORA_NUMBER then
    
      value.text := lib_xml.xmlNumber(get_number(p_cursor#, p_column));
    
    elsif p_column.type# = USER_INTEGER then
    
      value.text := get_integer(p_cursor#, p_column);
    
    elsif p_column.type# = USER_BOOLEAN then
    
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
    
    elsif p_column.type# in (ORA_CLOB, USER_XMLTYPE) then
    
      value.lob    := get_clob(p_cursor#, p_column);
      value.is_lob := true;
    
    else
      throw('[%s] Unsupported column type', p_column.type#, p_column.ora_type);
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
  
    doc := lib_xml.createDoc(rootNode, nvl(p_name, JAVA_ROWSET_TAG));
  
    n := 0;
    loop
      exit when dbms_sql.fetch_rows(p_cursor#) = 0;
    
      inc(n);
      recordNode := lib_xml.createNode(rootNode, JAVA_ROW_TAG);
      lib_xml.setAttrValue(recordNode, JAVA_ROW#_ATTR, n);
    
      for i in 1 .. describe.count loop
      
        column := describe(i);
        value  := get_value(p_cursor#, column);
      
        -- node      
        valueNode := lib_xml.createNode(recordNode, lib_text.lower_camel(column.name));
      
        -- value
        if value.is_lob then
          lib_xml.setClob(valueNode, value.lob);
        else
          lib_xml.setText(valueNode, value.text);
        end if;
      
        -- attributes
        lib_xml.setAttrValue(valueNode, 'type', value.java_type);
      
        if column.scale != 0 then
          lib_xml.setAttrValue(valueNode, 'scale', column.scale);
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
  
    doc := lib_xml.createDoc(root, nvl(p_name, JAVA_ROWSET_TAG));
  
    key := data.first;
    while key is not null loop
    
      lib_xml.createNode(root, key, data(key));
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
  
    doc := lib_xml.createDoc(rootNode, nvl(p_name, JAVA_ROWSET_TAG));
  
    if p_rows# = 1 then
    
      rec := rec_list(1);
      col := rec.first;
      while col is not null loop
      
        lib_xml.createNode(rootNode, lib_text.lower_camel(col), rec(col));
        col := rec.next(col);
      end loop;
    
    else
    
      for n in 1 .. rec_list.count loop
      
        rec     := rec_list(n);
        recNode := lib_xml.createNode(rootNode, JAVA_ROW_TAG);
      
        col := rec.first;
        while col is not null loop
        
          lib_xml.createNode(recNode, lib_text.lower_camel(col), rec(col));
          col := rec.next(col);
        end loop;
      
        lib_xml.setAttrValue(recNode, JAVA_ROW#_ATTR, n);
      end loop;
    end if;
  
    return dbms_xmldom.getxmltype(doc);
  end;

  -- SQL-совместимое содержимое ноды 
  function xml_value(p_node   dbms_xmldom.DOMNode,
                     p_column in out t_column) return varchar2 is
  
    colName varchar2(1000);
    colText varchar2(32767);
  begin
  
    colName := lib_xml.getNodeName(p_node);
    colText := lib_xml.getText(p_node);
  
    if colText is not null then
    
      if p_column.type# = USER_BOOLEAN then
        return to_int(lib_xml.toBool(colText));
      elsif p_column.type# = ORA_DATE then
        return lib_xml.toDateTime(colText);
      elsif p_column.type# in (ORA_NUMBER, USER_INTEGER) then
        return lib_xml.toNumber(colText);
      elsif p_column.type# is null then
      
        if lower(colName) like 'is%' and lib_xml.toBool(colText) is not null then
          p_column.type# := USER_BOOLEAN;
          return to_int(lib_xml.toBool(colText));
        elsif lower(colName) like '%date%' and colText like '____-__-__T' then
          p_column.type# := ORA_DATE;
          return lib_xml.toDate(colText);
        elsif lower(colName) like '%date%' and colText like '____-__-__T%' then
          p_column.type# := ORA_DATE;
          return lib_xml.toDateTime(colText);
        end if;
      end if;
    
      return colText;
    
    else
      return null;
    end if;
  end;

  function xml_uncamel(p_doc xmltype) return xmltype is
  
    col      t_column;
    descr    t_describe;
    doc      dbms_xmldom.DOMDocument;
    doc2     dbms_xmldom.DOMDocument;
    root     dbms_xmldom.DOMNode;
    root2    dbms_xmldom.DOMNode;
    rowList  dbms_xmldom.DOMNodeList;
    colList  dbms_xmldom.DOMNodeList;
    rowNode  dbms_xmldom.DOMNode;
    rowNode2 dbms_xmldom.DOMNode;
    colNode  dbms_xmldom.DOMNode;
  begin
  
    descr := describe_xml(p_doc);
  
    if descr is not null then
    
      doc  := lib_xml.createDoc(p_doc);
      root := lib_xml.getRootNode(doc);
    
      doc2    := lib_xml.createDoc(root2, ORA_ROWSET_TAG);
      rowList := dbms_xmldom.getChildNodes(root);
    
      -- rows
      for r in 0 .. dbms_xmldom.getLength(rowList) - 1 loop
      
        rowNode  := dbms_xmldom.item(rowList, r);
        rowNode2 := lib_xml.createNode(root2, ORA_ROW_TAG);
        colList  := dbms_xmldom.getChildNodes(rowNode);
      
        -- columns
        for c in 1 .. descr.count loop
        
          col     := descr(c);
          colNode := dbms_xmldom.item(colList, col.position - 1);
          lib_xml.createNode(rowNode2, lib_text.uncamel(col.name), xml_value(colNode, col));
        end loop;
      end loop;
    
    end if;
  
    return dbms_xmldom.getxmltype(doc2);
  end;

  -- сохранить в таблицу 
  function xml_store(p_doc    xmltype,
                     p_table  varchar2,
                     p_key    varchar2 default null,
                     p_action integer default DML_INSERT) return integer is
  
    doc      xmltype;
    ctx      dbms_xmlstore.ctxType;
    cols#    integer;
    rows#    integer;
    col      t_column;
    xml_desc t_describe;
    tab_desc t_describe;
  begin
  
    doc := xml_uncamel(p_doc);
  
    if lib_log.is_debug then
      lib_log.debug('*** UnCameled XML ***');
      lib_xml.print(doc);
    end if;
  
    xml_desc := describe_xml(doc);
    tab_desc := describe_table(p_table);
  
    -- xmlstore context
    ctx := dbms_xmlstore.newContext(p_table);
    dbms_xmlstore.clearKeyColumnList(ctx);
    dbms_xmlstore.clearUpdateColumnList(ctx);
  
    -- row tag
    dbms_xmlstore.setRowTag(ctx, ORA_ROW_TAG);
  
    -- data columns
    if p_action in (DML_INSERT, DML_UPDATE) then
      cols# := 0;
      for i in 1 .. xml_desc.count loop
      
        col := xml_desc(i);
      
        if has_column(tab_desc, col) then
        
          lib_log.debug('Common column: %s', col.name);
        
          inc(cols#);
          dbms_xmlstore.setUpdateColumn(ctx, col.name);
        end if;
      end loop;
    
      if cols# = 0 then
        throw('There are no common columns in xml and table');
      end if;
    end if;
  
    -- key column(s)
    if p_action in (DML_UPDATE, DML_DELETE) then
    
      if p_key is not null then
      
        col.name := lib_text.uncamel(p_key);
        lib_log.debug('Key column: %s', col.name);
        dbms_xmlstore.setKeyColumn(ctx, col.name);
      
      else
      
        cols# := 0;
        for i in 1 .. tab_desc.count loop
        
          col := tab_desc(i);
        
          if col.is_key then
          
            lib_log.debug('Key column: %s', col.name);
          
            inc(cols#);
            dbms_xmlstore.setKeyColumn(ctx, col.name);
          end if;
        end loop;
      
        if cols# = 0 then
          throw('There are no key columns for update/delete operation');
        end if;
      end if;
    end if;
  
    -- call dml
    if p_action = DML_INSERT then
    
      rows# := dbms_xmlstore.insertXML(ctx, doc);
      lib_log.debug('%d row(s) inserted', rows#);
    
    elsif p_action = DML_UPDATE then
    
      rows# := dbms_xmlstore.updateXML(ctx, doc);
      lib_log.debug('%d row(s) updated', rows#);
    
    elsif p_action = DML_DELETE then
    
      rows# := dbms_xmlstore.deleteXML(ctx, doc);
      lib_log.debug('%d row(s) deleted', rows#);
    
    else
      throw('Invalid DML action (%s)', p_action);
    end if;
  
    -- close the context
    dbms_xmlstore.closeContext(ctx);
  
    return rows#;
  
  exception
    when others then
    
      lib_log.debug(sqlerrm);
      lib_log.debug(dbms_utility.format_error_backtrace);
    
      if ctx is not null then
        dbms_xmlstore.closeContext(ctx);
      end if;
    
      raise;
  end;

  -- вставить записи в таблицу 
  function xml_insert(p_doc   xmltype,
                      p_table varchar2) return integer is
  begin
  
    return xml_store(p_doc => p_doc, p_table => p_table, p_action => DML_INSERT);
  end;

  -- обновить записи в таблице
  function xml_update(p_doc   xmltype,
                      p_table varchar2,
                      p_key   varchar2 default null) return integer is
  begin
  
    return xml_store(p_doc => p_doc, p_table => p_table, p_key => p_key, p_action => DML_UPDATE);
  end;

  -- удалить записи из таблицы
  function xml_delete(p_doc   xmltype,
                      p_table varchar2,
                      p_key   varchar2 default null) return integer is
  begin
    return xml_store(p_doc => p_doc, p_table => p_table, p_key => p_key, p_action => DML_DELETE);
  end;

begin
  init();
end;
/

