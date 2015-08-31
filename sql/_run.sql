------------------------------------------------------
-- Export file for user SPE@APRICOT                 --
-- Created by tlyuklyanchuk on 28.07.2015, 21:49:16 --
------------------------------------------------------

set define off
spool _run.log

prompt
prompt Creating package LIB_LOB
prompt ========================
prompt
@@lib_lob.spc
prompt
prompt Creating package body LIB_LOB
prompt =============================
prompt
@@lib_lob.bdy

spool off
