create or replace function sqltext(p_errm varchar2 default sqlerrm)
  return varchar2 is
  text varchar2(1000);
begin

  -- Returns truncated error message text
  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- (c) 1981-2014 Taras Lyuklyanchuk

  text := trim(substr(p_errm, 1, 1000));

  loop
    if text like 'ORA-%:%' then
      text := trim(substr(text, instr(text, ':') + 1));
    else
      exit;
    end if;
  end loop;

  return text;
end;
/

