create or replace function sprintf(format varchar2,
                                   arg1   varchar2 default null,
                                   arg2   varchar2 default null,
                                   arg3   varchar2 default null,
                                   arg4   varchar2 default null,
                                   arg5   varchar2 default null,
                                   arg6   varchar2 default null,
                                   arg7   varchar2 default null,
                                   arg8   varchar2 default null) return varchar2 is

  -- String formatting
  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- (c) 1981-2014 Taras Lyuklyanchuk

  i    integer;
  p    integer;
  argv types.StringTable;
  arg# types.IntegerTable;
  outf varchar2(4000);
  outv types.StringTable;
begin

  if regexp_instr(format, '%[0-9]') != 0 then
  
    /* numbered style: %2 %1 %3 */
  
    argv(1) := arg1;
    argv(2) := arg2;
    argv(3) := arg3;
    argv(4) := arg4;
    argv(5) := arg5;
    argv(6) := arg6;
    argv(7) := arg7;
    argv(8) := arg8;
  
    -- output format and values
    outf := format;
    outv := argv;
  
    -- format map
    for n in 1 .. 8 loop
    
      p := instr(outf, '%' || n);
    
      if p != 0 then
        arg#(p) := n;
      end if;
    end loop;
  
    i := 0;
    p := arg#.first;
    while p is not null loop
    
      inc(i);
      outv(i) := argv(arg#(p));
      outf := substr(outf, 1, p) || 's' || substr(outf, p + 2);
    
      p := arg#.next(p);
    end loop;
  
    return utl_lms.format_message(outf,
                                  outv(1),
                                  outv(2),
                                  outv(3),
                                  outv(4),
                                  outv(5),
                                  outv(6),
                                  outv(7),
                                  outv(8));
  
  else
  
    /* format string: %s %d %b */
    return utl_lms.format_message(format, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
  end if;
end;
/

