create or replace package lib_util is

  -- LibORA PL/SQL Library
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.11.2014 11:37:59  
  -- Purpose : PL/SQL Utillity Functions

  function this_user return all_users%rowtype;

  function this_schema return varchar2;

  function this_sid return integer;

  function this_sessionid return integer;

  function server_db_name return varchar2;

  function server_host_name return varchar2;

  function server_host_address return varchar2;

  function remote_os_user return varchar2;

  function remote_terminal return varchar2;

  function remote_host_name return varchar2;

  function remote_host_address return varchar2;

  procedure sleep(ms integer);

end;
/

