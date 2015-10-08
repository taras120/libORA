create or replace type body t_soap as

  /*
   * LibORA PL/SQL Library
   * http://bitbucket.org/rtfm/libora
   * Author  : Taras Lyuklyanchuk
   * Created : 26.05.2013 10:23:29
   * Purpose : HTTP SOAP Client
  **/

  constructor function t_soap(p_ws_url     varchar2,
                              p_ws_ns      varchar2,
                              p_ws_method  varchar2,
                              p_timeout    integer default 30,
                              p_username   varchar2 default null,
                              p_password   varchar2 default null,
                              p_persistent integer default 0) return self as result as
  begin

    -- defaults
    self.debug        := 0;
    self.http_ok      := utl_http.HTTP_OK;
    self.http_method  := 'POST';
    self.http_charset := 'UTF-8';
    self.xml_charset  := 'UTF8';
    self.content_type := sprintf('text/xml; charset=%s', lower(self.http_charset));
    self.ws_ns        := p_ws_ns;
    self.ws_url       := p_ws_url;
    self.ws_method    := p_ws_method;
    self.hdrp         := t_nvp_list();
    self.reqp         := t_nvp_list();
    self.timeout      := p_timeout;
    self.username     := p_username;
    self.password     := p_password;
    self.persistent   := p_persistent;

    self.build();
    return;
  end;

  member procedure log(p_text varchar2,
                       p_prm1 varchar2 default null,
                       p_prm2 varchar2 default null,
                       p_prm3 varchar2 default null,
                       p_prm4 varchar2 default null,
                       p_prm5 varchar2 default null,
                       p_prm6 varchar2 default null,
                       p_prm7 varchar2 default null) is
  begin

    if self.debug != 0 then
      printlnf(p_text, p_prm1, p_prm2, p_prm3, p_prm4, p_prm5, p_prm6, p_prm7);
    end if;
  end;

  member procedure set_header(p_xml xmltype) as
  begin
    hdrx := p_xml;
    build();
  end;

  member procedure set_request(p_xml xmltype) as
  begin
    reqx := p_xml;
    build();
  end;

  member procedure set_header(p_tag   varchar2,
                              p_value varchar2,
                              p_type  varchar2 default null) as
  begin

    hdrp.extend();
    hdrp(hdrp.last) := t_nvp(p_tag, p_value, p_type);

    build();
  end;

  member procedure set_request(p_tag   varchar2,
                               p_value varchar2,
                               p_type  varchar2 default null) as
  begin

    reqp.extend();
    reqp(reqp.last) := t_nvp(p_tag, p_value, p_type);

    build();
  end;

  member procedure build as

    doc       dbms_xmldom.DOMDocument;
    docx      dbms_xmldom.DOMDocument;
    eEnvelope dbms_xmldom.DOMElement;
    eHeader   dbms_xmldom.DOMElement;
    eBody     dbms_xmldom.DOMElement;
    eMethodH  dbms_xmldom.DOMElement;
    eMethodB  dbms_xmldom.DOMElement;
    eParam    dbms_xmldom.DOMElement;
    eToken    dbms_xmldom.DOMElement;
    nEnvelope dbms_xmldom.DOMNode;
    nHeader   dbms_xmldom.DOMNode;
    nBody     dbms_xmldom.DOMNode;
    nToken    dbms_xmldom.DOMNode;
    nMethodH  dbms_xmldom.DOMNode;
    nMethodB  dbms_xmldom.DOMNode;
    nPayloadH dbms_xmldom.DOMNode;
    nPayloadB dbms_xmldom.DOMNode;
    tag       dbms_xmldom.DOMNode;
    text      dbms_xmldom.DOMText;
  begin

    -- namespace
    ns_xsi := 'http://www.w3.org/2001/XMLSchema-instance';
    ns_xsd := 'http://www.w3.org/2001/XMLSchema';
    -- ns_soap := http://www.w3.org/2003/05/soap-envelop
    ns_soap := nvl(ns_soap, 'http://schemas.xmlsoap.org/soap/envelope/');
    ns_wsse := 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd';

    -- document
    doc := dbms_xmldom.newDOMDocument;

    -- envelope
    eEnvelope := dbms_xmldom.createElement(doc, 'soap:Envelope');

    -- dbms_xmldom.setAttribute(eEnvelope, 'xmlns:xsi', xmlns_xsi);
    -- dbms_xmldom.setAttribute(eEnvelope, 'xmlns:xsd', xmlns_xsd);
    dbms_xmldom.setAttribute(eEnvelope, 'xmlns:soap', ns_soap);

    nEnvelope := dbms_xmldom.appendChild(dbms_xmldom.makeNode(doc), dbms_xmldom.makeNode(eEnvelope));

    -- header
    if username is not null or hdrx is not null or hdrp.count > 0 then
      eHeader := dbms_xmldom.createElement(doc, 'soap:Header');
      nHeader := dbms_xmldom.appendChild(nEnvelope, dbms_xmldom.makeNode(eHeader));
      -- security token
      if username is not null then

        eToken := dbms_xmldom.createElement(doc, 'wsse:Security');
        dbms_xmldom.setAttribute(eToken, 'xmlns:wsse', ns_wsse);

        nToken := dbms_xmldom.appendChild(nHeader, dbms_xmldom.makeNode(eToken));

        eToken := dbms_xmldom.createElement(doc, 'wsse:UsernameToken');
        nToken := dbms_xmldom.appendChild(nToken, dbms_xmldom.makeNode(eToken));

        -- username
        eParam := dbms_xmldom.createElement(doc, 'wsse:Username');
        tag    := dbms_xmldom.makeNode(eParam);
        tag    := dbms_xmldom.appendChild(nToken, tag);
        text   := dbms_xmldom.createTextNode(doc, username);
        tag    := dbms_xmldom.appendChild(tag, dbms_xmldom.makeNode(text));

        dbms_xmldom.freeNode(tag);

        -- password
        eParam := dbms_xmldom.createElement(doc, 'wsse:Password');
        tag    := dbms_xmldom.makeNode(eParam);
        tag    := dbms_xmldom.appendChild(nToken, tag);
        text   := dbms_xmldom.createTextNode(doc, password);
        tag    := dbms_xmldom.appendChild(tag, dbms_xmldom.makeNode(text));
      end if;

      -- method header
      eMethodH := dbms_xmldom.createElement(doc, sprintf('q:%sHeader', ws_method));

      dbms_xmldom.setAttribute(eMethodH, 'xmlns:q', ws_ns);

      nMethodH := dbms_xmldom.appendChild(nHeader, dbms_xmldom.makeNode(eMethodH));

      -- method header parameters
      for i in 1 .. hdrp.count loop

        eParam := dbms_xmldom.createElement(doc, hdrp(i).name);
        tag    := dbms_xmldom.makeNode(eParam);
        tag    := dbms_xmldom.appendChild(nMethodH, tag);
        text   := dbms_xmldom.createTextNode(doc, hdrp(i).value);
        tag    := dbms_xmldom.appendChild(tag, dbms_xmldom.makeNode(text));

        if hdrp(i).type is not null then
          dbms_xmldom.setAttribute(eParam, 'xsi:type', hdrp(i).type);
        end if;
      end loop;

      -- header payload
      if hdrx is not null then

        docx      := dbms_xmldom.newDOMDocument(hdrx);
        nPayloadH := dbms_xmldom.makeNode(dbms_xmldom.getDocumentElement(docx));
        nPayloadH := dbms_xmldom.importNode(doc, nPayloadH, true);
        nPayloadH := dbms_xmldom.appendChild(nMethodH, nPayloadH);

        dbms_xmldom.freeNode(nPayloadH);
        dbms_xmldom.freeDocument(docx);
      end if;
    end if;

    -- body
    eBody := dbms_xmldom.createElement(doc, 'soap:Body');
    nBody := dbms_xmldom.appendChild(nEnvelope, dbms_xmldom.makeNode(eBody));

    -- method body
    eMethodB := dbms_xmldom.createElement(doc, sprintf('q:%s', ws_method));

    dbms_xmldom.setAttribute(eMethodB, 'xmlns:q', ws_ns);

    nMethodB := dbms_xmldom.appendChild(nBody, dbms_xmldom.makeNode(eMethodB));

    -- method body parameters
    for i in 1 .. reqp.count loop

      eParam := dbms_xmldom.createElement(doc, reqp(i).name);
      tag    := dbms_xmldom.makeNode(eParam);
      tag    := dbms_xmldom.appendChild(nMethodB, tag);
      text   := dbms_xmldom.createTextNode(doc, reqp(i).value);
      tag    := dbms_xmldom.appendChild(tag, dbms_xmldom.makeNode(text));

      if reqp(i).type is not null then
        dbms_xmldom.setAttribute(eParam, 'xsi:type', reqp(i).type);
      end if;
    end loop;

    -- request payload
    if reqx is not null then

      docx      := dbms_xmldom.newDOMDocument(reqx);
      nPayloadB := dbms_xmldom.makeNode(dbms_xmldom.getDocumentElement(docx));
      nPayloadB := dbms_xmldom.importNode(doc, nPayloadB, true);
      nPayloadB := dbms_xmldom.appendChild(nMethodB, nPayloadB);

      dbms_xmldom.freeNode(nPayloadB);
      dbms_xmldom.freeDocument(docx);
    end if;

    envelope := dbms_xmldom.getxmltype(doc);
    dbms_xmldom.freeDocument(doc);
  end;

  member procedure invoke as

    i            integer;
    req          utl_http.req;
    resp         utl_http.resp;
    req_raw      long raw;
    req_blob     blob;
    req_length   integer;
    resp_raw     long raw;
    resp_blob    blob;
    resp_clob    clob;
    resp_length  integer;
    offset       integer;
    lang_context integer;
    warning      integer;
    ena_pconn    boolean;
    max_conns    integer;
  begin

    -- параметры
    utl_http.set_proxy(null);
    utl_http.set_body_charset(http_charset);
    utl_http.set_transfer_timeout(timeout);
    utl_http.set_response_error_check(false);
    utl_http.set_detailed_excp_support(true);

    -- постоянное соединение
    utl_http.set_persistent_conn_support(enable    => self.persistent != 0,
                                         max_conns => self.persistent);

    -- нагрузка
    dbms_lob.createTemporary(req_blob, true);
    dbms_lob.createTemporary(resp_blob, true);

    req_blob := envelope.getblobval(nls_charset_id(XML_CHARSET));

    req_length := dbms_lob.getLength(req_blob);
    dbms_lob.read(req_blob, req_length, 1, req_raw);

    log('URL: %s', ws_url);
    log('Length: %s', req_length);

    i := 0;
    loop
      begin

        -- коннект
        req := utl_http.begin_request(url          => ws_url,
                                      method       => HTTP_METHOD,
                                      http_version => utl_http.HTTP_VERSION_1_1);

        exit when req.private_hndl is not null;

      exception
        when others then

          log(sqlerrm);

          if i < 3 and sqlcode in (-12541) then
            i := i + 1; -- try again
            log('Try to reconnect...(%s)', i);
          else
            raise;
          end if;
      end;
    end loop;

    -- постоянное соединение
    utl_http.get_persistent_conn_support(enable => ena_pconn, max_conns => max_conns);

    if ena_pconn then

      utl_http.set_persistent_conn_support(req, true);
      utl_http.set_header(req, 'Connection', 'Keep-Alive');
      log('[%s] Connected via persistent connection', max_conns);

    elsif self.persistent != 0 then
      log('Host does not support persistent connections');
    else
      log('Persistent connections are disabled');
    end if;

    -- заголовки
    utl_http.set_header(req, 'Content-Type', content_type);
    utl_http.set_header(req, 'Content-Length', req_length);

    -- запрос
    if debug != 0 then
      log('Request:');
      lib_lob.print(envelope.getclobval);
    end if;

    -- пишем в сокет
    utl_http.write_raw(req, req_raw);

    -- ответ
    resp := utl_http.get_response(req);

    -- код ответа HTTP
    httpcode := resp.status_code;

    log('Status code: %s', resp.status_code);
    log('Reason phrase: %s ', resp.reason_phrase);

    -- длинна ответа
    begin

      utl_http.get_header_by_name(r => resp, name => 'Content-Length', value => resp_length);

    exception
      when utl_http.header_not_found then
        resp_length := null;
      when others then
        raise;
    end;

    if resp_length is not null then
      log('Response Length: %s', resp_length);
    else
      log('Response Length: n/a');
    end if;

    begin
      loop
        utl_http.read_raw(resp, resp_raw);

        dbms_lob.writeAppend(lob_loc => resp_blob,
                             amount  => utl_raw.length(resp_raw),
                             buffer  => resp_raw);
      end loop;

    exception
      when utl_http.end_of_body then

        req := null; -- зер гуд
        utl_http.end_response(resp);

      when others then

        if debug != 0 then
          lib_lob.print(resp_blob);
        end if;

        raise;
    end;

    -- ответ
    if debug != 0 then
      lib_lob.print(resp_blob);
    end if;

    -- результат
    if resp.status_code in (utl_http.HTTP_OK, http_ok) then

      -- преобразуем в CLOB
      dbms_lob.createTemporary(resp_clob, true);

      offset       := 1;
      lang_context := 0;

      dbms_lob.convertToClob(dest_lob     => resp_clob,
                             src_blob     => resp_blob,
                             amount       => dbms_lob.getLength(resp_blob),
                             dest_offset  => offset,
                             src_offset   => offset,
                             blob_csid    => nls_charset_id(xml_charset),
                             lang_context => lang_context,
                             warning      => warning);

      if debug * warning != 0 then
        printlnf('Warning: [%s]', warning);
        lib_lob.print(resp_clob);
      end if;

      -- XML
      response := xmltype(resp_clob);

      log('Response: %s', iif(response is null, 'NULL', 'OK'));

      -- тело конверта
      response := response.Extract('/soap:Envelope/soap:Body/*',
                                   sprintf('xmlns:soap="%s"', ns_soap));

    else
      throw('HTTP/%s %s', resp.status_code, resp.reason_phrase);
    end if;

  exception
    when others then

      log(sqlerrm);
      log(dbms_utility.format_error_backtrace);

      if req.private_hndl is not null then
        utl_http.end_request(req);
      end if;

      raise;
  end;

  member function get_response(p_tag varchar,
                               p_ns  varchar2 default null) return xmltype is
  begin

    return response.extract(sprintf('/q:%s/*', p_tag), sprintf('xmlns:q="%s"', nvl(p_ns, ws_ns)));
  end;

end;
/

