create or replace package lib_mail is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 13.05.2015 14:25:17
  -- Purpose : Mailer Library
  
  -- defaults
  SENDER_NAME varchar2(100) := lib_util.remote_os_user;
  SENDER_MAIL varchar2(100) := sprintf('%s@%s', user, lib_util.server_host_name);

  -- file attachment
  type t_attach is record(
    file_name varchar2(1000),
    file_blob blob);

  -- attachment array
  type t_attaches is table of t_attach;

  -- джоб очереди
  procedure job;

  -- отправка письма
  procedure send(p_mail      in varchar2,
                 p_subject   in varchar2,
                 p_message   in varchar2,
                 p_from_mail in varchar2 default SENDER_MAIL,
                 p_from_name in varchar2 default SENDER_NAME);

  -- отправка письма с вложением от имени
  procedure send(p_mail      in varchar2,
                 p_subject   in varchar2,
                 p_message   in varchar2,
                 p_file_name in varchar2,
                 p_file_blob in blob,
                 p_from_mail in varchar2 default SENDER_MAIL,
                 p_from_name in varchar2 default SENDER_NAME);

  -- отправка письма с несколькими вложениями
  procedure send(p_mail      in varchar2,
                 p_subject   in varchar2,
                 p_message   in varchar2,
                 p_attaches  in t_attaches,
                 p_from_mail in varchar2 default SENDER_MAIL,
                 p_from_name in varchar2 default SENDER_NAME);

  -- постановка в очередь
  procedure enqueue(p_mail    in varchar2,
                    p_subject in varchar2,
                    p_message in varchar2);

  -- поставить в очередь от имени
  procedure enqueue(p_mail      in varchar2,
                    p_subject   in varchar2,
                    p_message   in varchar2,
                    p_from_mail in varchar2,
                    p_from_name in varchar2);

  -- поставить в очередь (с вложением)
  procedure enqueue(p_mail      in varchar2,
                    p_subject   in varchar2,
                    p_message   in varchar2,
                    p_file_name in varchar2,
                    p_file_blob in blob);
end;
/

