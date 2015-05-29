create or replace package body lib_mail is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 13.05.2015 14:25:17
  -- Purpose : Mailer Library

  cursor c_queue is
    select t.* from mail_queue t order by t.id for update;

  -- джоб очереди
  procedure job is
  
    b_attach boolean;
  begin
  
    -- читаем очередь
    for q in c_queue loop
    
      -- наличие аттача
      b_attach := q.file_name is not null and q.file_blob is not null;
    
      -- отправитель
      q.from_mail := nvl(q.from_mail, SENDER_MAIL);
      q.from_name := nvl(q.from_name, SENDER_NAME);
    
      -- не будим клиентов
      begin
      
        q.smtp_errm := null;
      
        if b_attach then
        
          -- отправка с аттачем
          send(p_mail      => q.mail,
               p_subject   => q.subject,
               p_message   => q.message,
               p_file_name => q.file_name,
               p_file_blob => q.file_blob,
               p_from_mail => q.from_mail,
               p_from_name => q.from_name);
        
        else
        
          -- отправка без аттача
          send(p_mail      => q.mail,
               p_subject   => q.subject,
               p_message   => q.message,
               p_from_mail => q.from_mail,
               p_from_name => q.from_name);
        
        end if;
      
      exception
        when others then
          q.smtp_errm := sqlerrm;
      end;
    
      if q.smtp_errm is null then
        delete from mail_queue t where t.id = q.id;
      else
        update mail_queue t set row = q where t.id = q.id;
      end if;
    end loop;
  
  end;

  -- функция для перекодировки заголовка письма в utf-8
  function utf8_encode(p_text varchar2) return varchar2 as
  
    a      varchar2(1000);
    b      varchar2(24);
    result varchar2(4000);
  begin
  
    a := p_text;
  
    while length(a) > 24 loop
    
      b := substr(a, 1, 24);
      a := substr(a, 25);
    
      result := result || '=?UTF-8?B?' ||
                utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(convert(b,
                                                                                              'utf8')))) || '?=';
    end loop;
  
    if length(a) > 0 then
    
      result := result || '=?UTF-8?B?' ||
                utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(convert(a,
                                                                                              'utf8')))) || '?=';
    end if;
  
    return result;
  end;

  procedure header(p_conn      in out utl_smtp.connection,
                   p_mail      in varchar2,
                   p_subject   in varchar2,
                   p_from_mail in varchar2 default SENDER_MAIL,
                   p_from_name in varchar2 default SENDER_NAME) is
  begin
  
    if p_mail is null then
      throw('ToMail not specified');
    elsif p_from_mail is null then
      throw('FromMail not specified');
    elsif p_from_name is null then
      throw('FromName not specified');
    end if;
  
    -- подтверждение установки связи
    utl_smtp.helo(p_conn, ib_conf.get_value('mail.smtp.server'));
  
    -- установка адреса отправителя
    utl_smtp.mail(p_conn, '<' || p_from_mail || '>');
  
    -- установка адреса получателя
    utl_smtp.rcpt(p_conn, '<' || p_mail || '>');
  
    -- отправка команды data, после которой можно начать передачу письма
    utl_smtp.open_data(p_conn);
  
    -- заголовки
    utl_smtp.write_data(p_conn,
                        'Date: ' || to_char(sysdate,
                                            'Dy, dd Mon yyyy hh24:mi:ss',
                                            'nls_date_language = english') || utl_tcp.crlf);
  
    utl_smtp.write_data(p_conn,
                        'From: ' || utf8_encode(p_from_name) || ' <' || p_from_mail || '>' ||
                        utl_tcp.crlf);
  
    utl_smtp.write_data(p_conn, 'To: ' || p_mail || utl_tcp.crlf);
  
    utl_smtp.write_raw_data(p_conn,
                            utl_raw.cast_to_raw('Subject: ' ||
                                                utf8_encode(nvl(p_subject, '(no subject)')) ||
                                                utl_tcp.crlf));
  
    -- прочие заголовки
    utl_smtp.write_data(p_conn, 'MIME-Version: 1.0' || utl_tcp.crlf);
  
    utl_smtp.write_data(p_conn, 'Content-Transfer-Encoding: 8bit' || utl_tcp.crlf);
  
  end;

  -- отправка письма
  procedure send(p_mail      in varchar2,
                 p_subject   in varchar2,
                 p_message   in varchar2,
                 p_from_mail in varchar2 default SENDER_MAIL,
                 p_from_name in varchar2 default SENDER_NAME) as
  
    conn utl_smtp.connection;
  begin
  
    -- установка соединения
    conn := utl_smtp.open_connection(ib_conf.get_value('mail.smtp.server'));
  
    -- заголовок      
    header(p_conn      => conn,
           p_mail      => p_mail,
           p_subject   => p_subject,
           p_from_mail => p_from_mail,
           p_from_name => p_from_name);
  
    -- текст письма
    utl_smtp.write_data(conn, 'Content-Type: text/plain; charset="Windows-1251"' || utl_tcp.crlf);
  
    utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw(utl_tcp.crlf || p_message || utl_tcp.crlf));
  
    -- завершение соединения
    utl_smtp.close_data(conn);
    utl_smtp.quit(conn);
  
  exception
    when others then
      utl_smtp.quit(conn);
      raise;
  end;

  -- отправка письма с вложением
  procedure send(p_mail      in varchar2,
                 p_subject   in varchar2,
                 p_message   in varchar2,
                 p_file_name in varchar2,
                 p_file_blob in blob,
                 p_from_mail in varchar2 default SENDER_MAIL,
                 p_from_name in varchar2 default SENDER_NAME) as
  
    conn     utl_smtp.connection;
    vraw     raw(54);
    length   integer := 0;
    offset   integer := 1;
    buffsize integer := 54;
    boundary varchar2(32);
  begin
  
    -- установка соединения
    conn := utl_smtp.open_connection(ib_conf.get_value('mail.smtp.server'));
  
    -- заголовок      
    header(p_conn      => conn,
           p_mail      => p_mail,
           p_subject   => p_subject,
           p_from_mail => p_from_mail,
           p_from_name => p_from_name);
  
    -- boundary
    boundary := dbms_random.string('a', 16);
    utl_smtp.write_data(conn,
                        'Content-Type: multipart/mixed; boundary= "' || boundary || '"' ||
                        utl_tcp.crlf);
  
    -- текст письма
    if p_message is not null then
    
      utl_smtp.write_data(conn, utl_tcp.crlf || '--' || boundary || utl_tcp.crlf);
    
      utl_smtp.write_data(conn, 'Content-Type: text/plain; charset="Windows-1251"' || utl_tcp.crlf);
    
      utl_smtp.write_data(conn, 'Content-Transfer-Encoding: 8bit' || utl_tcp.crlf);
    
      utl_smtp.write_raw_data(conn, utl_raw.cast_to_raw(utl_tcp.crlf || p_message || utl_tcp.crlf));
    end if;
  
    -- вложение
    utl_smtp.write_data(conn, '--' || boundary || utl_tcp.crlf);
  
    utl_smtp.write_data(conn, 'Content-Type: application/octet-stream' || utl_tcp.crlf);
  
    utl_smtp.write_data(conn, 'Content-Transfer-Encoding: base64' || utl_tcp.crlf);
  
    length := dbms_lob.getlength(p_file_blob);
    utl_smtp.write_data(conn,
                        'Content-Disposition: attachment; filename="' || p_file_name || '"; size=' ||
                        length || utl_tcp.crlf);
  
    utl_smtp.write_data(conn, utl_tcp.crlf);
  
    while offset < length loop
    
      vraw := null;
      dbms_lob.read(p_file_blob, buffsize, offset, vraw);
      utl_smtp.write_raw_data(conn, utl_encode.base64_encode(vraw));
      utl_smtp.write_data(conn, utl_tcp.crlf);
      offset := offset + buffsize;
    end loop;
  
    utl_smtp.write_data(conn, utl_tcp.crlf || '--' || boundary || '--' || utl_tcp.crlf);
    utl_smtp.close_data(conn);
    utl_smtp.quit(conn);
  
  exception
    when others then
      utl_smtp.quit(conn);
      raise;
  end;

  -- отправка письма с несколькими вложениями
  procedure send(p_mail      in varchar2,
                 p_subject   in varchar2,
                 p_message   in varchar2,
                 p_attaches  in t_attaches,
                 p_from_mail in varchar2 default SENDER_MAIL,
                 p_from_name in varchar2 default SENDER_NAME) is
  
  begin
  
    if p_attaches.count = 0 then
    
      send(p_mail      => p_mail,
           p_subject   => p_subject,
           p_message   => p_message,
           p_from_mail => p_from_mail,
           p_from_name => p_from_name);
    
    elsif p_attaches.count = 1 then
    
      send(p_mail      => p_mail,
           p_subject   => p_subject,
           p_message   => p_message,
           p_file_name => p_attaches(1).file_name,
           p_file_blob => p_attaches(1).file_blob,
           p_from_mail => p_from_mail,
           p_from_name => p_from_name);
    
    else
      throw('[%s] Multiple attachments not supported via this mail protocol');
    end if;
  
  end;

  -- поставить в очередь
  procedure enqueue(p_mail    in varchar2,
                    p_subject in varchar2,
                    p_message in varchar2) is
  begin
  
    enqueue(p_mail      => p_mail,
            p_subject   => p_subject,
            p_message   => p_message,
            p_from_mail => SENDER_MAIL,
            p_from_name => SENDER_NAME);
  end;

  -- поставить в очередь от имени
  procedure enqueue(p_mail      in varchar2,
                    p_subject   in varchar2,
                    p_message   in varchar2,
                    p_from_mail in varchar2,
                    p_from_name in varchar2) is
  
    q mail_queue%rowtype;
  begin
  
    q.mail      := p_mail;
    q.subject   := p_subject;
    q.message   := p_message;
    q.from_mail := p_from_mail;
    q.from_name := p_from_name;
  
    select ref_seq.nextval into q.id from dual;
    insert into mail_queue values q;
  end;

  -- поставить в очередь (с вложением)
  procedure enqueue(p_mail      in varchar2,
                    p_subject   in varchar2,
                    p_message   in varchar2,
                    p_file_name in varchar2,
                    p_file_blob in blob) is
  
    q mail_queue%rowtype;
  begin
  
    q.mail      := p_mail;
    q.subject   := p_subject;
    q.message   := p_message;
    q.file_name := p_file_name;
    q.file_blob := p_file_blob;
  
    select ref_seq.nextval into q.id from dual;
    insert into mail_queue values q;
  end;

end;
/

