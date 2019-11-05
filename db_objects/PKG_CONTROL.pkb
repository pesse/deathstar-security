create or replace package body pkg_control as

  function get_user return number
  as
    v_id integer;

  begin

    return v_user;

  end get_user ;

  function get_user_role return varchar2
  as

    v_role_name roles.role_name%TYPE;

  begin

    select r.role_name
    into v_role_name
    from user_roles ur join roles r on (r.id = ur.id_role)
    where id_user = v_user;

    return v_role_name;

  end get_user_role;

begin -- init

  if v_user is null then

    select 2 id -- SELECT SYS_CONTEXT ('USERENV', 'SESSION_USER')
    into v_user
    from dual;

  end if;

end;
/