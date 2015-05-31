create or replace package body lib_crypt is

  -- LibORA PL/SQL Library
  -- http://bitbucket.org/rtfm/libora
  -- Cryptographic Functions
  -- (c) 1981-2014 Taras Lyuklyanchuk

  TABLE1 constant varchar2(32) := '0123456789';
  TABLE2 constant varchar2(32) := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  TABLE3 constant varchar2(32) := 'abcdefghijklmnopqrstuvwxyz';

  -- raw cast
  function to_raw(input varchar2) return raw is
  begin
    return utl_raw.cast_to_raw(input);
  end;

  -- random boolean
  function b_rand return boolean is
  begin
    return trunc(sys.dbms_random.value * 2) = 0;
  end;

  -- MD5 hash
  function md5(input varchar2) return varchar2 as
  begin
    if input is not null then
      return rawtohex(dbms_obfuscation_toolkit.md5(input => utl_raw.cast_to_raw(input)));
    else
      return null;
    end if;
  end;

  -- DES encrypt
  function des1e(input raw,
                 key   raw) return raw as

    piece  raw(8);
    result raw(1024);
  begin

    if mod(utl_raw.length(input), 8) != 0 then
      throw('Invalid input length for DES function');
    end if;

    for i in 1 .. utl_raw.length(input) / 8 loop

      piece := utl_raw.substr(input, (i - 1) * 8 + 1, 8);

      result := utl_raw.concat(r1 => result,
                               r2 => dbms_obfuscation_toolkit.DESEncrypt(input => piece, key => key));
    end loop;

    return result;
  end;

  -- DES decrypt
  function des1d(input raw,
                 key   raw) return raw as

    piece  raw(8);
    result raw(1024);
  begin

    if mod(utl_raw.length(input), 8) != 0 then
      throw('Invalid input length for DES function');
    end if;

    for i in 1 .. utl_raw.length(input) / 8 loop

      piece := utl_raw.substr(input, (i - 1) * 8 + 1, 8);

      result := utl_raw.concat(r1 => result,
                               r2 => dbms_obfuscation_toolkit.DESDecrypt(input => piece, key => key));
    end loop;

    return result;
  end;

  -- 3DES encrypt
  function des3e(input raw,
                 key   raw) return raw as

    key1 raw(8);
    key2 raw(8);
    key3 raw(8);
  begin

    -- EK3(DK2(EK1(plaintext)))

    key1 := utl_raw.substr(key, 1, 8);
    key2 := utl_raw.substr(key, 9, 8);
    key3 := key1;

    return des1e(des1d(des1e(input, key1), key2), key3);
  end;

  -- 3DES decrypt
  function des3d(input raw,
                 key   raw) return raw as

    key1 raw(8);
    key2 raw(8);
    key3 raw(8);
  begin

    -- DK1(EK2(DK3(ciphertext)))

    key1 := utl_raw.substr(key, 1, 8);
    key2 := utl_raw.substr(key, 9, 8);
    key3 := key1;

    return des1d(des1e(des1d(input, key3), key2), key1);
  end;

  -- 3DES encrypt
  function des3ev(input char,
                  key   char) return raw as
  begin

    return des3e(input => utl_raw.cast_to_raw(input), key => utl_raw.cast_to_raw(key));
  end;

  -- 3DES decrypt
  function des3dv(input char,
                  key   char) return raw as
  begin

    return des3d(input => utl_raw.cast_to_raw(input), key => utl_raw.cast_to_raw(key));
  end;

  -- spaced rpad
  function padtrail(input varchar2,
                    len   integer) return varchar as
  begin
    return rpad(input, len, chr(32));
  end;

  -- password generator
  function gen_pwd(len integer default DEFAULT_PWD_LENGTH) return varchar2 is

    i1     integer;
    i2     integer;
    i3     integer;
    a1     char(1);
    a2     char(1);
    a3     char(1);
    result varchar2(32);
  begin

    while nvl(length(result), 0) < len loop

      i1 := trunc(dbms_random.value(1, length(TABLE1)));
      i2 := trunc(dbms_random.value(1, length(TABLE2)));
      i3 := trunc(dbms_random.value(1, length(TABLE3)));

      a1 := substr(TABLE1, i1, 1);
      a2 := substr(TABLE2, i1, 1);
      a3 := substr(TABLE3, i1, 1);

      loop

        if b_rand then
          swap(a1, a2);
        end if;

        if b_rand then
          swap(a2, a3);
        end if;

        if b_rand then
          swap(a1, a3);
        end if;

        exit when b_rand;
      end loop;

      result := result || a1 || a2 || a3;
    end loop;

    return substr(result, 1, len);
  end;

  -- хэш-функция пароля
  function raw_hash(pwd varchar2) return raw is
  begin

    return des3e(to_raw(PadTrail(SubStr(Upper(pwd), 1, 8), 8)),
                 to_raw(PadTrail(SubStr(Upper(pwd), 1, 16), 16)));
  end;

  -- хэш-функция пароля
  function text_hash(pwd varchar2) return char is
  begin
    return rawtohex(raw_hash(pwd));
  end;

  -- функция шифрования пароля
  function raw_encrypt(input raw,
                       pwd   varchar2) return raw is
  begin
    return des1e(input, text_hash(pwd));
  end;

  -- функция дешифрования пароля
  function raw_decrypt(input raw,
                       pwd   varchar2) return raw is
  begin
    return des1d(input, text_hash(pwd));
  end;

end;
/

