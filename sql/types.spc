create or replace package types is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
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

  -- <key,value> hash maps
  type hmap_vv is table of varchar2(4000) index by varchar2(4000);
  type hmap_vi is table of integer index by varchar2(4000);
  type hmap_vd is table of date index by varchar2(4000);
  type hmap_iv is table of varchar2(4000) index by binary_integer;
  type hmap_ii is table of integer index by binary_integer;
  type hmap_id is table of date index by binary_integer;

end;
/

