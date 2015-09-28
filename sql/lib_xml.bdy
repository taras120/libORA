create or replace package body lib_xml is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- XML Library
  -- (c) 1981-2014 Taras Lyuklyanchuk

  -- constants
  SPC         constant char(1) := const.SPC;
  AMP         constant char(1) := const.AMP;
  CDATA_OPEN  constant varchar2(16) := '<![CDATA[';
  CDATA_CLOSE constant varchar2(16) := ']]>';
  NLS_NUMERIC constant char(2) := '.,';

  -- init
  procedure init is
  begin
    setNlsNumeric(NLS_NUMERIC);
  end;

  -- парсер
  function parse(p_clob clob) return xmltype is
  begin
  
    if p_clob is null then
      return null;
    else
      return xmltype(p_clob);
    end if;
  end;

  -- парсер
  function parse(p_cursor t_cursor) return xmltype is
  begin
    return xmltype(p_cursor);
  end;

  -- сериализация
  function serialize(p_doc xmltype) return clob is
  begin
    return p_doc.getclobval();
  end;

  -- сериализация
  function serialize(p_doc dbms_xmldom.DOMDocument) return clob is
  begin
    return serialize(dbms_xmldom.getxmltype(p_doc));
  end;

  -- печать xml
  procedure print(p_doc xmltype) is
  begin
    lib_lob.print(serialize(p_doc));
  end;

  -- печать xml
  procedure print(p_doc dbms_xmldom.DOMDocument) is
  begin
    lib_lob.print(serialize(p_doc));
  end;

  -- печать xml
  procedure print(p_node dbms_xmldom.DOMNode,
                  p_root dbms_xmldom.DOMNode default null) is
  
    childList dbms_xmldom.DOMNodeList;
    childNode dbms_xmldom.DOMNode;
    nodeLevel integer;
  begin
  
    if isNotNull(p_root) then
      nodeLevel := getNodeLevel(p_node) - getNodeLevel(p_root);
    else
      nodeLevel := 0;
    end if;
  
    if dbms_xmldom.getNodeType(p_node) in (dbms_xmldom.TEXT_NODE, dbms_xmldom.CDATA_SECTION_NODE) then
    
      lib_text.print(dbms_xmldom.getNodeValue(p_node));
    
    else
    
      if nodeLevel != 0 then
        lib_text.println();
      end if;
    
      lib_text.printf('%s%s: ', lib_text.space(nodeLevel * 2), dbms_xmldom.getNodeName(p_node));
    
      childList := dbms_xmldom.getChildNodes(p_node);
    
      -- recursive traverse
      for n in 0 .. dbms_xmldom.getLength(childList) - 1 loop
      
        childNode := dbms_xmldom.item(childList, n);
      
        print(childNode, p_node);
      end loop;
    end if;
  
    if nodeLevel = 0 then
      lib_text.println();
    end if;
  end;

  -- текст->bool
  function toBool(p_value varchar2) return boolean is
  begin
  
    if lower(p_value) in (lower(XML_TRUE), to_char(const.I_TRUE)) then
      return true;
    elsif lower(p_value) in (lower(XML_FALSE), to_char(const.I_FALSE)) then
      return false;
    else
      return null;
    end if;
  end;

  -- текст->дата
  function toDate(p_value  varchar2,
                  p_format varchar2 default DATE_FORMAT) return date is
  begin
  
    return to_date(lib_text.crop(p_value, length(p_format)), p_format);
  end;

  -- текст->дата+время
  function toDateTime(p_value  varchar2,
                      p_format varchar2 default DATETIME_FORMAT) return date is
  
    value  varchar2(100) := replace(p_value, 'T', SPC);
    format varchar2(100) := replace(p_format, 'T', SPC);
  begin
  
    return to_date(lib_text.crop(value, length(format)), format);
  end;

  -- текст->число
  function toNumber(p_value  varchar2,
                    p_format varchar2 default null) return number is
  begin
  
    if p_format is not null then
      return to_number(p_value, p_format);
    else
      return to_number(p_value);
    end if;
  
  exception
    when INVALID_NUMBER then
    
      throw('Invalid number: %s', p_value);
    
    when others then
      raise;
  end;

  -- текст->целое число
  function toInteger(p_value varchar2) return integer is
    val number;
  begin
  
    val := toNumber(p_value);
  
    if val != trunc(val) then
      throw('Invalid integer: %s', val);
    end if;
  
    return val;
  end;

  -- xml Boolean
  function xmlBool(p_value boolean) return varchar2 is
  begin
  
    if p_value then
      return XML_TRUE;
    elsif not p_value then
      return XML_FALSE;
    else
      return null;
    end if;
  end;

  -- xml Boolean
  function xmlBool(p_value integer) return varchar2 is
  begin
    return xmlBool(sys.diutil.int_to_bool(p_value));
  end;

  -- дата->текст
  function xmlDate(p_value  date,
                   p_format varchar2 default DATE_FORMAT) return varchar2 is
  begin
    return to_char(p_value, p_format);
  end;

  -- время->текст
  function xmlTime(p_value  date,
                   p_format varchar2 default TIME_FORMAT) return varchar2 is
  begin
    return to_char(p_value, p_format);
  end;

  -- время->текст
  function xmlDateTime(p_value date) return varchar2 is
  begin
  
    if p_value is not null then
      return sprintf('%sT%s', xmlDate(p_value), xmlTime(p_value));
    else
      return null;
    end if;
  end;

  -- число->текст
  function xmlNumber(p_value number) return varchar2 is
    result varchar2(1000);
  begin
  
    result := to_char(p_value);
  
    if result like '._%' then
      result := '0' || result;
    elsif result like '-._%' then
      result := '-0' || substr(result, 2);
    end if;
  
    return result;
  end;

  -- целое число->текст
  function xmlInteger(p_value integer) return varchar2 is
  begin
    return xmlNumber(p_value);
  end;

  -- namespace map
  function getNSmap(p_xmlns  varchar2,
                    p_prefix varchar2 default null) return varchar2 is
  begin
  
    if instr(p_xmlns, '=') != 0 then
      return p_xmlns;
    elsif p_xmlns is not null then
      if p_prefix is null then
        return sprintf('xmlns="%s"', p_xmlns);
      else
        return sprintf('xmlns:%s="%s"', p_prefix, p_xmlns);
      end if;
    else
      return null;
    end if;
  end;

  -- установить параметр сессии
  procedure setSessionParam(p_param varchar2,
                            p_value varchar2) is
  begin
  
    lib_util.set_session_param(p_param, p_value);
  end;

  -- NLS Numeric Characters
  procedure setNlsNumeric(p_value varchar2) is
  begin
  
    -- NLS
    for q in (select t.* from v$nls_parameters t where t.parameter = 'NLS_NUMERIC_CHARACTERS') loop
    
      if q.value != p_value then
      
        setSessionParam(q.parameter, p_value);
      end if;
    end loop;
  end;

  -- xml Entity
  function entity(p_text varchar2) return varchar2 is
  
    text varchar2(4000) := trim(p_text);
  begin
  
    text := replace(text, AMP, AMP || 'amp;');
    text := replace(text, '<', AMP || 'lt;');
    text := replace(text, '>', AMP || 'gt;');
    text := replace(text, '"', AMP || 'quot;');
    text := replace(text, '''', AMP || 'apos;');
  
    return text;
  end;

  -- xml unentity
  function unentity(p_text varchar2) return varchar2 is
    text varchar2(4000) := p_text;
  begin
  
    if text is not null then
    
      text := replace(text, AMP || 'amp;', AMP);
      text := replace(text, AMP || 'lt;', '<');
      text := replace(text, AMP || 'gt;', '>');
      text := replace(text, AMP || 'quot;', '"');
      text := replace(text, AMP || 'apos;', '''');
    
      -- фиксим косяки компаса
      for i in 2 .. length(text) - 1 loop
      
        if substr(text, i, 1) = '"' then
          if substr(text, i + 1, 1) not in (SPC, '>') and substr(text, i - 1, 1) not in ('=') then
            text := substr(text, 1, i - 1) || substr(text, i + 1);
          end if;
        end if;
      end loop;
    
    end if;
  
    -- CDATA unwrap
    text := replace(replace(text, CDATA_OPEN), CDATA_CLOSE);
  
    return text;
  end;

  -- объеденить
  function concat(p_doc1 xmltype,
                  p_doc2 xmltype default null,
                  p_doc3 xmltype default null,
                  p_doc4 xmltype default null) return xmltype is
    xml xmltype;
  begin
    select xmlelement("root", xmlconcat(p_doc1, p_doc2, p_doc3, p_doc4)) into xml from dual;
    return xml;
  end;

  -- извлечь ноду по пути
  function extract(p_doc   xmltype,
                   p_xpath varchar2,
                   p_nsmap varchar2 default null) return xmltype is
  
    nsmap varchar2(4000) := getNSmap(p_nsmap);
  begin
  
    -- extract
    if p_doc.existsNode(p_xpath, nsmap) != 0 then
    
      return p_doc.extract(p_xpath, nsmap);
    end if;
  
    return null;
  end;

  -- создать документ
  function createDoc(p_clob clob) return dbms_xmldom.DOMDocument is
  begin
    return dbms_xmldom.newDOMDocument(xmltype(p_clob));
  end;

  -- создать документ
  function createDoc(p_doc xmltype) return dbms_xmldom.DOMDocument is
  begin
    return dbms_xmldom.newDOMDocument(p_doc);
  end;

  -- создать документ и корневую ноду
  function createDoc(p_root out dbms_xmldom.DOMNode,
                     p_name varchar2) return dbms_xmldom.DOMDocument is
  
    doc  dbms_xmldom.DOMDocument;
    root dbms_xmldom.DOMElement;
  begin
  
    doc    := dbms_xmldom.newDOMDocument;
    root   := dbms_xmldom.createElement(doc, p_name);
    p_root := dbms_xmldom.appendChild(dbms_xmldom.makeNode(doc), dbms_xmldom.makeNode(root));
  
    return doc;
  end;

  -- создать документ и корневую ноду
  function createDoc(p_name varchar2) return dbms_xmldom.DOMNode is
  
    doc  dbms_xmldom.DOMDocument;
    root dbms_xmldom.DOMElement;
  begin
  
    doc  := dbms_xmldom.newDOMDocument;
    root := dbms_xmldom.createElement(doc, p_name);
  
    return dbms_xmldom.appendChild(dbms_xmldom.makeNode(doc), dbms_xmldom.makeNode(root));
  end;

  -- создать документ из ноды
  function createDoc(p_node dbms_xmldom.DOMNode) return dbms_xmldom.DOMDocument is
  
    doc  dbms_xmldom.DOMDocument;
    root dbms_xmldom.DOMNode;
  begin
  
    doc  := dbms_xmldom.newDOMDocument;
    root := dbms_xmldom.adoptNode(doc, p_node);
    root := dbms_xmldom.appendChild(dbms_xmldom.makeNode(doc), root);
  
    freeNode(root);
  
    return doc;
  end;

  -- создать ноду из документа
  function createNode(p_doc xmltype) return dbms_xmldom.DOMNode is
  begin
    return dbms_xmldom.makeNode(dbms_xmldom.getDocumentElement(dbms_xmldom.newDOMDocument(p_doc)));
  end;

  -- создать дочернюю ноду
  function createNode(p_parent dbms_xmldom.DOMNode,
                      p_name   varchar2) return dbms_xmldom.DOMNode is
  
    childNode dbms_xmldom.DOMElement;
  begin
  
    if p_name is null then
      throw('Node name is NULL while createNode(1)');
    end if;
  
    childNode := dbms_xmldom.createElement(dbms_xmldom.getOwnerDocument(p_parent), p_name);
  
    return dbms_xmldom.appendChild(p_parent, dbms_xmldom.makeNode(childNode));
  end;

  -- создать дочернюю ноду
  function createNode(p_parent dbms_xmldom.DOMNode,
                      p_name   varchar2,
                      p_value  varchar2) return dbms_xmldom.DOMNode is
  
    element dbms_xmldom.DOMElement;
    node    dbms_xmldom.DOMNode;
    text    dbms_xmldom.DOMText;
  begin
  
    if p_name is not null then
    
      element := dbms_xmldom.createElement(dbms_xmldom.getOwnerDocument(p_parent), p_name);
    
      node := dbms_xmldom.makeNode(element);
      node := dbms_xmldom.appendChild(p_parent, node);
    
      if p_value is not null then
      
        text := dbms_xmldom.createTextNode(dbms_xmldom.getOwnerDocument(p_parent), p_value);
        freeNode(dbms_xmldom.appendChild(node, dbms_xmldom.makeNode(text)));
      end if;
    
    else
      throw('Node name is NULL while createNode(2)');
    end if;
  
    return node;
  end;

  -- создать дочернюю ноду
  procedure createNode(p_parent     dbms_xmldom.DOMNode,
                       p_name       varchar2,
                       p_value      varchar2,
                       p_attr_name  varchar2 default null,
                       p_attr_value varchar2 default null) is
  
    element dbms_xmldom.DOMElement;
    node    dbms_xmldom.DOMNode;
  begin
  
    node := createNode(p_parent => p_parent, p_name => p_name, p_value => p_value);
  
    if p_attr_value is not null then
    
      element := dbms_xmldom.makeElement(node);
      dbms_xmldom.setAttribute(element, p_attr_name, p_attr_value);
    end if;
  
    freeNode(node);
  end;

  -- создать дочернюю ноду
  procedure createNode(p_parent dbms_xmldom.DOMNode,
                       p_name   varchar2,
                       p_value  boolean) is
  begin
  
    createNode(p_parent => p_parent, p_name => p_name, p_value => xmlBool(p_value));
  end;

  -- создать дочернюю ноду
  procedure createNode(p_parent dbms_xmldom.DOMNode,
                       p_name   varchar2,
                       p_value  date) is
  begin
  
    createNode(p_parent => p_parent, p_name => p_name, p_value => xmlDateTime(p_value));
  end;

  -- создать дочернюю ноду
  procedure createNode(p_parent dbms_xmldom.DOMNode,
                       p_name   varchar2,
                       p_value  number) is
  begin
  
    createNode(p_parent => p_parent, p_name => p_name, p_value => xmlNumber(p_value));
  end;

  -- добавить документ как ноду
  function appendChild(p_node  dbms_xmldom.DOMNode,
                       p_child xmltype) return dbms_xmldom.DOMNode is
  
    doc   dbms_xmldom.DOMDocument;
    child dbms_xmldom.DOMNode;
  begin
  
    doc   := dbms_xmldom.getOwnerDocument(p_node);
    child := getRootNode(createDoc(p_child));
  
    child := dbms_xmldom.adoptNode(doc, child);
    return dbms_xmldom.appendChild(p_node, child);
  end;

  -- добавить документ как ноду
  procedure appendChild(p_node  dbms_xmldom.DOMNode,
                        p_child xmltype) is
  begin
    freeNode(appendChild(p_node, p_child));
  end;

  -- добавить документ как ноду
  function appendChild(p_node  dbms_xmldom.DOMNode,
                       p_name  varchar2,
                       p_child xmltype) return dbms_xmldom.DOMNode is
  
    doc        dbms_xmldom.DOMDocument;
    childRoot  dbms_xmldom.DOMNode;
    importNode dbms_xmldom.DOMNode;
    importList dbms_xmldom.DOMNodeList;
  begin
  
    doc       := dbms_xmldom.getOwnerDocument(p_node);
    childRoot := createNode(p_node, p_name);
  
    importList := dbms_xmldom.getChildNodes(getRootNode(createDoc(p_child)));
  
    -- rows
    for i in 0 .. dbms_xmldom.getLength(importList) - 1 loop
    
      importNode := dbms_xmldom.item(importList, i);
    
      importNode := dbms_xmldom.adoptNode(doc, importNode);
      freeNode(dbms_xmldom.appendChild(childRoot, importNode));
    end loop;
  
    return childRoot;
  end;

  -- добавить документ как ноду
  procedure appendChild(p_node  dbms_xmldom.DOMNode,
                        p_name  varchar2,
                        p_child xmltype) is
  begin
    freeNode(appendChild(p_node, p_name, p_child));
  end;

  -- уничтожить ноду
  procedure freeNode(p_node dbms_xmldom.DOMNode) is
  begin
    dbms_xmldom.freeNode(p_node);
  end;

  -- документ, владелец ноды
  function ownerDoc(p_node dbms_xmldom.DOMNode) return dbms_xmldom.DOMDocument is
  begin
    return dbms_xmldom.getOwnerDocument(p_node);
  end;

  -- проверка на Null
  function isNull(p_node dbms_xmldom.DOMNode) return boolean is
  begin
    return dbms_xmldom.isNull(p_node);
  end;

  -- проверка на Null
  function isNotNull(p_node dbms_xmldom.DOMNode) return boolean is
  begin
    return not isNull(p_node);
  end;

  -- текстовая нода?
  function isTextNode(p_node dbms_xmldom.DOMNode) return boolean is
  
    child    dbms_xmldom.DOMNode;
    children dbms_xmldom.DOMNodeList;
  begin
  
    if dbms_xmldom.getNodeType(child) in (dbms_xmldom.TEXT_NODE, dbms_xmldom.CDATA_SECTION_NODE) then
    
      return true;
    
    elsif dbms_xmldom.hasChildNodes(p_node) then
    
      children := dbms_xmldom.getChildNodes(p_node);
    
      for i in 0 .. dbms_xmldom.getLength(children) - 1 loop
      
        child := dbms_xmldom.item(children, i);
      
        if dbms_xmldom.getNodeType(child) in
           (dbms_xmldom.TEXT_NODE, dbms_xmldom.CDATA_SECTION_NODE) then
        
          return true;
        end if;
      end loop;
    
      return false;
    
    else
      return false;
    end if;
  
  end;

  -- найти/создать дочернюю ноду
  function getChild(p_parent dbms_xmldom.DOMNode,
                    p_name   varchar2,
                    p_index  integer default 0) return dbms_xmldom.DOMNode is
  
    parentElement dbms_xmldom.DOMElement;
    childList     dbms_xmldom.DOMNodeList;
    childNode     dbms_xmldom.DOMNode;
  begin
  
    parentElement := dbms_xmldom.makeElement(p_parent);
  
    childList := dbms_xmldom.getChildrenByTagName(parentElement, p_name);
  
    if dbms_xmldom.getLength(childList) > p_index then
    
      childNode := dbms_xmldom.Item(childList, p_index);
    
    elsif dbms_xmldom.getLength(childList) = p_index then
    
      childNode := createNode(p_parent, p_name);
    
    else
      throw('Node index out of range');
    end if;
  
    return childNode;
  end;

  -- текстовая под-нода
  function getTextNode(p_node dbms_xmldom.DOMNode) return dbms_xmldom.DOMText is
  
    children dbms_xmldom.DOMNodeList;
    child    dbms_xmldom.DOMNode;
  begin
  
    children := dbms_xmldom.getChildNodes(p_node);
  
    if dbms_xmldom.getLength(children) != 0 then
    
      child := dbms_xmldom.getFirstChild(p_node);
    
      if dbms_xmldom.getNodeType(child) in (dbms_xmldom.TEXT_NODE, dbms_xmldom.CDATA_SECTION_NODE) then
        return dbms_xmldom.makeText(child);
      end if;
    end if;
  
    return null;
  end;

  -- текст
  function getText(p_doc   xmltype,
                   p_xpath varchar2,
                   p_nsmap varchar2 default null) return varchar2 is
  
    xpath varchar2(1000);
    nsmap varchar2(1000);
  begin
  
    -- xpath
    if instr(p_xpath, '@') = 0 then
      xpath := sprintf('%s/text()', p_xpath);
    else
      xpath := p_xpath;
    end if;
  
    -- nsmap
    nsmap := getNSmap(p_nsmap);
  
    if p_doc.existsNode(xpath, nsmap) != 0 then
      return unEntity(p_doc.extract(xpath, nsmap).getStringVal());
    else
      return null;
    end if;
  end;

  -- текстовое содержимое ноды
  function getText(p_node dbms_xmldom.DOMNode) return varchar2 is
  
    child    dbms_xmldom.DOMNode;
    children dbms_xmldom.DOMNodeList;
    result   varchar2(32767);
  begin
  
    if dbms_xmldom.hasChildNodes(p_node) then
    
      children := dbms_xmldom.getChildNodes(p_node);
    
      for i in 0 .. dbms_xmldom.getLength(children) - 1 loop
      
        child := dbms_xmldom.item(children, i);
      
        if dbms_xmldom.getNodeType(child) in
           (dbms_xmldom.TEXT_NODE, dbms_xmldom.CDATA_SECTION_NODE) then
        
          result := result || dbms_xmldom.getNodeValue(child);
        end if;
      end loop;
    
      return result;
    
    else
      return dbms_xmldom.getNodeValue(p_node);
    end if;
  
  end;

  -- установить значение ноды
  /*
   function getClob(p_node dbms_xmldom.DOMNode) return clob is
  
     child    dbms_xmldom.DOMNode;
     children dbms_xmldom.DOMNodeList;
     clobNode dbms_xmldom.DOMNode;
     stream   sys.utl_CharacterInputStream;
     amount   integer;
     buff     varchar2(32767);
     result   clob;
   begin
  
     if dbms_xmldom.hasChildNodes(p_node) then
  
       children := dbms_xmldom.getChildNodes(p_node);
  
       for i in 0 .. dbms_xmldom.getLength(children) - 1 loop
  
         child := dbms_xmldom.item(children, i);
  
         if dbms_xmldom.getNodeType(child) in
            (dbms_xmldom.TEXT_NODE, dbms_xmldom.CDATA_SECTION_NODE) then
  
           clobNode := child;
           exit;
         end if;
       end loop;
  
     else
       clobNode := p_node;
     end if;
  
     dbms_lob.createTemporary(result, true);
  
     stream := dbms_xmldom.getNodeValueAsCharacterStream(clobNode);
  
     -- read stream
     amount := 4000;
     loop
       stream.read(buff, amount);
       exit when amount = 0;
  
       dbms_lob.writeAppend(result, length(buff), buff);
       --offset := offset + length(buff);
     end loop;
  
     stream.close();
  
     return result;
  
   end;
  */
  -- текстовое содержимое ноды
  function getClob(p_node dbms_xmldom.DOMNode) return clob is
  
    child    dbms_xmldom.DOMNode;
    children dbms_xmldom.DOMNodeList;
    result   clob;
  begin
  
    dbms_lob.createTemporary(result, true);
  
    if dbms_xmldom.hasChildNodes(p_node) then
    
      children := dbms_xmldom.getChildNodes(p_node);
    
      for i in 0 .. dbms_xmldom.getLength(children) - 1 loop
      
        child := dbms_xmldom.item(children, i);
      
        if dbms_xmldom.getNodeType(child) in
           (dbms_xmldom.TEXT_NODE, dbms_xmldom.CDATA_SECTION_NODE) then
        
          dbms_xmldom.writeToClob(child, result);
          exit when dbms_lob.getLength(result) != 0;
        end if;
      end loop;
    
    else
      dbms_xmldom.writeToClob(p_node, result);
    end if;
  
    return result;
  end;

  -- логическое значение
  function getBool(p_doc   xmltype,
                   p_xpath varchar2,
                   p_nsmap varchar2 default null) return boolean is
  begin
  
    return toBool(getText(p_doc, p_xpath, p_nsmap));
  end;

  -- логическое значение
  function getBool(p_node dbms_xmldom.DOMNode) return boolean is
  begin
    return toBool(getText(p_node));
  end;

  -- число с плавающей точкой
  function getNumber(p_doc   xmltype,
                     p_xpath varchar2,
                     p_nsmap varchar2 default null) return number is
  begin
  
    return toNumber(getText(p_doc, p_xpath, p_nsmap));
  end;

  -- число с плавающей точкой
  function getNumber(p_node dbms_xmldom.DOMNode) return number is
  begin
  
    return toNumber(getText(p_node));
  end;

  -- целое число
  function getInteger(p_doc   xmltype,
                      p_xpath varchar2,
                      p_nsmap varchar2 default null) return integer is
  begin
  
    return toInteger(getText(p_doc, p_xpath, p_nsmap));
  end;

  -- целое число
  function getInteger(p_node dbms_xmldom.DOMNode) return integer is
  begin
    return toInteger(getText(p_node));
  end;

  -- дата
  function getDate(p_doc    xmltype,
                   p_xpath  varchar2,
                   p_format varchar2 default DATE_FORMAT) return date is
  begin
  
    return toDate(p_value => getText(p_doc, p_xpath), p_format => p_format);
  end;

  -- дата
  function getDate(p_node   dbms_xmldom.DOMNode,
                   p_format varchar2 default DATE_FORMAT) return date is
  begin
    return toDate(p_value => getText(p_node), p_format => p_format);
  end;

  -- дата+время
  function getDateTime(p_doc    xmltype,
                       p_xpath  varchar2,
                       p_format varchar2 default DATETIME_FORMAT) return date is
  begin
  
    return toDateTime(p_value => getText(p_doc, p_xpath), p_format => p_format);
  end;

  -- дата+время
  function getDateTime(p_node   dbms_xmldom.DOMNode,
                       p_format varchar2 default DATETIME_FORMAT) return date is
  begin
    return toDateTime(p_value => getText(p_node), p_format => p_format);
  
  end;

  -- прочитать атрибут
  function getAttrValue(p_node dbms_xmldom.DOMNode,
                        p_attr varchar2) return varchar2 is
  
    element dbms_xmldom.DOMElement;
  begin
  
    if p_attr is not null then
    
      element := dbms_xmldom.makeElement(p_node);
      return dbms_xmldom.getAttribute(element, p_attr);
    else
      return null;
    end if;
  end;

  -- SQL-совместимое содержимое ноды
  function getSQLValue(p_node dbms_xmldom.DOMNode) return varchar2 is
  
    colName varchar2(1000);
    colText varchar2(32767);
  begin
  
    colName := getNodeName(p_node);
    colText := getText(p_node);
  
    if colText is not null then
    
      if lower(colName) like 'is%' and toBool(colText) is not null then
        return to_int(toBool(colText));
      elsif lower(colName) like '%date%' and colText like '____-__-__T' then
        return toDate(colText);
      elsif lower(colName) like '%date%' and colText like '____-__-__T%' then
        return toDateTime(colText);
      else
        return colText;
      end if;
    end if;
  
    return colText;
  end;

  -- нода->xmltype
  function getXmlType(p_node dbms_xmldom.DOMNode) return xmltype is
  begin
    return dbms_xmldom.getxmltype(ownerDoc(p_node));
  end;

  -- извлечь список
  function getList(p_doc   xmltype,
                   p_xpath varchar2) return t_xml_list is
  
    n      integer;
    rec    xmltype;
    result t_xml_list := t_xml_list();
  begin
  
    while p_doc is not null loop
    
      inc(n);
    
      rec := p_doc.extract(sprintf('%s[position()=%s]/*', p_xpath, n));
      exit when rec is null;
    
      result.extend;
      result(result.last) := rec;
    end loop;
  
    return result;
  end;

  -- извлечь список
  function getList(p_parent dbms_xmldom.DOMNode,
                   p_name   varchar2) return t_node_list is
  
    result   t_node_list := t_node_list();
    nodeList dbms_xmldom.DOMNodeList;
  begin
  
    nodeList := dbms_xmldom.getChildrenByTagName(dbms_xmldom.makeElement(p_parent), p_name);
  
    -- recursive traverse
    for n in 0 .. dbms_xmldom.getLength(nodeList) - 1 loop
    
      result.extend;
      result(result.last) := dbms_xmldom.item(nodeList, n);
    end loop;
  
    return result;
  end;

  -- установить значение ноды
  procedure setText(p_node  dbms_xmldom.DOMNode,
                    p_value varchar2) is
  
    textNode dbms_xmldom.DOMText;
  begin
  
    textNode := getTextNode(p_node);
  
    if not dbms_xmldom.isNull(textNode) then
      dbms_xmldom.setNodeValue(dbms_xmldom.makeNode(textNode), p_value);
    else
      textNode := dbms_xmldom.createTextNode(ownerDoc(p_node), p_value);
      freeNode(dbms_xmldom.appendChild(p_node, dbms_xmldom.makeNode(textNode)));
    end if;
  end;

  -- установить значение ноды
  procedure setClob(p_node  dbms_xmldom.DOMNode,
                    p_value clob) is
  
    textNode dbms_xmldom.DOMText;
    stream   sys.utl_CharacterOutputStream;
    buffsize integer;
    amount   integer;
    bufflen  integer;
    offset   integer;
    clobsize integer;
    buff     varchar2(32767);
  begin
  
    if p_value is not null then
    
      textNode := getTextNode(p_node);
    
      if not dbms_xmldom.isNull(textNode) then
      
        stream := dbms_xmldom.setNodeValueAsCharacterStream(dbms_xmldom.makeNode(textNode));
      
      else
      
        textNode := dbms_xmldom.createTextNode(ownerDoc(p_node), null);
        freeNode(dbms_xmldom.appendChild(p_node, dbms_xmldom.makeNode(textNode)));
      
        stream := dbms_xmldom.setNodeValueAsCharacterStream(dbms_xmldom.makeNode(textNode));
      end if;
    
      stream.flush;
    
      -- write stream
      offset   := 1;
      buffsize := 4000;
      clobsize := dbms_lob.getLength(p_value);
    
      for i in 1 .. ceil(clobsize / buffsize) loop
      
        amount := least(buffsize, clobsize - offset + 1);
        dbms_lob.read(p_value, amount, offset, buff);
      
        bufflen := lengthb(buff);
        stream.write(buff, bufflen);
      
        offset := offset + amount;
      end loop;
    
      stream.close();
    end if;
  end;

  -- установить значение ноды
  procedure setBool(p_node  dbms_xmldom.DOMNode,
                    p_value boolean) is
  begin
    setText(p_node, xmlBool(p_value));
  end;

  -- установить значение ноды
  procedure setInteger(p_node  dbms_xmldom.DOMNode,
                       p_value integer) is
  begin
    setText(p_node, p_value);
  end;

  -- установить значение ноды
  procedure setNumber(p_node  dbms_xmldom.DOMNode,
                      p_value number) is
  begin
    setText(p_node, xmlNumber(p_value));
  end;

  -- установить значение ноды
  procedure setDate(p_node  dbms_xmldom.DOMNode,
                    p_value date) is
  begin
    setText(p_node, xmlDate(p_value));
  end;

  -- установить значение ноды
  procedure setDateTime(p_node  dbms_xmldom.DOMNode,
                        p_value date) is
  begin
    setText(p_node, xmlDateTime(p_value));
  end;

  -- установить атрибут
  procedure setAttrValue(p_node  dbms_xmldom.DOMNode,
                         p_attr  varchar2,
                         p_value varchar2) is
  
    element dbms_xmldom.DOMElement;
  begin
  
    if p_attr is not null then
    
      element := dbms_xmldom.makeElement(p_node);
      dbms_xmldom.setAttribute(element, p_attr, p_value);
    end if;
  end;

  -- корневая нода
  function getRootNode(p_doc dbms_xmldom.DOMDocument) return dbms_xmldom.DOMNode is
  begin
    return dbms_xmldom.makeNode(dbms_xmldom.getDocumentElement(p_doc));
  end;

  -- название ноды
  function getNodeName(p_node dbms_xmldom.DOMNode) return varchar2 is
  begin
  
    --  if dbms_xmldom.getNodeType(p_node) = dbms_xmldom.TEXT_NODE then
    --    return getNodeName(dbms_xmldom.getParentNode(p_node));
    --  else
    return dbms_xmldom.getNodeName(p_node);
    --  end if;
  end;

  -- путь к ноде
  function getNodePath(p_node dbms_xmldom.DOMNode) return varchar2 is
  
    parentNode dbms_xmldom.DOMNode;
    parentPath varchar2(4000);
  begin
  
    parentNode := dbms_xmldom.getParentNode(p_node);
  
    if dbms_xmldom.getNodeType(p_node) = dbms_xmldom.TEXT_NODE then
    
      return getNodePath(parentNode);
    
    elsif isNotNull(parentNode) and
          dbms_xmldom.getNodeType(parentNode) != dbms_xmldom.DOCUMENT_NODE then
    
      parentPath := getNodePath(parentNode);
    end if;
  
    return parentPath || '/' || getNodeName(p_node);
  end;

  -- уровень ноды от корня
  function getNodeLevel(p_node dbms_xmldom.DOMNode) return integer is
  
    n          integer := 0;
    parentNode dbms_xmldom.DOMNode := p_node;
  begin
  
    loop
      parentNode := dbms_xmldom.getParentNode(parentNode);
      exit when isNull(parentNode);
    
      inc(n);
    end loop;
  
    return n;
  end;

  -- hash map parser
  function parseHashMap(p_map  types.hashmap,
                        p_name varchar2) return xmltype is
  
    key  varchar2(1000);
    doc  dbms_xmldom.DOMDocument;
    root dbms_xmldom.DOMNode;
  begin
  
    doc := createDoc(root, p_name);
  
    if p_map.count != 0 then
    
      key := p_map.first;
      while key is not null loop
      
        createNode(root, key, p_map(key));
      
        key := p_map.next(key);
      end loop;
    end if;
  
    return dbms_xmldom.getxmltype(doc);
  end;

  -- hash map serializer
  function serializeHashMap(p_xml xmltype) return types.hashmap is
  
    doc       dbms_xmldom.DOMDocument;
    root      dbms_xmldom.DOMNode;
    keyNode   dbms_xmldom.DOMNode;
    keyList   dbms_xmldom.DOMNodeList;
    hashMap   types.hashmap;
    keys#     integer;
    isList    boolean;
    firstNode dbms_xmldom.DOMNode;
    lastNode  dbms_xmldom.DOMNode;
  begin
  
    if p_xml is not null then
    
      doc     := createDoc(p_xml);
      root    := getRootNode(doc);
      keyList := dbms_xmldom.getChildNodes(root);
    
      keys# := dbms_xmldom.getLength(keyList);
    
      if keys# > 1 then
      
        firstNode := dbms_xmldom.item(keyList, 0);
        lastNode  := dbms_xmldom.item(keyList, keys# - 1);
      
        isList := getNodeName(firstNode) = getNodeName(lastNode);
      else
        isList := false;
      end if;
    
      for i in 0 .. dbms_xmldom.getLength(keyList) - 1 loop
      
        keyNode := dbms_xmldom.item(keyList, i);
      
        if isList then
          hashMap(i + 1) := getText(keyNode);
        else
          hashMap(getNodeName(keyNode)) := getText(keyNode);
        end if;
      end loop;
    end if;
  
    return hashMap;
  end;

begin
  init();
end;
/

