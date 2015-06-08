create or replace package types is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.01.2015 14:23:29
  -- Purpose : Common Usage PL/SQL Types

  -- refcursor
  type RefCursor is ref cursor;

  -- array list
  type List is table of varchar2(4000);

  -- hashmap
  type HashMap is table of varchar2(4000) index by varchar2(4000);

  -- table of hashmaps
  type HashTable is table of hashmap index by binary_integer;

  -- hashmap of clob
  type ClobHashMap is table of clob index by varchar2(4000);

  -- array types
  type StringArray is table of varchar2(4000);
  type NumberArray is table of number;
  type IntegerArray is table of integer;
  type DateArray is table of date;

  -- <str,value> maps
  type StringMap is table of varchar2(4000) index by varchar2(4000);
  type NumberMap is table of number index by varchar2(4000);
  type IntegerMap is table of integer index by varchar2(4000);
  type DateMap is table of date index by varchar2(4000);

  -- <int,value> maps
  type StringTable is table of varchar2(4000) index by binary_integer;
  type NumberTable is table of number index by binary_integer;
  type IntegerTable is table of integer index by binary_integer;
  type DateTable is table of date index by binary_integer;

end;
/

