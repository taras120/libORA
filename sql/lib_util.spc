create or replace package lib_util is

  -- LibORA PL/SQL Library
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.11.2014 11:37:59  
  -- Purpose : PL/SQL Utillity Functions

  function this_user return all_users%rowtype;

  function this_schema return varchar2;

  function this_sid return integer;

  function this_sessionid return integer;

  function this_server_host return varchar2;

  function session_os_user return varchar2;

  function session_terminal return varchar2;

  function session_client_ip return varchar2;

  procedure sleep(ms integer);

end;
/

