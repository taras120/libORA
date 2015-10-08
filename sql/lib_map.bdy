create or replace package body lib_map is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 15.07.2015 0:11:57
  -- Purpose : Map & Collection Library

  -- map turn
  function turn(p_map types.StringTable) return types.IntegerMap is
  
    key    integer;
    result types.IntegerMap;
  begin
  
    key := p_map.first;
  
    while key is not null loop
    
      result(p_map(key)) := key;
      key := p_map.next(key);
    end loop;
  
    return result;
  end;

  -- backward map turn
  function turnbw(p_map types.StringTable) return types.IntegerMap is
  
    key    integer;
    result types.IntegerMap;
  begin
  
    key := p_map.last;
  
    while key is not null loop
    
      result(p_map(key)) := key;
      key := p_map.prior(key);
    end loop;
  
    return result;
  end;

  -- map turn
  function turn(p_map types.IntegerMap) return types.StringTable is
  
    key    varchar2(4000);
    result types.StringTable;
  begin
  
    key := p_map.first;
  
    while key is not null loop
    
      result(p_map(key)) := key;
      key := p_map.next(key);
    end loop;
  
    return result;
  end;

  -- backward map turn
  function turnbw(p_map types.IntegerMap) return types.StringTable is
  
    key    varchar2(4000);
    result types.StringTable;
  begin
  
    key := p_map.last;
  
    while key is not null loop
    
      result(p_map(key)) := key;
      key := p_map.prior(key);
    end loop;
  
    return result;
  end;

  -- get keys by value
  function keys_by_value(p_map   types.StringTable,
                         p_value varchar2) return types.IntegerList is
  
    key    integer;
    result types.IntegerList := types.IntegerList();
  begin
  
    key := p_map.first;
  
    while key is not null loop
    
      if p_map(key) = p_value then
      
        result.extend;
        result(result.last) := key;
      end if;
    
      key := p_map.next(key);
    end loop;
  
    return result;
  end;

  -- get keys by value
  function keys_by_value(p_map   types.IntegerMap,
                         p_value integer) return types.StringList is
  
    key    types.varchar2_max%type;
    result types.StringList := types.StringList();
  begin
  
    key := p_map.first;
  
    while key is not null loop
    
      if p_map(key) = p_value then
      
        result.extend;
        result(result.last) := key;
      end if;
    
      key := p_map.next(key);
    end loop;
  
    return result;
  end;

end;
/

