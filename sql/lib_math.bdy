create or replace package body lib_math is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.04.2014 11:37:59
  -- Purpose : Mathematical Functions

  -- Interest rate
  function rate(p_nper  in number,
                p_pmt   in number,
                p_pv    in number,
                p_fv    in number default 0,
                p_type  in integer default 1,
                p_guess in number default 0.1) return number is

    l_a     number;
    l_b     number;
    l_c     number;
    l_r     number;
    l_rtmp  number;
    l_mrate number;
  begin

    l_r := 1 + p_guess;
    l_a := (p_pmt * (1 - p_type) - p_pv) / (p_pv + p_pmt * p_type);
    l_b := (p_fv - p_pmt * p_type) / (p_pv + p_pmt * p_type);
    l_c := (-p_pmt * (1 - p_type) - p_fv) / (p_pv + p_pmt * p_type);

    for i in 1 .. 20 loop

      l_rtmp := l_r -
                (power(l_r, (p_nper + 1)) + l_a * power(l_r, p_nper) + l_b * l_r + l_c) /
                ((p_nper + 1) * power(l_r, p_nper) + l_a * p_nper * power(l_r, (p_nper - 1)) + l_b);

      if abs(l_rtmp - l_r) < 0.0000001 then
        exit;
      end if;

      l_r     := l_rtmp;
      l_mrate := l_rtmp - 1;
    end loop;

    return l_mrate;

    /*exception
    when others then
      return null;*/
  end;

  -- Present value
  function pv(p_rate in number,
              p_nper in number,
              p_pmt  in number,
              p_fv   in number default 0,
              p_type in integer default 1) return number is
  begin

    return p_pmt / p_rate *(1 - power(1 + p_rate, -p_nper));

    /*exception
    when others then
      return null;*/
  end;

  -- Payment
  function pmt(p_rate in number,
               p_nper in number,
               p_pv   in number,
               p_fv   in number default 0,
               p_type in integer default 1) return number is
  begin

    return p_pv * p_rate * power((1 + p_rate), p_nper) /(power((1 + p_rate), p_nper) - 1);

    /*exception
    when others then
      return null;*/
  end;

  /*функция ЧИСТНЗ*/
  --p_at - массив выплат
  --p_dt - массив дат выплат
  --p_d0 - начальная дата
  --p_x - ставка
  function ft(p_at   t_number_list,
              p_dt   t_date_list,
              p_d0   date,
              p_x    double precision,
              p_ylen integer default 365) return double precision is

    v_s double precision := 0;
  begin

    for i in 1 .. p_at.count loop
      v_s := v_s + p_at(i) * power(1 + p_x, - ((p_dt(i) - p_d0) / p_ylen));
    end loop;

    return v_s;
  end;

end;
/

