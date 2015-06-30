create or replace package body lib_text is

  -- Text Functions
  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- (c) 1981-2014 Taras Lyuklyanchuk

  DIGITS constant char(10) := '0123456789';

  -- fill string with a character
  function fill(p_len  integer,
                p_text varchar2) return varchar as
  begin
    return rpad(p_text, p_len, p_text);
  end;

  function space(p_len integer) return varchar is
  begin
    return fill(p_len, const.SPC);
  end;

  function crop(p_text   varchar2,
                p_length integer) return varchar2 is
  begin
  
    if p_text is not null then
      return substr(trim(p_text), 1, p_length);
    else
      return null;
    end if;
  end;

  function rcrop(p_text   varchar2,
                 p_length integer) return varchar2 is
    pos# integer;
  begin
  
    if p_text is not null then
    
      pos# := least(p_length, length(trim(p_text)));
      return substr(trim(p_text), -pos#);
    
    else
      return null;
    end if;
  end;

  procedure concat(p_text in out varchar2,
                   p_arg1 varchar2,
                   p_arg2 varchar2 default null,
                   p_arg3 varchar2 default null,
                   p_arg4 varchar2 default null) is
  begin
    p_text := p_text || p_arg1 || p_arg2 || p_arg3 || p_arg4;
  end;

  function split(p_text  varchar2,
                 p_delim varchar2) return t_array is
  
    a     t_array := t_array();
    w     varchar(100);
    w_len integer;
  begin
  
    if p_text is not null and p_delim is not null then
    
      a.extend;
      w_len := length(p_delim);
    
      for pos# in 1 .. length(p_text) loop
      
        w := substr(p_text, pos#, w_len);
      
        if w != p_delim then
          concat(a(a.last), w);
        elsif a(a.last) is not null then
          a.extend;
        end if;
      end loop;
    
      if a(a.last) is null then
        a.delete(a.last);
      end if;
    end if;
  
    return a;
  
  exception
    when NO_DATA_FOUND then
    
      a.delete;
      return a;
    
    when others then
    
      lib_log.print_stack;
      raise;
  end;

  function join(p_arr   t_array,
                p_delim varchar2 default null) return varchar2 is
  
    result varchar2(32767);
  begin
  
    for i in 1 .. p_arr.count loop
    
      if result is null then
        result := p_arr(i);
      else
        result := result || p_delim || p_arr(i);
      end if;
    end loop;
  
    return result;
  end;

  function wrap(p_text  varchar2,
                p_index integer,
                p_delim varchar2) return varchar2 is
  begin
    return split(p_text, p_delim)(p_index);
  end;

  function decode(p_arg1 varchar2,
                  p_arg2 varchar2,
                  p_ret1 varchar2,
                  p_ret2 varchar2 default null) return varchar2 is
  begin
    return iif(p_arg1 = p_arg2, p_ret1, p_ret2);
  end;

  -- string formatting
  function format(p_format varchar2,
                  p_arg1   varchar2 default null,
                  p_arg2   varchar2 default null,
                  p_arg3   varchar2 default null,
                  p_arg4   varchar2 default null,
                  p_arg5   varchar2 default null,
                  p_arg6   varchar2 default null,
                  p_arg7   varchar2 default null,
                  p_arg8   varchar2 default null) return varchar2 is
  
    result varchar2(32767);
  begin
  
    result := utl_lms.format_message(p_format,
                                     p_arg1,
                                     p_arg2,
                                     p_arg3,
                                     p_arg4,
                                     p_arg5,
                                     p_arg6,
                                     p_arg7,
                                     p_arg8);
  
    return replace(result, '\n', const.CRLF);
  end;

  -- print to dbms_out
  procedure print(p_text varchar2) is
  
    lines t_array;
    line  varchar2(32767);
  begin
  
    lines := split(p_text, const.LF);
  
    for i in 1 .. lines.count loop
    
      line := replace(lines(i), const.CR, null);
    
      if i < lines.count then
        dbms_output.put_line(line);
      else
        dbms_output.put(line);
      end if;
    end loop;
  end;

  -- print line to dbms_out
  procedure println(p_text varchar2 default null) is
  begin
    print(p_text);
    dbms_output.new_line;
  end;

  -- format+print to dbms_out
  procedure printf(p_format varchar2,
                   p_arg1   varchar2 default null,
                   p_arg2   varchar2 default null,
                   p_arg3   varchar2 default null,
                   p_arg4   varchar2 default null,
                   p_arg5   varchar2 default null,
                   p_arg6   varchar2 default null,
                   p_arg7   varchar2 default null,
                   p_arg8   varchar2 default null) is
  
  begin
  
    print(format(p_format => p_format,
                 p_arg1   => p_arg1,
                 p_arg2   => p_arg2,
                 p_arg3   => p_arg3,
                 p_arg4   => p_arg4,
                 p_arg5   => p_arg5,
                 p_arg6   => p_arg6,
                 p_arg7   => p_arg7,
                 p_arg8   => p_arg8));
  end;

  -- format+print line to dbms_out
  procedure printlnf(p_format varchar2,
                     p_arg1   varchar2 default null,
                     p_arg2   varchar2 default null,
                     p_arg3   varchar2 default null,
                     p_arg4   varchar2 default null,
                     p_arg5   varchar2 default null,
                     p_arg6   varchar2 default null,
                     p_arg7   varchar2 default null,
                     p_arg8   varchar2 default null) is
  begin
  
    printf(p_format => p_format,
           p_arg1   => p_arg1,
           p_arg2   => p_arg2,
           p_arg3   => p_arg3,
           p_arg4   => p_arg4,
           p_arg5   => p_arg5,
           p_arg6   => p_arg6,
           p_arg7   => p_arg7,
           p_arg8   => p_arg8);
  
    println();
  end;

  function camel(p_text varchar2) return varchar2 is
  
    a t_array;
  begin
  
    if instr(p_text, '_') != 0 then
    
      a := split(p_text, '_');
    
      for i in 1 .. a.count loop
        a(i) := initcap(a(i));
      end loop;
    
      return join(a);
    
    elsif is_upper(p_text) then
    
      return initcap(p_text);
    
    else
    
      return p_text;
    end if;
  end;

  function lower_camel(p_text varchar2) return varchar2 is
  
    result varchar2(32767);
  begin
  
    result := camel(p_text);
  
    if length(result) > 1 then
      return lower(substr(result, 1, 1)) || substr(result, 2);
    elsif length(result) = 1 then
      return lower(result);
    else
      return result;
    end if;
  end;

  function upper_camel(p_text varchar2) return varchar2 is
  
    result varchar2(32767);
  begin
  
    result := camel(p_text);
  
    if length(result) > 1 then
      return upper(substr(result, 1, 1)) || substr(result, 2);
    elsif length(result) = 1 then
      return upper(result);
    else
      return result;
    end if;
  end;

  function uncamel(p_text varchar2) return varchar2 is
  
    a t_array;
    n integer := 0;
    p integer := 0;
  begin
  
    if p_text is not null then
    
      for i in 1 .. length(p_text) - 1 loop
      
        if is_lower(substr(p_text, i, 1)) and is_upper(substr(p_text, i + 1, 1)) then
          inc(n);
          a(n) := upper(substr(p_text, p + 1, i - p));
          p := i;
        end if;
      end loop;
    
      if p < length(p_text) then
        a(n + 1) := upper(substr(p_text, p + 1, length(p_text) - p));
      end if;
    
      return join(a, '_');
    
    else
      return null;
    end if;
  end;

  function is_lower(p_text varchar2) return boolean is
  begin
    return lower(p_text) = p_text;
  end;

  function is_upper(p_text varchar2) return boolean is
  begin
    return upper(p_text) = p_text;
  end;

  function is_equal(p_text1       varchar2,
                    p_text2       varchar2,
                    b_case_ignore boolean default false) return boolean is
  begin
    if b_case_ignore then
      return lower(p_text1) = lower(p_text2);
    else
      return p_text1 = p_text2;
    end if;
  end;

  function is_similar(p_text1 varchar2,
                      p_text2 varchar2) return boolean is
  begin
    return is_equal(p_text1 => p_text1, p_text2 => p_text2, b_case_ignore => true);
  end;

  function index_of(p_text    varchar2,
                    p_pattern varchar2,
                    p_offset  integer) return integer is
  begin
  
    return instr(p_text, p_pattern, p_offset);
  end;

  -- substring(text,from,to)
  function substring(p_text  varchar2,
                     p_begin integer,
                     p_end   integer) return varchar2 is
  begin
    return substr(p_text, p_begin, p_end - p_begin + 1);
  end;

  -- substring+trim
  function subtrim(p_text  varchar2,
                   p_begin integer,
                   p_end   integer) return varchar2 is
  begin
    return trim(substring(p_text, p_begin, p_end));
  end;

  -- base64 encode
  function b64_encode(p_text in varchar2) return varchar2 is
  begin
    return utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(p_text)));
  end;

  -- base64 decode
  function b64_decode(p_text in varchar2) return varchar2 is
  begin
    return utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(p_text)));
  end;

  -- repeat text N-times
  function repeat(p_text  varchar2,
                  p_times integer) return varchar2 is
  
    result varchar2(32767);
  begin
  
    for n in 1 .. p_times loop
      concat(result, p_text);
    end loop;
  
    return result;
  end;

  -- repeat text N-times with delimiter
  function repeat(p_text  varchar2,
                  p_delim varchar2,
                  p_times integer) return varchar2 is
  
    result varchar2(32767);
  begin
  
    for n in 1 .. p_times loop
    
      if result is null then
        concat(result, p_text);
      else
        concat(result, p_delim, p_text);
      end if;
    end loop;
  
    return result;
  end;

  -- check is text have only letters
  function is_alpha(p_text varchar2) return boolean is
  
    code integer;
  begin
  
    if p_text is not null then
    
      for i in 1 .. length(p_text) loop
      
        code := ascii(substr(p_text, i, 1));
      
        if code between 65 and 90 or code between 97 and 122 then
          continue;
        end if;
      
        return false;
      end loop;
    
      return true;
    end if;
  
    return null;
  end;

  -- check is text have only numbers
  function is_number(p_text varchar2) return boolean is
  begin
  
    if p_text is not null then
    
      for i in 1 .. length(p_text) loop
      
        if instr(DIGITS, substr(p_text, i, 1)) != 0 then
          continue;
        end if;
      
        return false;
      end loop;
    
      return true;
    end if;
  
    return null;
  end;

  -- check is text have only letters or numbers
  function is_alphanum(p_text varchar2) return boolean is
    code integer;
  begin
  
    if p_text is not null then
    
      for i in 1 .. length(p_text) loop
      
        if instr(DIGITS, substr(p_text, i, 1)) != 0 then
          continue;
        else
        
          code := ascii(substr(p_text, i, 1));
        
          if code between 65 and 90 or code between 97 and 122 then
            continue;
          end if;
        end if;
      
        return false;
      end loop;
    
      return true;
    end if;
  
    return null;
  end;

  -- returns only letters and numbers from text
  function only_alphas(p_text varchar2) return varchar2 is
  
    result varchar2(32767);
  begin
  
    if p_text is not null then
    
      for i in 1 .. length(p_text) loop
        if upper(substr(p_text, i, 1)) != lower(substr(p_text, i, 1)) then
          concat(result, substr(p_text, i, 1));
        end if;
      end loop;
    end if;
  
    return result;
  end;

  -- returns only numbers from text
  function only_numbers(p_text varchar2) return varchar2 is
  
    digits constant varchar2(10) := '0123456789';
    result varchar2(32767);
  begin
  
    if p_text is not null then
    
      for i in 1 .. length(p_text) loop
        if instr(digits, substr(p_text, i, 1)) != 0 then
          concat(result, substr(p_text, i, 1));
        end if;
      end loop;
    end if;
  
    return result;
  end;

  -- returns only letters and numbers from text
  function only_alphanum(p_text varchar2) return varchar2 is
  
    result varchar2(32767);
  begin
  
    if p_text is not null then
    
      for i in 1 .. length(p_text) loop
        if instr(DIGITS, substr(p_text, i, 1)) != 0 then
          concat(result, substr(p_text, i, 1));
        elsif upper(substr(p_text, i, 1)) != lower(substr(p_text, i, 1)) then
          concat(result, substr(p_text, i, 1));
        end if;
      end loop;
    end if;
  
    return result;
  end;

end;
/

