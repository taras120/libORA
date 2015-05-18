create or replace type t_nvp is object
(

/* Name-Value Pair */

  name  varchar2(1000),
  value varchar2(4000),
  type  varchar2(100)
)
/

