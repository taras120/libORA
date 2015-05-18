create or replace package body lib_text is

  -- LibORA PL/SQL Library
  -- Text Functions
  -- (c) 1981-2014
  -- Taras Lyuklyanchuk

  function crop(p_text   varchar2,
                p_length integer) return varchar2 is
  begin
    return substr(trim(p_text), 1, p_length);
  end;

  function split(p_text  varchar2,
                 p_delim char) return t_array is
  
    a t_array;
    i integer;
    c char(1);
  begin
  
    if p_text is not null then
    
      i := 1;
      a(i) := null;
    
      for p in 1 .. length(p_text) loop
      
        c := substr(p_text, p, 1);
      
        if c != p_delim then
          a(i) := a(i) || c;
        elsif a(i) is not null then
          i := i + 1;
          a(i) := null;
        end if;
      end loop;
    end if;
  
    return a;
  
  exception
    when NO_DATA_FOUND then
      a.delete;
      return a;
    when others then
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
                p_delim char) return varchar2 is
  begin
    return split(p_text, p_delim)(p_index);
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
    
    else
      return initcap(p_text);
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

  function is_lower(p_text varchar2) return boolean is
  begin
    return lower(p_text) = p_text;
  end;

  function is_upper(p_text varchar2) return boolean is
  begin
    return upper(p_text) = p_text;
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

  function index_of(p_text    clob,
                    p_pattern varchar2,
                    p_offset  integer) return integer is
  begin
  
    return instr(p_text, p_pattern, p_offset);
  end;

  function substring(p_text  clob,
                     p_begin integer,
                     p_end   integer) return varchar2 is
  begin
    return substr(p_text, p_begin, p_end - p_begin + 1);
  end;

end;
/

