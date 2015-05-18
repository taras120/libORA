create or replace package body lib_xml is

  -- LibORA PL/SQL Library
  -- XML DOM Library
  -- (c) 1981-2014
  -- Taras Lyuklyanchuk

  -- константы
  CDATA_OPEN  constant varchar2(16) := '<![CDATA[';
  CDATA_CLOSE constant varchar2(16) := ']]>';
  NLS_NUMERIC constant char(2) := '.,';

  -- инициализация
  procedure init is
  begin
    setNlsNumeric(NLS_NUMERIC);
  end;

  function crop(p_text   varchar2,
                p_length integer) return varchar2 is
  begin
    return substr(trim(p_text), 1, p_length);
  end;

  -- парсер
  function parse(p_xml clob) return xmltype is
  begin
    return xmltype(p_xml);
  end;

  -- парсер
  function parse(p_xml clob) return dbms_xmldom.DOMDocument is
  begin
    return dbms_xmldom.newDOMDocument(xmltype(p_xml));
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
    printf(serialize(p_doc));
  end;

  -- печать xml
  procedure print(p_doc dbms_xmldom.DOMDocument) is
  begin
    printf(serialize(p_doc));
  end;

  -- текст->bool
  function toBool(p_value varchar2) return boolean is
  begin
  
    if lower(p_value) = lower(XML_TRUE) then
      return true;
    elsif lower(p_value) = lower(XML_FALSE) then
      return false;
    else
      return null;
    end if;
  end;

  -- текст->дата
  function toDate(p_value  varchar2,
                  p_format varchar2 default FMT_DATE) return date is
  begin
    return to_date(crop(p_value, length(p_format)), p_format);
  end;

  -- текст->дата+время
  function toDateTime(p_value  varchar2,
                      p_format varchar2 default FMT_DATETIME) return date is
    text varchar2(32);
  begin
  
    text := crop(p_value, length(p_format));
  
    return to_date(replace(text, 'T', SPC), p_format);
  end;

  -- текст->число
  function toNumber(p_value  varchar2,
                    p_format varchar2 default NLS_NUMERIC) return number is
  begin
    return to_number(p_value, p_format);
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
                   p_format varchar2 default FMT_DATE) return varchar2 is
  begin
    return to_char(p_value, p_format);
  end;

  -- время->текст
  function xmlTime(p_value  date,
                   p_format varchar2 default FMT_TIME) return varchar2 is
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
  
    result := to_char(p_value, '');
  
    if result like '._%' then
      result := '0' || result;
    elsif result like '-._%' then
      result := '-0' || substr(result, 2);
    end if;
  
    return result;
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
  
    execute immediate sprintf('alter session set %s = "%s"', p_param, p_value);
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
  
    nsmap varchar2(1000) := getNSmap(p_nsmap);
  begin
  
    -- extract
    if p_doc.existsNode(p_xpath, nsmap) != 0 then
    
      return p_doc.extract(p_xpath, nsmap);
    end if;
  
    return null;
  end;

  -- уничтожить ноду
  procedure freeNode(node dbms_xmldom.DOMNode) is
  begin
    dbms_xmldom.freeNode(node);
  end;

  -- документ, владелец ноды
  function ownerDoc(node dbms_xmldom.DOMNode) return dbms_xmldom.DOMDocument is
  begin
    return dbms_xmldom.getOwnerDocument(node);
  end;

  -- создать xml-документ
  function createDoc(rootNode out dbms_xmldom.DOMNode,
                     rootName varchar2) return dbms_xmldom.DOMDocument is
  
    doc  dbms_xmldom.DOMDocument;
    root dbms_xmldom.DOMElement;
  begin
  
    doc      := dbms_xmldom.newDOMDocument;
    root     := dbms_xmldom.createElement(doc, rootName);
    rootNode := dbms_xmldom.appendChild(dbms_xmldom.makeNode(doc), dbms_xmldom.makeNode(root));
  
    return doc;
  end;

  -- создать ноду из документа
  function createNode(doc xmltype) return dbms_xmldom.DOMNode is
  begin
    return dbms_xmldom.makeNode(dbms_xmldom.getDocumentElement(dbms_xmldom.newDOMDocument(doc)));
  end;

  -- создать дочернюю ноду
  function createNode(parentNode dbms_xmldom.DOMNode,
                      nodeName   varchar2) return dbms_xmldom.DOMNode is
  
    childNode dbms_xmldom.DOMElement;
  begin
  
    if nodeName is null then
      throw('Node name is NULL while createNode(1)');
    end if;
  
    childNode := dbms_xmldom.createElement(dbms_xmldom.getOwnerDocument(parentNode), nodeName);
  
    return dbms_xmldom.appendChild(parentNode, dbms_xmldom.makeNode(childNode));
  end;

  -- создать дочернюю ноду
  function createNode(parentNode dbms_xmldom.DOMNode,
                      nodeName   varchar2,
                      nodeValue  varchar2) return dbms_xmldom.DOMNode is
  
    element dbms_xmldom.DOMElement;
    node    dbms_xmldom.DOMNode;
    text    dbms_xmldom.DOMText;
  begin
  
    if nodeName is not null then
    
      element := dbms_xmldom.createElement(dbms_xmldom.getOwnerDocument(parentNode), nodeName);
    
      node := dbms_xmldom.makeNode(element);
      node := dbms_xmldom.appendChild(parentNode, node);
    
      if nodeValue is not null then
      
        text := dbms_xmldom.createTextNode(dbms_xmldom.getOwnerDocument(parentNode), nodeValue);
        freeNode(dbms_xmldom.appendChild(node, dbms_xmldom.makeNode(text)));
      end if;
    
    else
      throw('Node name is NULL while createNode(2)');
    end if;
  
    return node;
  end;

  -- создать дочернюю ноду
  procedure createNode(parentNode dbms_xmldom.DOMNode,
                       nodeName   varchar2,
                       nodeValue  varchar2 default null,
                       attrName   varchar2 default null,
                       attrValue  varchar2 default null) is
  
    element dbms_xmldom.DOMElement;
    node    dbms_xmldom.DOMNode;
    text    dbms_xmldom.DOMText;
  begin
  
    if nodeName is not null and nvl(nodeValue, attrValue) is not null then
    
      element := dbms_xmldom.createElement(dbms_xmldom.getOwnerDocument(parentNode), nodeName);
    
      node := dbms_xmldom.makeNode(element);
      node := dbms_xmldom.appendChild(parentNode, node);
    
      if nodeValue is not null then
      
        text := dbms_xmldom.createTextNode(dbms_xmldom.getOwnerDocument(parentNode), nodeValue);
        node := dbms_xmldom.appendChild(node, dbms_xmldom.makeNode(text));
      end if;
    
      if attrValue is not null then
        dbms_xmldom.setAttribute(element, attrName, attrValue);
      end if;
    
      dbms_xmldom.freeNode(node);
    end if;
  end;

  -- найти/создать дочернюю ноду
  function getChild(parentNode dbms_xmldom.DOMNode,
                    childName  varchar2,
                    childIndex integer default 0) return dbms_xmldom.DOMNode is
  
    parentElement dbms_xmldom.DOMElement;
    childList     dbms_xmldom.DOMNodeList;
    childNode     dbms_xmldom.DOMNode;
  begin
  
    parentElement := dbms_xmldom.makeElement(parentNode);
  
    childList := dbms_xmldom.getChildrenByTagName(parentElement, childName);
  
    if dbms_xmldom.getLength(childList) > childIndex then
    
      childNode := dbms_xmldom.Item(childList, childIndex);
    
    elsif dbms_xmldom.getLength(childList) = childIndex then
    
      childNode := createNode(parentNode, childName);
    
    else
      throw('Node index out of range');
    end if;
  
    return childNode;
  end;

  -- текстовая под-нода
  function getTextNode(node dbms_xmldom.DOMNode) return dbms_xmldom.DOMText is
  
    children dbms_xmldom.DOMNodeList;
    child    dbms_xmldom.DOMNode;
  begin
  
    children := dbms_xmldom.getChildNodes(node);
  
    if dbms_xmldom.getLength(children) != 0 then
    
      child := dbms_xmldom.getFirstChild(node);
    
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
  function getText(node dbms_xmldom.DOMNode) return varchar2 is
  
    child    dbms_xmldom.DOMNode;
    children dbms_xmldom.DOMNodeList;
    result   varchar2(32767);
  begin
  
    children := dbms_xmldom.getChildNodes(node);
  
    for i in 0 .. dbms_xmldom.getLength(children) - 1 loop
    
      child := dbms_xmldom.item(children, i);
    
      if dbms_xmldom.getNodeType(child) in (dbms_xmldom.TEXT_NODE, dbms_xmldom.CDATA_SECTION_NODE) then
        result := result || dbms_xmldom.getNodeValue(child);
      end if;
    end loop;
  
    return result;
  end;

  -- логическое значение
  function getBool(p_doc   xmltype,
                   p_xpath varchar2,
                   p_nsmap varchar2 default null) return boolean is
  begin
  
    return toBool(getText(p_doc, p_xpath, p_nsmap));
  end;

  -- целое число
  function getInteger(p_doc   xmltype,
                      p_xpath varchar2,
                      p_nsmap varchar2 default null) return integer is
  begin
  
    return trunc(getNumber(p_doc, p_xpath, p_nsmap));
  end;

  -- число с плавающей точкой
  function getNumber(p_doc   xmltype,
                     p_xpath varchar2,
                     p_nsmap varchar2 default null) return number is
  begin
  
    return to_number(getText(p_doc, p_xpath, p_nsmap), NLS_NUMERIC);
  end;

  -- дата
  function getDate(p_doc    xmltype,
                   p_xpath  varchar2,
                   p_format varchar2 default FMT_DATE) return date is
  begin
  
    return toDate(p_value => getText(p_doc, p_xpath), p_format => p_format);
  end;

  -- дата+время
  function getDateTime(p_doc    xmltype,
                       p_xpath  varchar2,
                       p_format varchar2 default FMT_DATETIME) return date is
  begin
  
    return toDateTime(p_value => getText(p_doc, p_xpath), p_format => p_format);
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
  begin
  
    textNode := getTextNode(p_node);
  
    if not dbms_xmldom.isNull(textNode) then
      dbms_xmldom.setNodeValue(dbms_xmldom.makeNode(textNode), p_value);
    else
      textNode := dbms_xmldom.createTextNode(ownerDoc(p_node), null);
      dbms_xmldom.setNodeValue(dbms_xmldom.makeNode(textNode), p_value);
      freeNode(dbms_xmldom.appendChild(p_node, dbms_xmldom.makeNode(textNode)));
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

begin
  init();
end;
/

