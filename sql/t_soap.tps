create or replace type t_soap as object
(

/*
 * LibORA PL/SQL Library
 * Author  : Taras Lyuklyanchuk
 * Created : 26.05.2013 10:23:29
 * Purpose : HTTP SOAP Client
 */

  debug        integer,
  ns_xsi       varchar2(128),
  ns_xsd       varchar2(128),
  ns_wsse      varchar2(128),
  ns_soap      varchar2(128),
  ws_ns        varchar2(128),
  ws_url       varchar2(512),
  ws_method    varchar2(128),
  http_ok      integer,
  http_method  varchar2(4),
  http_charset varchar2(16),
  xml_charset  varchar2(16),
  username     varchar2(32),
  password     varchar2(32),
  persistent   integer,
  memo1        varchar2(128),
  memo2        varchar2(128),
  memo3        varchar2(128),
  memo4        varchar2(128),
  timeout      integer,
  httpcode     integer,
  envelope     xmltype,
  response     xmltype,
  hdrx         xmltype,
  reqx         xmltype,
  hdrp         t_nvp_list,
  reqp         t_nvp_list,

  constructor function t_soap(p_ws_url     varchar2,
                              p_ws_ns      varchar2,
                              p_ws_method  varchar2,
                              p_timeout    integer default 30,
                              p_username   varchar2 default null,
                              p_password   varchar2 default null,
                              p_persistent integer default 0) return self as result,

  member procedure log(p_text varchar2,
                       p_prm1 varchar2 default null,
                       p_prm2 varchar2 default null,
                       p_prm3 varchar2 default null,
                       p_prm4 varchar2 default null,
                       p_prm5 varchar2 default null,
                       p_prm6 varchar2 default null,
                       p_prm7 varchar2 default null),

  member procedure set_header(p_xml xmltype),

  member procedure set_request(p_xml xmltype),

  member procedure set_header(p_tag   varchar2,
                              p_value varchar2,
                              p_type  varchar2 default null),

  member procedure set_request(p_tag   varchar2,
                               p_value varchar2,
                               p_type  varchar2 default null),

  member procedure build,

  member procedure invoke,

  member function get_response(p_tag varchar,
                               p_ns  varchar2 default null) return xmltype

)
/

