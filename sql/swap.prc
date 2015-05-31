create or replace procedure swap(a in out varchar2,
                                 b in out varchar2) is
  tmp varchar2(4000);
begin

  -- Swap arguments values
  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- (c) 1981-2014 Taras Lyuklyanchuk

  tmp := a;
  a   := b;
  b   := tmp;
end;
/

