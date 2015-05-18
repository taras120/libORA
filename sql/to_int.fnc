create or replace function to_int(val boolean) return integer is
begin

  -- Converts boolean to integer
  -- LibORA PL/SQL Library
  -- (c) 1981-2014 Taras Lyuklyanchuk  

  return sys.diutil.bool_to_int(val);
end;
/

