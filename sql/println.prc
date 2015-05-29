create or replace procedure println(text varchar2 default null) is

  -- Formatted DBMS-OUT Printing
  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora  
  -- (c) 1981-2014 Taras Lyuklyanchuk

begin

  dbms_output.put_line(text);
end;
/

