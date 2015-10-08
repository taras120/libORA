create or replace package body lib_xsql is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.07.2013 11:37:59
  -- Purpose : XML SQL Reflection Library

  -- dml actions
  DML_INSERT constant integer := 1;
  DML_UPDATE constant integer := 2;
  DML_DELETE constant integer := 3;

  -- ora xml tags
  TAG_ROW     constant varchar2(100) := lower(dbms_xmlquery.DEFAULT_ROWTAG);
  TAG_ROWSET  constant varchar2(100) := lower(dbms_xmlquery.DEFAULT_ROWSETTAG);
  TAG_RESULT  constant varchar2(100) := 'result';
  TAG_RESULTS constant varchar2(100) := 'results';
  ATTR_ROW#   constant varchar2(100) := lower(dbms_xmlquery.DEFAULT_ROWIDATTR);
  ATTR_TYPE   constant varchar2(100) := 'type';
  ATTR_SCALE  constant varchar2(100) := 'scale';
  ATTR_LENGTH constant varchar2(100) := 'length';

  -- xml datatypes map
  XML_TYPE# types.IntegerMap;

  procedure init is
  begin

    -- XMLSchema types
    XML_TYPE#(lib_xml.XS_INT) := lib_sql.PLS_INTEGER;
    XML_TYPE#(lib_xml.XS_BOOLEAN) := lib_sql.PLS_BOOLEAN;
    XML_TYPE#(lib_xml.XS_STRING) := lib_sql.ORA_VARCHAR2;
    XML_TYPE#(lib_xml.XS_DOUBLE) := lib_sql.ORA_NUMBER;
    XML_TYPE#(lib_xml.XS_FLOAT) := lib_sql.ORA_NUMBER;
    XML_TYPE#(lib_xml.XS_DECIMAL) := lib_sql.ORA_NUMBER;
    XML_TYPE#(lib_xml.XS_DATETIME) := lib_sql.ORA_DATE;
    XML_TYPE#(lib_xml.XS_DATE) := lib_sql.ORA_DATE;

    -- Oracle specific types
    XML_TYPE#('clob') := lib_sql.ORA_CLOB;
    XML_TYPE#('blob') := lib_sql.ORA_BLOB;
    XML_TYPE#('timestamp') := lib_sql.ORA_TIMESTAMP;
    XML_TYPE#('xmltype') := lib_sql.UDT_XMLTYPE;
  end;

  function get_type#(p_name varchar2) return integer is
  begin

    begin

      return XML_TYPE#(p_name);

    exception
      when NO_DATA_FOUND then

        return lib_sql.get_type#(p_name);
    end;

  exception
    when NO_DATA_FOUND then

      return null;

    when others then
      lib_log.print_stack;
      raise;
  end;

  function get_xml_type(p_type# integer,
                        p_value varchar2 default null) return varchar2 is

    xs_types   types.StringList;
    date_value date;
    number_value number;
  begin

    begin

      xs_types := lib_map.keys_by_value(XML_TYPE#, p_type#);

      if xs_types.count = 0 then

        raise NO_DATA_FOUND;

      elsif xs_types.count = 1 then

        return xs_types(1);

      elsif p_type# = lib_sql.ORA_DATE and p_value is not null then

        date_value := lib_xml.toDateTime(p_value);

        if date_value = trunc(date_value) then
          return /*lib_xml.XS_DATE;*/ lib_xml.XS_DATETIME;
        else
          return lib_xml.XS_DATETIME;
        end if;

      elsif p_type# = lib_sql.ORA_NUMBER and p_value is not null then

        number_value := lib_xml.toNumber(p_value);

        if length(to_char(number_value - trunc(number_value))) > 8 then
          return lib_xml.XS_DECIMAL;
        else
          return lib_xml.XS_DOUBLE;
        end if;

      else
        return xs_types(1); -- default type
      end if;

    exception
      when NO_DATA_FOUND then

        return lib_sql.get_ora_type(p_type#);
    end;

  exception
    when NO_DATA_FOUND then

      return null;

    when others then
      lib_log.print_stack;
      raise;
  end;

  function serialize#(p_cursor# integer,
                      p_name    varchar2 default null,
                      b_close   boolean default true) return xmltype is

    n          integer;
    describe   lib_sql.t_describe;
    column     lib_sql.t_column;
    value      lib_sql.t_value;
    doc        dbms_xmldom.DOMDocument;
    rootNode   dbms_xmldom.DOMNode;
    recordNode dbms_xmldom.DOMNode;
    valueNode  dbms_xmldom.DOMNode;
  begin

    describe := lib_sql.describe_cursor(p_cursor#);
    lib_sql.define_columns(p_cursor#, describe);

    doc := lib_xml.createDoc(rootNode, nvl(p_name, TAG_ROWSET));

    n := 0;
    loop
      exit when dbms_sql.fetch_rows(p_cursor#) = 0;

      inc(n);
      recordNode := lib_xml.createNode(rootNode, TAG_ROW);
      lib_xml.setAttrValue(recordNode, ATTR_ROW#, n);

      for i in 1 .. describe.count loop

        column := describe(i);
        value  := lib_sql.get_value(p_cursor#, column);

        -- node
        valueNode := lib_xml.createNode(recordNode, lib_text.lower_camel(column.name));

        -- value
        if value.is_lob then
          lib_xml.setClob(valueNode, value.lob);
        else
          lib_xml.setText(valueNode, value.text);
        end if;

        -- attributes
        value.xml_type := get_xml_type(value.type#);

        if value.xml_type is not null then
          lib_xml.setAttrValue(valueNode, ATTR_TYPE, value.xml_type);
        end if;

        if column.scale != 0 then
          lib_xml.setAttrValue(valueNode, ATTR_SCALE, column.scale);
        end if;

      end loop;
    end loop;

    if b_close then
      lib_sql.close_cursor(p_cursor#);
    end if;

    return dbms_xmldom.getxmltype(doc);
  end;

  function serialize(p_cursor in out t_cursor,
                     p_name   varchar2 default null,
                     b_close  boolean default true) return xmltype is
    cursor# integer;
  begin

    cursor# := dbms_sql.to_cursor_number(p_cursor);

    return serialize#(p_cursor# => cursor#, p_name => p_name, b_close => b_close);
  end;

  function fetch_as_keyval(p_cursor t_cursor,
                           p_name   varchar2 default null,
                           b_close  boolean default true) return xmltype is

    key  varchar2(1000);
    data types.hashmap;
    doc  dbms_xmldom.DOMDocument;
    root dbms_xmldom.DOMNode;
  begin

    data := lib_sql.fetch_as_keyval(p_cursor => p_cursor, b_close => b_close);

    doc := lib_xml.createDoc(root, nvl(p_name, TAG_ROWSET));

    key := data.first;
    while key is not null loop

      lib_xml.createNode(root, key, data(key));
      key := data.next(key);
    end loop;

    return dbms_xmldom.getxmltype(doc);
  end;

  function fetch_as_rowset(p_cursor t_cursor,
                           p_name   varchar2,
                           p_rows#  integer default null,
                           b_close  boolean default true) return xmltype is

    rec      lib_sql.t_row;
    rowset   lib_sql.t_rowset;
    col      varchar2(30);
    doc      dbms_xmldom.DOMDocument;
    rootNode dbms_xmldom.DOMNode;
    recNode  dbms_xmldom.DOMNode;
  begin

    rowset := lib_sql.fetch_as_rowset(p_cursor => p_cursor, p_rows# => p_rows#, b_close => b_close);

    doc := lib_xml.createDoc(rootNode, nvl(p_name, TAG_ROWSET));

    if p_rows# = 1 then

      rec := rowset(1);
      col := rec.first;
      while col is not null loop

        lib_xml.createNode(rootNode, lib_text.lower_camel(col), rec(col));
        col := rec.next(col);
      end loop;

    else

      for n in 1 .. rowset.count loop

        rec     := rowset(n);
        recNode := lib_xml.createNode(rootNode, TAG_ROW);

        col := rec.first;
        while col is not null loop

          lib_xml.createNode(recNode, lib_text.lower_camel(col), rec(col));
          col := rec.next(col);
        end loop;

        lib_xml.setAttrValue(recNode, ATTR_ROW#, n);
      end loop;
    end if;

    return dbms_xmldom.getxmltype(doc);
  end;

  function describe_xml(p_doc xmltype) return lib_sql.t_describe is

    doc      dbms_xmldom.DOMDocument;
    root     dbms_xmldom.DOMNode;
    rowList  dbms_xmldom.DOMNodeList;
    colList  dbms_xmldom.DOMNodeList;
    rowNode  dbms_xmldom.DOMNode;
    colNode  dbms_xmldom.DOMNode;
    colName  varchar2(1000);
    colText  varchar2(32767);
    column   lib_sql.t_column;
    describe lib_sql.t_describe := lib_sql.t_describe();
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

        if not lib_sql.has_column(describe, colName) then

          colText := lib_xml.getText(colNode);

          -- column record
          column          := null;
          column.pos#     := c + 1;
          column.xml_type := lib_xml.getAttrValue(colNode, ATTR_TYPE);

          if column.xml_type is not null then
            column.type#    := get_type#(column.xml_type);
            column.ora_type := lib_sql.get_ora_type(column.type#);
          end if;

          -- if column type is not recognized
          if column.type# is null then

            if lower(colName) like 'is%' and lib_xml.toBool(colText) is not null then

              column.type# := lib_sql.PLS_BOOLEAN;

            elsif lower(colName) like '%date%' or colText like '____-__-__%' then

              begin

                if lib_xml.toDate(colText) is not null then
                  column.type# := lib_sql.ORA_DATE;
                else
                  throw('date not recognized');
                end if;

              exception
                when others then
                  column.type# := lib_sql.ORA_VARCHAR2;
              end;

            else
              column.type# := lib_sql.ORA_VARCHAR2;
            end if;

            column.ora_type := lib_sql.get_ora_type(column.type#);
          end if;

          column.name   := colName;
          column.scale  := lib_xml.getAttrValue(colNode, ATTR_SCALE);
          column.length := lib_xml.getAttrValue(colNode, ATTR_LENGTH);

          describe.extend;
          describe(column.pos#) := column;

          lib_sql.print_column(column);
        end if;
      end loop;

      exit; -- 1st row is enough
    end loop;

    return describe;
  end;

  -- SQL-совместимое содержимое ноды
  function get_value(p_node  dbms_xmldom.DOMNode,
                     p_type# integer) return varchar2 is

    colText varchar2(32767);
  begin

    colText := lib_xml.getText(p_node);

    if p_type# is not null then

      if p_type# = lib_sql.PLS_BOOLEAN then

        return to_int(lib_xml.toBool(colText));

      elsif p_type# = lib_sql.ORA_DATE then

        return lib_xml.toDateTime(colText);

      elsif p_type# in (lib_sql.ORA_NUMBER, lib_sql.PLS_INTEGER) then

        return lib_xml.toNumber(colText);

      else
        return colText;
      end if;

    else
      return colText;
    end if;
  end;

  procedure camelize(oldNode dbms_xmldom.DOMNode,
                     newNode dbms_xmldom.DOMNode) is

    childList dbms_xmldom.DOMNodeList;
    oldChild  dbms_xmldom.DOMNode;
    newChild  dbms_xmldom.DOMNode;
    childName varchar2(1000);
  begin

    childList := dbms_xmldom.getChildNodes(oldNode);

    -- rows
    for i in 0 .. dbms_xmldom.getLength(childList) - 1 loop

      oldChild  := dbms_xmldom.item(childList, i);
      childName := lib_xml.getNodeName(oldChild);

      if dbms_xmldom.getNodeType(oldChild) = dbms_xmldom.TEXT_NODE then

        lib_xml.setText(newNode, dbms_xmldom.getNodeValue(oldChild));

      else

        newChild := lib_xml.createNode(newNode, lib_text.lower_camel(childName));

        if dbms_xmldom.hasChildNodes(oldChild) then
          camelize(oldChild, newChild);
        end if;
      end if;
    end loop;

  end;

  function camelize(p_doc xmltype) return xmltype is

    doc      dbms_xmldom.DOMDocument;
    newDoc   dbms_xmldom.DOMDocument;
    root     dbms_xmldom.DOMNode;
    newRoot  dbms_xmldom.DOMNode;
    rootName varchar2(1000);
  begin

    doc      := lib_xml.createDoc(p_doc);
    root     := lib_xml.getRootNode(doc);
    rootName := lib_xml.getNodeName(root);

    newDoc := lib_xml.createDoc(newRoot, lib_text.lower_camel(rootName));
    camelize(root, newRoot);

    return dbms_xmldom.getxmltype(newDoc);
  end;

  procedure camelize$(oldNode dbms_xmldom.DOMNode,
                      newNode dbms_xmldom.DOMNode) is

    childList dbms_xmldom.DOMNodeList;
    oldChild  dbms_xmldom.DOMNode;
    newChild  dbms_xmldom.DOMNode;
    childName varchar2(1000);
  begin

    childList := dbms_xmldom.getChildNodes(oldNode);

    -- rows
    for i in 0 .. dbms_xmldom.getLength(childList) - 1 loop

      oldChild  := dbms_xmldom.item(childList, i);
      childName := lib_xml.getNodeName(oldChild);

      if dbms_xmldom.getNodeType(oldChild) = dbms_xmldom.TEXT_NODE then

        lib_xml.setClob(newNode, lib_xml.getClob(oldChild));

      else

        newChild := lib_xml.createNode(newNode, lib_text.lower_camel(childName));

        if dbms_xmldom.hasChildNodes(oldChild) then
          camelize$(oldChild, newChild);
        end if;
      end if;
    end loop;

  end;

  function camelize$(p_doc xmltype) return xmltype is

    doc      dbms_xmldom.DOMDocument;
    newDoc   dbms_xmldom.DOMDocument;
    root     dbms_xmldom.DOMNode;
    newRoot  dbms_xmldom.DOMNode;
    rootName varchar2(1000);
  begin

    doc      := lib_xml.createDoc(p_doc);
    root     := lib_xml.getRootNode(doc);
    rootName := lib_xml.getNodeName(root);

    newDoc := lib_xml.createDoc(newRoot, lib_text.lower_camel(rootName));
    camelize$(root, newRoot);

    return dbms_xmldom.getxmltype(newDoc);
  end;

  function decamelize(p_doc xmltype) return xmltype is

    col      lib_sql.t_column;
    descr    lib_sql.t_describe;
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

      doc2    := lib_xml.createDoc(root2, TAG_ROWSET);
      rowList := dbms_xmldom.getChildNodes(root);

      -- rows
      for r in 0 .. dbms_xmldom.getLength(rowList) - 1 loop

        rowNode  := dbms_xmldom.item(rowList, r);
        rowNode2 := lib_xml.createNode(root2, TAG_ROW);
        colList  := dbms_xmldom.getChildNodes(rowNode);

        -- columns
        for c in 0 .. dbms_xmldom.getLength(colList) - 1 loop

          colNode := dbms_xmldom.item(colList, c);
          col     := lib_sql.get_column(descr, lib_xml.getNodeName(colNode));

          lib_xml.createNode(rowNode2, lib_text.uncamel(col.name), get_value(colNode, col.type#));
        end loop;
      end loop;

    end if;

    return dbms_xmldom.getxmltype(doc2);
  end;

  -- сохранить в таблицу
  function store_xml(p_doc    xmltype,
                     p_table  varchar2,
                     p_key    varchar2 default null,
                     p_action integer default DML_INSERT) return integer is

    doc      xmltype;
    ctx      dbms_xmlstore.ctxType;
    cols#    integer;
    rows#    integer;
    col      lib_sql.t_column;
    xml_desc lib_sql.t_describe;
    tab_desc lib_sql.t_describe;
  begin

    doc := decamelize(p_doc);

    if lib_log.is_debug then
      lib_log.debug('*** UN_CAMELED_XML ***');
      lib_xml.print(doc);
    end if;

    xml_desc := describe_xml(doc);
    tab_desc := lib_sql.describe_table(p_table);

    -- xmlstore context
    ctx := dbms_xmlstore.newContext(p_table);
    dbms_xmlstore.clearKeyColumnList(ctx);
    dbms_xmlstore.clearUpdateColumnList(ctx);

    -- row tag
    dbms_xmlstore.setRowTag(ctx, TAG_ROW);

    -- data columns
    if p_action in (DML_INSERT, DML_UPDATE) then

      cols# := 0;
      for i in 1 .. xml_desc.count loop

        col := xml_desc(i);

        if lib_sql.has_column(tab_desc, col) then

          lib_log.debug('Common column: %s(%s)', col.name, col.ora_type);

          inc(cols#);
          dbms_xmlstore.setUpdateColumn(ctx, col.name);
        end if;

      --  exit when i >= 17;
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
  function insert_xml(p_doc   xmltype,
                      p_table varchar2) return integer is
  begin

    return store_xml(p_doc => p_doc, p_table => p_table, p_action => DML_INSERT);
  end;

  -- обновить записи в таблице
  function update_xml(p_doc   xmltype,
                      p_table varchar2,
                      p_key   varchar2 default null) return integer is
  begin

    return store_xml(p_doc => p_doc, p_table => p_table, p_key => p_key, p_action => DML_UPDATE);
  end;

  -- удалить записи из таблицы
  function delete_xml(p_doc   xmltype,
                      p_table varchar2,
                      p_key   varchar2 default null) return integer is
  begin
    return store_xml(p_doc => p_doc, p_table => p_table, p_key => p_key, p_action => DML_DELETE);
  end;

  -- parse arguments
  function parse_arguments(p_xargs xmltype) return lib_sql.t_values is

    doc       dbms_xmldom.DOMDocument;
    root      dbms_xmldom.DOMNode;
    argNode   dbms_xmldom.DOMNode;
    argList   dbms_xmldom.DOMNodeList;
    firstNode dbms_xmldom.DOMNode;
    lastNode  dbms_xmldom.DOMNode;
    args#     integer;
    bindBy#   boolean;
    arg       lib_sql.t_value;
    args      lib_sql.t_values;
  begin

    if p_xargs is not null then

      doc     := lib_xml.createDoc(p_xargs);
      root    := lib_xml.getRootNode(doc);
      argList := dbms_xmldom.getChildNodes(root);
      args#   := dbms_xmldom.getLength(argList);

      if args# > 1 then

        firstNode := dbms_xmldom.item(argList, 0);
        lastNode  := dbms_xmldom.item(argList, args# - 1);

        bindBy# := lib_xml.getNodeName(firstNode) = lib_xml.getNodeName(lastNode);
      else
        bindBy# := true;
      end if;

      for i in 1 .. args# loop

        arg     := null;
        argNode := dbms_xmldom.item(argList, i - 1);

        -- read
        if lib_xml.isTextNode(argNode) then

          arg.xml_type := lib_xml.getAttrValue(argNode, ATTR_TYPE);

          if instr(arg.xml_type, ':') != 0 then
            arg.xml_type := lib_text.split(arg.xml_type, ':') (2);
          end if;

          if arg.xml_type is not null then
            arg.type# := get_type#(arg.xml_type);
          end if;

          arg.text := get_value(argNode, arg.type#);

        else

          arg.lob    := lib_xml.serialize(lib_xml.createDoc(argNode));
          arg.is_lob := true;
          arg.type#  := lib_sql.UDT_XMLTYPE;
        end if;

        -- store to args map
        if bindBy# then
          args(i) := arg;
        else
          args(lib_xml.getNodeName(argNode)) := arg;
        end if;

      end loop;
    end if;

    return args;
  end;

  procedure serialize_result(p_node   dbms_xmldom.DOMNode,
                             p_result lib_sql.t_value) is
  begin

    if p_result.is_lob then
      lib_xml.setClob(p_node, p_result.lob);
    else
      lib_xml.setText(p_node, p_result.text);
    end if;

    if p_result.xml_type is not null then
      lib_xml.setAttrValue(p_node, ATTR_TYPE, p_result.xml_type);
    elsif p_result.type# is not null then
      lib_xml.setAttrValue(p_node, ATTR_TYPE, get_xml_type(p_result.type#, p_result.text));
    end if;
  end;

  -- result serializer
  function serialize_result(p_result lib_sql.t_value) return xmltype is

    doc  dbms_xmldom.DOMDocument;
    root dbms_xmldom.DOMNode;
  begin

    doc := lib_xml.createDoc(root, TAG_RESULT);

    serialize_result(root, p_result);

    return dbms_xmldom.getxmltype(doc);
  end;

  -- resultset serializer
  function serialize_results(p_results lib_sql.t_values) return xmltype is

    key  varchar2(100);
    doc  dbms_xmldom.DOMDocument;
    root dbms_xmldom.DOMNode;
    node dbms_xmldom.DOMNode;
  begin

    doc := lib_xml.createDoc(root, TAG_RESULTS);

    if p_results.count != 0 then

      key := p_results.first;
      while key is not null loop

        node := lib_xml.createNode(root, key);
        serialize_result(node, p_results(key));

        key := p_results.next(key);
      end loop;
    end if;

    return dbms_xmldom.getxmltype(doc);
  end;

  function serialize_and_camelize(p_results lib_sql.t_values) return xmltype is

    key    varchar2(1000);
    is_lob boolean := false;
  begin

    key := p_results.first;
    while key is not null loop

      is_lob := p_results(key).is_lob;
      exit when is_lob;

      key := p_results.next(key);
    end loop;

    if is_lob then
      return camelize$(serialize_results(p_results));
    else
      return camelize(serialize_results(p_results));
    end if;
  end;

  function execute_query(p_stmt varchar2,
                         p_name varchar2 default null) return xmltype is
    cursor# integer;
  begin

    cursor# := lib_sql.execute_query#(p_stmt);

    return serialize#(p_cursor# => cursor#, p_name => p_name, b_close => true);
  end;

  function execute_query(p_stmt  varchar2,
                         p_xargs xmltype) return xmltype is

    cursor# integer;
  begin

    cursor# := lib_sql.execute_query#(p_stmt => p_stmt, p_args => parse_arguments(p_xargs));

    return serialize#(p_cursor# => cursor#, b_close => true);
  end;

  function execute_query$(p_stmt  varchar2,
                          p_xargs clob) return clob is
  begin

    if p_xargs is null then
      return execute_query(p_stmt => p_stmt).getclobval();
    else
      return execute_query(p_stmt => p_stmt, p_xargs => xmltype(p_xargs)).getclobval();
    end if;
  end;

  function call_procedure(p_name  varchar2,
                          p_xargs xmltype default null) return xmltype is

    results lib_sql.t_values;
  begin

    results := lib_sql.call_procedure$(p_name => p_name, p_args => parse_arguments(p_xargs));

    return serialize_and_camelize(results);
  end;

  function call_procedure$(p_name  varchar2,
                           p_xargs clob default null) return clob is
  begin

    if p_xargs is null then
      return call_procedure(p_name => p_name).getclobval();
    else
      return call_procedure(p_name => p_name, p_xargs => xmltype(p_xargs)).getclobval();
    end if;
  end;

  function call_function(p_name  varchar2,
                         p_xargs xmltype default null) return xmltype is

    result lib_sql.t_value;
  begin

    result := lib_sql.call_function$(p_name => p_name, p_args => parse_arguments(p_xargs));

    if result.type# in (lib_sql.UDT_XMLTYPE) then
      return xmltype(result.lob);
    else
      return serialize_result(result);
    end if;
  end;

  function call_function$(p_name  varchar2,
                          p_xargs clob default null) return clob is
  begin

    if p_xargs is null then
      return call_function(p_name => p_name).getclobval();
    else
      return call_function(p_name => p_name, p_xargs => xmltype(p_xargs)).getclobval();
    end if;
  end;

begin
  init();
end;
/

