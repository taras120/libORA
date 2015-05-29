create or replace package lib_crypt is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Cryptographic Functions
  -- (c) 1981-2014 Taras Lyuklyanchuk

  DEFAULT_PWD_LENGTH constant integer := 16;

  -- MD5 hash
  function md5(input varchar2) return varchar2;

  -- DES encrypt
  function des1e(input raw,
                 key   raw) return raw;

  -- DES decrypt
  function des1d(input raw,
                 key   raw) return raw;

  -- 3DES encrypt
  function des3e(input raw,
                 key   raw) return raw;

  -- 3DES decrypt
  function des3d(input raw,
                 key   raw) return raw;

  -- 3DES
  function des3ev(input char,
                  key   char) return raw;

  -- 3DES decrypt
  function des3dv(input char,
                  key   char) return raw;

  -- password generator
  function gen_pwd(len integer default DEFAULT_PWD_LENGTH) return varchar2;

  -- хэш-функция пароля
  function raw_hash(pwd varchar2) return raw;

  -- хэш-функция пароля
  function text_hash(pwd varchar2) return char;

  -- функция шифрования на основе пароля
  function raw_encrypt(input raw,
                       pwd   varchar2) return raw;

  -- функция дешифрования на основе пароля
  function raw_decrypt(input raw,
                       pwd   varchar2) return raw;

end;
/

