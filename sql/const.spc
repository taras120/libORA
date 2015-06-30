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
  HRS_PER_DAY    constant integer := 24;
  MIN_PER_HOUR   constant integer := 60;
  SEC_PER_MINUTE constant integer := 60;
  SEC_PER_HOUR   constant integer := SEC_PER_MINUTE * MIN_PER_HOUR;
  MIN_PER_DAY    constant integer := HRS_PER_DAY * MIN_PER_HOUR;
  SEC_PER_DAY    constant integer := MIN_PER_DAY * SEC_PER_MINUTE;
  DATE_HOUR      constant number := 1 / HRS_PER_DAY;
  DATE_MINUTE    constant number := DATE_HOUR / MIN_PER_HOUR;
  DATE_SECOND    constant number := DATE_MINUTE / SEC_PER_MINUTE;

  -- charset id's
  UTF8    constant varchar2(16) := 'UTF8';
  CS_UTF8 constant integer := nls_charset_id(UTF8);

end;
/

