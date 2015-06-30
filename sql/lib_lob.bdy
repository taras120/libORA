create or replace package body lib_lob is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 15.05.2015 0:11:57
  -- Purpose : Large Object Library

  BUFF_SIZE constant integer := 4000;

  function split(p_clob  clob,
                 p_delim varchar2) return types.list is
  
    offset    integer := 1;
    amount    integer;
    clob_len  integer;
    delim_len integer;
    list      types.list := types.list();
  begin
  
    if p_clob is not null and p_delim is not null then
    
      delim_len := length(p_delim);
      clob_len  := dbms_lob.getLength(p_clob);
    
      while offset < clob_len loop
      
        amount := instr(p_clob, p_delim, offset);
      
        if amount <= 0 then
          amount := clob_len - offset + 1;
        else
          amount := amount - offset;
        end if;
      
        list.extend;
        dbms_lob.read(lob_loc => p_clob,
                      amount  => amount,
                      offset  => offset,
                      buffer  => list(list.last));
      
        offset := offset + amount + delim_len;
      end loop;
    end if;
  
    return list;
  end;

  -- print clob
  procedure print(p_clob clob) is
  
    lines      types.list;
    line_delim varchar2(2);
  begin
  
    if p_clob is not null then
    
      -- detect line separator
      if instr(p_clob, const.CRLF) != 0 then
        line_delim := const.CRLF;
      else
        line_delim := const.LF;
      end if;
    
      -- split by lines
      lines := split(p_clob, line_delim);
    
      for i in 1 .. lines.count loop
        println(lines(i));
      end loop;
    end if;
  end;

  -- print clob
  procedure print2(p_clob clob) is
  
    amount   integer;
    offset   integer := 1;
    buffsize integer := BUFF_SIZE;
    clobsize integer;
  begin
  
    clobsize := dbms_lob.getLength(p_clob);
  
    if p_clob is not null then
    
      for i in 1 .. ceil(clobsize / buffsize) loop
      
        amount := least(buffsize, clobsize - offset + 1);
        println(dbms_lob.substr(p_clob, amount, offset));
      
        offset := offset + amount;
      end loop;
    end if;
  end;

  -- print blob
  procedure print(p_blob blob) is
  begin
    print(to_clob(p_blob));
  end;

  -- print xmltype
  procedure print(p_xml xmltype) is
  begin
  
    if p_xml is not null then
      print(p_xml.getclobval());
    end if;
  end;

  function substr(p_text   clob,
                  p_offset integer,
                  p_amount integer) return varchar2 is
  begin
  
    return dbms_lob.substr(lob_loc => p_text, offset => p_offset, amount => p_amount);
  end;

  function substring(p_text  clob,
                     p_begin integer,
                     p_end   integer) return varchar2 is
  begin
  
    return substr(p_text, p_begin, p_end - p_begin + 1);
  end;

  function instr(p_text    clob,
                 p_pattern varchar2,
                 p_offset  integer default 1) return integer is
  begin
  
    return nvl(dbms_lob.instr(lob_loc => p_text,
                              pattern => p_pattern,
                              offset  => p_offset,
                              nth     => 1),
               0);
  end;

  function size_of(p_blob blob) return integer is
  begin
    return dbms_lob.getLength(p_blob);
  end;

  function size_of(p_clob clob) return integer is
  begin
    return dbms_lob.getLength(p_clob);
  end;

  function index_of(p_text    clob,
                    p_pattern varchar2,
                    p_offset  integer) return integer is
  begin
  
    return instr(p_text, p_pattern, p_offset);
  end;

  procedure substitute(p_text    in out clob,
                       p_search  varchar2,
                       p_replace varchar2) is
  begin
  
    p_text := replace(p_text, p_search, p_replace);
  end;

  -- пустой clob
  /*
  function new_clob return clob is
    result clob;
  begin
  
    insert into tmp_clob (clob) values (empty_clob()) returning clob into result;
  
    return result;
  end;
  */

  -- пустой clob
  function new_clob return clob is
    result clob;
  begin
  
    dbms_lob.createTemporary(result, true);
  
    return result;
  end;

  -- пустой blob
  function new_blob return blob is
    result blob;
  begin
  
    dbms_lob.createTemporary(result, true);
  
    return result;
  end;

  -- raw cast
  function to_raw(input varchar2) return raw is
  begin
    return utl_raw.cast_to_raw(input);
  end;

  -- blob to clob conversion
  function to_clob(p_blob blob) return clob as
  
    buff     varchar2(32767);
    buffsize integer := BUFF_SIZE;
    offset   integer := 1;
    result   clob;
  begin
  
    if p_blob is not null then
    
      dbms_lob.createTemporary(result, true);
    
      for i in 1 .. ceil(dbms_lob.getLength(p_blob) / buffsize) loop
      
        buff := utl_raw.cast_to_varchar2(dbms_lob.substr(p_blob, buffsize, offset));
      
        dbms_lob.writeAppend(result, length(buff), buff);
      
        offset := offset + length(buff);
      end loop;
    end if;
  
    return result;
  end;

  -- blob to clob conversion
  function to_clob(p_blob blob,
                   p_csid integer) return clob as
  
    result       clob := new_clob();
    src_offset   integer := 1;
    dest_offset  integer := 1;
    lang_context integer := dbms_lob.default_lang_ctx;
    warning      integer;
  begin
  
    dbms_lob.convertToClob(dest_lob     => result,
                           src_blob     => p_blob,
                           amount       => size_of(p_blob),
                           src_offset   => src_offset,
                           dest_offset  => dest_offset,
                           blob_csid    => p_csid,
                           lang_context => lang_context,
                           warning      => warning);
  
    return result;
  end;

  -- clob to blob conversion
  function to_blob(p_clob clob) return blob as
  
    buff     varchar2(32767);
    buffsize integer := BUFF_SIZE;
    offset   integer := 1;
    result   blob;
  begin
  
    if p_clob is not null then
    
      dbms_lob.createTemporary(result, true);
    
      for i in 1 .. ceil(dbms_lob.getLength(p_clob) / buffsize) loop
      
        buff := utl_raw.cast_to_varchar2(dbms_lob.substr(p_clob, buffsize, offset));
      
        dbms_lob.writeAppend(result, length(buff), buff);
      
        offset := offset + length(buff);
      end loop;
    end if;
  
    return result;
  end;

  -- blob to clob conversion
  function to_blob(p_clob clob,
                   p_csid integer) return blob as
  
    result       blob := new_blob();
    src_offset   integer := 1;
    dest_offset  integer := 1;
    lang_context integer := dbms_lob.default_lang_ctx;
    warning      integer;
  begin
  
    dbms_lob.convertToBlob(dest_lob     => result,
                           src_clob     => p_clob,
                           amount       => size_of(p_clob),
                           src_offset   => src_offset,
                           dest_offset  => dest_offset,
                           blob_csid    => p_csid,
                           lang_context => lang_context,
                           warning      => warning);
  
    return result;
  end;

  -- base64 encode
  function b64_encode(p_blob blob) return clob is
  
    v_text     varchar2(32767);
    v_start    integer := 1;
    v_buffsize integer := BUFF_SIZE;
    v_length   integer;
    result     clob;
  begin
  
    if p_blob is not null then
    
      v_length := dbms_lob.getLength(p_blob);
    
      if v_length != 0 then
      
        for i in 1 .. ceil(v_length / v_buffsize) loop
        
          v_text := utl_raw.cast_to_varchar2(utl_encode.base64_encode(dbms_lob.substr(p_blob,
                                                                                      v_buffsize,
                                                                                      v_start)));
        
          dbms_lob.writeAppend(result, length(v_text), v_text);
          v_start := v_start + v_buffsize;
        end loop;
      end if;
    end if;
  
    return result;
  end;

  -- base64 encode
  function b64_encode(p_clob clob) return clob is
  begin
    return b64_encode(to_blob(p_clob));
  end;

  -- base64 decode
  function b64_decode(p_clob clob) return blob is
  
    v_raw      raw(32767);
    v_start    integer := 1;
    v_buffsize integer := BUFF_SIZE;
    v_length   integer;
    result     blob;
  begin
  
    if p_clob is not null then
    
      v_length := dbms_lob.getLength(p_clob);
    
      if v_length != 0 then
      
        for i in 1 .. ceil(v_length / v_buffsize) loop
        
          v_raw := utl_encode.base64_decode(dbms_lob.substr(p_clob, v_buffsize, v_start));
        
          dbms_lob.writeAppend(result, utl_raw.length(v_raw), v_raw);
          v_start := v_start + v_buffsize;
        end loop;
      end if;
    end if;
  
    return result;
  end;

  -- base64 decode
  function b64_decode(p_blob blob) return blob is
  begin
    return b64_decode(to_clob(p_blob));
  end;

end;
/

