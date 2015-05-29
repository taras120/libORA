create or replace function to_bool(val integer) return boolean is
begin

  -- Converts integer to boolean
  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora  
  -- (c) 1981-2014 Taras Lyuklyanchuk

  return sys.diutil.int_to_bool(val);
end;
/

