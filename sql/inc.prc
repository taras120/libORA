create or replace procedure inc(a in out number) is
begin

  /* a++ */

  a := nvl(a, 0) + 1;
end;
/

