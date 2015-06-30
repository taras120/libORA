create or replace package lib_xml is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- XML DOM Library
  -- (c) 1981-2014 Taras Lyuklyanchuk

  -- constants
  XML_TRUE     constant varchar2(16) := 'true';
  XML_FALSE    constant varchar2(16) := 'false';
  FMT_DATE     constant varchar2(32) := 'yyyy-mm-dd';
  FMT_TIME     constant varchar2(32) := 'hh24:mi:ss';
  FMT_DATETIME constant varchar2(32) := FMT_DATE || 'T' || FMT_TIME;

  -- types
  type t_cursor is ref cursor;

  -- парсер
  function parse(p_clob clob) return xmltype;

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

  -- печать xml
  procedure print(p_node dbms_xmldom.DOMNode,
                  p_root dbms_xmldom.DOMNode default null);

  -- текст->bool
  function toBool(p_value varchar2) return boolean;

  -- текст->дата
  function toDate(p_value  varchar2,
                  p_format varchar2 default FMT_DATE) return date;

  -- текст->дата+время
  function toDateTime(p_value  varchar2,
                      p_format varchar2 default FMT_DATETIME) return date;

  -- текст->число
  function toNumber(p_value  varchar2,
                    p_format varchar2 default null) return number;

  -- текст->целое число
  function toInteger(p_value varchar2) return integer;

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

  -- целое число->текст
  function xmlInteger(p_value integer) return varchar2;

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

  -- создать документ
  function createDoc(p_clob clob) return dbms_xmldom.DOMDocument;

  -- создать документ
  function createDoc(p_doc xmltype) return dbms_xmldom.DOMDocument;

  -- создать xml-документ и корневую ноду
  function createDoc(p_root out dbms_xmldom.DOMNode,
                     p_name varchar2) return dbms_xmldom.DOMDocument;

  -- создать документ и корневую ноду
  function createDoc(p_name varchar2) return dbms_xmldom.DOMNode;

  -- создать документ из ноды
  function createDoc(p_node dbms_xmldom.DOMNode) return dbms_xmldom.DOMDocument;

  -- создать ноду из документа
  function createNode(p_doc xmltype) return dbms_xmldom.DOMNode;

  -- создать дочернюю ноду
  function createNode(p_parent dbms_xmldom.DOMNode,
                      p_name   varchar2) return dbms_xmldom.DOMNode;

  -- создать дочернюю ноду
  function createNode(p_parent dbms_xmldom.DOMNode,
                      p_name   varchar2,
                      p_value  varchar2) return dbms_xmldom.DOMNode;

  -- создать дочернюю ноду
  procedure createNode(p_parent     dbms_xmldom.DOMNode,
                       p_name       varchar2,
                       p_value      varchar2,
                       p_attr_name  varchar2 default null,
                       p_attr_value varchar2 default null);

  -- создать дочернюю ноду
  procedure createNode(p_parent dbms_xmldom.DOMNode,
                       p_name   varchar2,
                       p_value  boolean);

  -- создать дочернюю ноду
  procedure createNode(p_parent dbms_xmldom.DOMNode,
                       p_name   varchar2,
                       p_value  date);

  -- создать дочернюю ноду
  procedure createNode(p_parent dbms_xmldom.DOMNode,
                       p_name   varchar2,
                       p_value  number);

  -- добавить документ как ноду
  function appendChild(p_node  dbms_xmldom.DOMNode,
                       p_child xmltype) return dbms_xmldom.DOMNode;

  -- добавить документ как ноду
  procedure appendChild(p_node  dbms_xmldom.DOMNode,
                        p_child xmltype);

  -- добавить документ как ноду
  function appendChild(p_node  dbms_xmldom.DOMNode,
                       p_name  varchar2,
                       p_child xmltype) return dbms_xmldom.DOMNode;

  -- добавить документ как ноду
  procedure appendChild(p_node  dbms_xmldom.DOMNode,
                        p_name  varchar2,
                        p_child xmltype);

  -- уничтожить ноду
  procedure freeNode(p_node dbms_xmldom.DOMNode);

  -- документ, владелец ноды
  function ownerDoc(p_node dbms_xmldom.DOMNode) return dbms_xmldom.DOMDocument;

  -- проверка на Null
  function isNull(p_node dbms_xmldom.DOMNode) return boolean;

  -- проверка на Null
  function isNotNull(p_node dbms_xmldom.DOMNode) return boolean;

  -- текстовая нода?
  function isTextNode(p_node dbms_xmldom.DOMNode) return boolean;

  -- найти/создать дочернюю ноду
  function getChild(p_parent dbms_xmldom.DOMNode,
                    p_name   varchar2,
                    p_index  integer default 0) return dbms_xmldom.DOMNode;

  -- текстовая под-нода
  function getTextNode(p_node dbms_xmldom.DOMNode) return dbms_xmldom.DOMText;

  -- текст
  function getText(p_doc   xmltype,
                   p_xpath varchar2,
                   p_nsmap varchar2 default null) return varchar2;

  -- текстовое содержимое ноды
  function getText(p_node dbms_xmldom.DOMNode) return varchar2;

  -- текстовое содержимое ноды
  function getClob(p_node dbms_xmldom.DOMNode) return clob;

  -- логическое значение
  function getBool(p_doc   xmltype,
                   p_xpath varchar2,
                   p_nsmap varchar2 default null) return boolean;

  -- логическое значение
  function getBool(p_node dbms_xmldom.DOMNode) return boolean;

  -- число с плавающей точкой
  function getNumber(p_doc   xmltype,
                     p_xpath varchar2,
                     p_nsmap varchar2 default null) return number;

  -- число с плавающей точкой
  function getNumber(p_node dbms_xmldom.DOMNode) return number;

  -- целое число
  function getInteger(p_doc   xmltype,
                      p_xpath varchar2,
                      p_nsmap varchar2 default null) return integer;

  -- целое число
  function getInteger(p_node dbms_xmldom.DOMNode) return integer;

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

  -- SQL-совместимое содержимое ноды
  function getSQLValue(p_node dbms_xmldom.DOMNode) return varchar2;

  -- нода->xmltype
  function getXmlType(p_node dbms_xmldom.DOMNode) return xmltype;

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
  -- корневая нода
  function getRootNode(p_doc dbms_xmldom.DOMDocument) return dbms_xmldom.DOMNode;

  -- уровень ноды от корня
  function getNodeLevel(p_node dbms_xmldom.DOMNode) return integer;

  -- название ноды
  function getNodeName(p_node dbms_xmldom.DOMNode) return varchar2;

  -- hash map parser
  function parseHashMap(p_map  types.hashmap,
                        p_name varchar2) return xmltype;

  -- hash map serializer
  function serializeHashMap(p_xml xmltype) return types.hashmap;

end;
/

