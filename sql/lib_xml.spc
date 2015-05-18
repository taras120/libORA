create or replace package lib_xml is

  -- LibORA PL/SQL Library
  -- XML DOM Library
  -- (c) 1981-2014
  -- Taras Lyuklyanchuk

  -- constants
  SPC          constant char(1) := chr(32);
  AMP          constant char(1) := chr(38);
  XML_TRUE     constant varchar2(16) := 'true';
  XML_FALSE    constant varchar2(16) := 'false';
  FMT_DATE     constant varchar2(32) := 'yyyy-mm-dd';
  FMT_TIME     constant varchar2(32) := 'hh24:mi:ss';
  FMT_DATETIME constant varchar2(32) := FMT_DATE || SPC || FMT_TIME;

  -- types
  type t_cursor is ref cursor;

  -- парсер
  function parse(p_xml clob) return xmltype;

  -- парсер
  function parse(p_xml clob) return dbms_xmldom.DOMDocument;

  -- парсер
  function parse(p_cursor t_cursor) return xmltype;

  -- сериализация
  function serialize(p_doc xmltype) return clob;

  -- сериализация
  function serialize(p_doc dbms_xmldom.DOMDocument) return clob;

  -- печать xml
  procedure print(p_doc xmltype);

  -- печать xml
  procedure print(p_doc dbms_xmldom.DOMDocument);

  -- текст->bool
  function toBool(p_value varchar2) return boolean;

  -- текст->дата
  function toDate(p_value  varchar2,
                  p_format varchar2 default FMT_DATE) return date;

  -- текст->дата+время
  function toDateTime(p_value  varchar2,
                      p_format varchar2 default FMT_DATETIME) return date;

  -- xml boolean
  function xmlBool(p_value boolean) return varchar2;

  -- xml boolean
  function xmlBool(p_value integer) return varchar2;

  -- дата->текст
  function xmlDate(p_value  date,
                   p_format varchar2 default FMT_DATE) return varchar2;

  -- время->текст
  function xmlTime(p_value  date,
                   p_format varchar2 default FMT_TIME) return varchar2;

  -- дата+время->текст
  function xmlDateTime(p_value date) return varchar2;

  -- число->текст
  function xmlNumber(p_value number) return varchar2;

  -- namespace map
  function getNSmap(p_xmlns  varchar2,
                    p_prefix varchar2 default null) return varchar2;

  -- NLS Numeric Characters
  procedure setNlsNumeric(p_value varchar2);

  -- xml Entity
  function entity(p_text varchar2) return varchar2;

  -- xml unentity
  function unentity(p_text varchar2) return varchar2;

  -- объеденить
  function concat(p_doc1 xmltype,
                  p_doc2 xmltype default null,
                  p_doc3 xmltype default null,
                  p_doc4 xmltype default null) return xmltype;

  -- извлечь ноду по пути
  function extract(p_doc   xmltype,
                   p_xpath varchar2,
                   p_nsmap varchar2 default null) return xmltype;

  -- уничтожить ноду
  procedure freeNode(node dbms_xmldom.DOMNode);

  -- документ, владелец ноды
  function ownerDoc(node dbms_xmldom.DOMNode) return dbms_xmldom.DOMDocument;

  -- создать xml-документ
  function createDoc(rootNode out dbms_xmldom.DOMNode,
                     rootName varchar2) return dbms_xmldom.DOMDocument;

  -- создать ноду из документа
  function createNode(doc xmltype) return dbms_xmldom.DOMNode;

  -- создать дочернюю ноду
  function createNode(parentNode dbms_xmldom.DOMNode,
                      nodeName   varchar2) return dbms_xmldom.DOMNode;

  -- создать дочернюю ноду
  function createNode(parentNode dbms_xmldom.DOMNode,
                      nodeName   varchar2,
                      nodeValue  varchar2) return dbms_xmldom.DOMNode;

  -- создать дочернюю ноду
  procedure createNode(parentNode dbms_xmldom.DOMNode,
                       nodeName   varchar2,
                       nodeValue  varchar2 default null,
                       attrName   varchar2 default null,
                       attrValue  varchar2 default null);

  -- найти/создать дочернюю ноду
  function getChild(parentNode dbms_xmldom.DOMNode,
                    childName  varchar2,
                    childIndex integer default 0) return dbms_xmldom.DOMNode;

  -- текстовая под-нода
  function getTextNode(node dbms_xmldom.DOMNode) return dbms_xmldom.DOMText;

  -- текст  
  function getText(p_doc   xmltype,
                   p_xpath varchar2,
                   p_nsmap varchar2 default null) return varchar2;

  -- текстовое содержимое ноды
  function getText(node dbms_xmldom.DOMNode) return varchar2;

  -- логическое значение
  function getBool(p_doc   xmltype,
                   p_xpath varchar2,
                   p_nsmap varchar2 default null) return boolean;

  -- число с плавающей точкой
  function getNumber(p_doc   xmltype,
                     p_xpath varchar2,
                     p_nsmap varchar2 default null) return number;

  -- целое число
  function getInteger(p_doc   xmltype,
                      p_xpath varchar2,
                      p_nsmap varchar2 default null) return integer;
  -- дата
  function getDate(p_doc    xmltype,
                   p_xpath  varchar2,
                   p_format varchar2 default FMT_DATE) return date;

  -- дата+время
  function getDateTime(p_doc    xmltype,
                       p_xpath  varchar2,
                       p_format varchar2 default FMT_DATETIME) return date;

  -- прочитать атрибут
  function getAttrValue(p_node dbms_xmldom.DOMNode,
                        p_attr varchar2) return varchar2;

  -- установить значение ноды
  procedure setText(p_node  dbms_xmldom.DOMNode,
                    p_value varchar2);

  -- установить значение ноды
  procedure setClob(p_node  dbms_xmldom.DOMNode,
                    p_value clob);

  -- установить значение ноды
  procedure setBool(p_node  dbms_xmldom.DOMNode,
                    p_value boolean);

  -- установить значение ноды
  procedure setInteger(p_node  dbms_xmldom.DOMNode,
                       p_value integer);

  -- установить значение ноды
  procedure setNumber(p_node  dbms_xmldom.DOMNode,
                      p_value number);

  -- установить значение ноды
  procedure setDate(p_node  dbms_xmldom.DOMNode,
                    p_value date);

  -- установить значение ноды
  procedure setDateTime(p_node  dbms_xmldom.DOMNode,
                        p_value date);

  -- установить атрибут
  procedure setAttrValue(p_node  dbms_xmldom.DOMNode,
                         p_attr  varchar2 default null,
                         p_value varchar2 default null);

end;
/

