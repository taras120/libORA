create or replace package types is

  -- LibORA PL/SQL Library
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.01.2015 14:23:29
  -- Purpose : Common Usage PL/SQL Types

  -- refcursor
  type refcursor is ref cursor;

  -- array list
  type list is table of varchar2(4000);

  -- hashmap
  type hash_map is table of varchar2(4000) index by varchar2(4000);

  -- list of hashmaps
  type map_list is table of hash_map index by binary_integer;

  -- <key,value> maps
  type mapVV is table of varchar2(4000) index by varchar2(4000);
  type mapVI is table of integer index by varchar2(4000);
  type mapVD is table of date index by varchar2(4000);
  type mapIV is table of varchar2(4000) index by binary_integer;
  type mapII is table of integer index by binary_integer;
  type mapID is table of date index by binary_integer;

end;
/

