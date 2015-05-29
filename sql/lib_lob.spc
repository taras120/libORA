create or replace package lib_lob is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 15.05.2015 0:11:57
  -- Purpose : Large Object Library

  -- raw cast
  function to_raw(input varchar2) return raw;

  -- blob to clob conversion
  function to_clob(p_blob blob) return clob;

  -- clob to blob conversion
  function to_blob(p_clob clob) return blob;

  -- print blob
  procedure print(p_blob blob);

  -- print clob
  procedure print(p_clob clob);

  -- print xmltype
  procedure print(p_xml xmltype);

  function substr(p_text   clob,
                  p_offset integer,
                  p_amount integer) return varchar2;

  function substring(p_text  clob,
                     p_begin integer,
                     p_end   integer) return varchar2;

  function instr(p_text    clob,
                 p_pattern varchar2,
                 p_offset  integer) return integer;

  function index_of(p_text    clob,
                    p_pattern varchar2,
                    p_offset  integer) return integer;

  procedure substitute(p_text    in out clob,
                       p_search  varchar2,
                       p_replace varchar2);

  -- base64 encode
  function b64_encode(p_blob blob) return clob;

  -- base64 encode
  function b64_encode(p_clob clob) return clob;

  -- base64 decode
  function b64_decode(p_clob clob) return blob;

  -- base64 decode
  function b64_decode(p_blob blob) return blob;

end;
/

