create or replace package pkg_control as

  v_user integer;

  function get_user return number;

  function get_user_role return varchar2;

end;
/