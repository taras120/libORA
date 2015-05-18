create or replace package const is

  -- LibORA PL/SQL Library
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.01.2015 14:23:29
  -- Purpose : Constants Header

  -- chars
  CR   constant char(1) := chr(13);
  LF   constant char(1) := chr(10);
  SPC  constant char(1) := chr(32);
  AMP  constant char(1) := chr(38);
  CRLF constant char(2) := CR || LF;

  -- integer boolean
  I_TRUE  constant integer := to_int(true);
  I_FALSE constant integer := to_int(false);

  -- date/time
  D_HOUR   constant number := 1 / 24;
  D_MINUTE constant number := D_HOUR / 60;
  D_SECOND constant number := D_MINUTE / 60;

  -- charset id's
  UTF8    constant varchar2(16) := 'UTF8';
  CS_UTF8 constant integer := nls_charset_id(UTF8);

end;
/

