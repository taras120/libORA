create or replace package types is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.01.2015 14:23:29
  -- Purpose : Common Usage PL/SQL Types

  -- varchar2(max)
  varchar2_max varchar2(4000) := null;
  varchar2_pls varchar2(32767) := null;

  -- refcursor
  type RefCursor is ref cursor;

  -- simple lists
  type List is table of varchar2_max%type;
  type StringList is table of varchar2_max%type;
  type NumberList is table of number;
  type IntegerList is table of integer;
  type DateList is table of date;

  -- cubes (array of lists)
  type StringCube is table of StringList;
  type NumberCube is table of NumberList;
  type IntegerCube is table of IntegerList;
  type DateCube is table of DateList;

  -- hashmap
  type HashMap is table of varchar2_max%type index by varchar2_max%type;

  -- table of hashmaps
  type HashTable is table of HashMap index by binary_integer;

  -- hashmap of clob
  type ClobHashMap is table of clob index by varchar2_max%type;

  -- array types
  type StringArray is table of varchar2_max%type;
  type NumberArray is table of number;
  type IntegerArray is table of integer;
  type DateArray is table of date;

  -- <str,value> maps
  type StringMap is table of varchar2_max%type index by varchar2_max%type;
  type NumberMap is table of number index by varchar2_max%type;
  type IntegerMap is table of integer index by varchar2_max%type;
  type DateMap is table of date index by varchar2_max%type;

  -- <int,value> maps
  type StringTable is table of varchar2_max%type index by binary_integer;
  type NumberTable is table of number index by binary_integer;
  type IntegerTable is table of integer index by binary_integer;
  type DateTable is table of date index by binary_integer;

end;
/

