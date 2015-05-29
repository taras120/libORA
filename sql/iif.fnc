create or replace function iif(cond boolean, arg1 varchar2, arg2 varchar2)
  return varchar2 is
begin
  
  -- IIF implementation
  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora  
  -- (c) 1981-2014 Taras Lyuklyanchuk

  if cond then
    return arg1;
  else
    return arg2;
  end if;
end;
/

