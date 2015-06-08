create or replace package lib_math is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Author  : Taras Lyuklyanchuk
  -- Created : 26.04.2014 11:37:59
  -- Purpose : Mathematical Functions

  type t_date_list is table of date;
  type t_number_list is table of number;

  -- Interest rate
  function rate(p_nper  in number,
                p_pmt   in number,
                p_pv    in number,
                p_fv    in number default 0,
                p_type  in integer default 1,
                p_guess in number default 0.1) return number;

  -- Present value
  function pv(p_rate in number,
              p_nper in number,
              p_pmt  in number,
              p_fv   in number default 0,
              p_type in integer default 1) return number;

  -- Payment
  function pmt(p_rate in number,
               p_nper in number,
               p_pv   in number,
               p_fv   in number default 0,
               p_type in integer default 1) return number;

  /*функция ЧИСТНЗ*/
  --p_at - массив выплат
  --p_dt - массив дат выплат
  --p_d0 - начальная дата
  --p_x - ставка
  function ft(p_at   t_number_list,
              p_dt   t_date_list,
              p_d0   date,
              p_x    double precision,
              p_ylen integer default 365) return double precision;

  function nvlsum(a1 number,
                  a2 number,
                  a3 number default null,
                  a4 number default null,
                  a5 number default null,
                  a6 number default null,
                  a7 number default null) return number;

end;
/

