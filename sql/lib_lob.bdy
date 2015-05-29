create or replace package body lib_lob is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 15.05.2015 0:11:57
  -- Purpose : Large Object Library

  BUFF_SIZE constant integer := 4000;

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

  -- print clob
  procedure print(p_clob clob) is
  
    amount   integer;
    offset   integer := 1;
    buffsize integer := BUFF_SIZE;
    clobsize integer;
  begin
  
    clobsize := dbms_lob.getLength(p_clob);
  
    if p_clob is not null then
    
      for i in 1 .. ceil(clobsize / buffsize) loop
      
        amount := least(buffsize, clobsize - offset + 1);
        dbms_output.put_line(dbms_lob.substr(p_clob, amount, offset));
      
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
      print(p_xml.getclobval);
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
    return substr(p_text, p_begin, p_end - p_begin);
  end;

  function instr(p_text    clob,
                 p_pattern varchar2,
                 p_offset  integer) return integer is
  begin
  
    return nvl(dbms_lob.instr(lob_loc => p_text,
                              pattern => p_pattern,
                              offset  => p_offset,
                              nth     => 1),
               0);
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

