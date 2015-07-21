create or replace package lib_map is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 15.07.2015 0:11:57
  -- Purpose : Map & Collection Library

  -- map turn
  function turn(p_map types.StringTable) return types.IntegerMap;

  -- backward map turn
  function turnbw(p_map types.StringTable) return types.IntegerMap;

  -- map turn
  function turn(p_map types.IntegerMap) return types.StringTable;

  -- backward map turn
  function turnbw(p_map types.IntegerMap) return types.StringTable;

  -- get keys by value
  function keys_by_value(p_map   types.StringTable,
                         p_value varchar2) return types.IntegerList;

  -- get keys by value
  function keys_by_value(p_map   types.IntegerMap,
                         p_value integer) return types.StringList;

end;
/

