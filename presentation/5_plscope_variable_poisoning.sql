create or replace package pkg_control as

  v_user integer;

  function get_user return number;

  function get_user_role return varchar2;

end;
/

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

begin -- init des Packages
  if v_user is null then
    case sys_context('USERENV', 'SESSION_USER')
      when 'DARTH_DBA' then
        v_user := 1; -- Deathstar-DBA ist Admin
      else
        v_user := 2; -- Default ist READ
    end case;
  end if;
end;
/

begin
  dbms_output.put_line( 'User-ID: ' || pkg_control.get_user );
  dbms_output.put_line( 'User-ROLE: ' || pkg_control.get_user_role );
end;
/

-- Exploit! Public User-Variable
begin
  pkg_control.v_user := 1;
  dbms_output.put_line( 'User-ID: ' || pkg_control.get_user );
  dbms_output.put_line( 'User-ROLE: ' || pkg_control.get_user_role );
end;
/

-- Kann mit PL/SCOPE gefunden werden
ALTER SESSION SET PLSCOPE_SETTINGS='IDENTIFIERS:ALL, STATEMENTS:ALL';

-- Alle Schema-Objekte neu compilieren
begin
  DBMS_UTILITY.compile_schema(schema => 'DEATHSTAR', compile_all => true);
end;
/

select *
	from user_identifiers
	where object_type = 'PACKAGE'
		and usage = 'DECLARATION'
		and type = 'VARIABLE';


-- Fix it!
create or replace package pkg_control as

  function get_user return number;

  function get_user_role return varchar2;

end;
/

create or replace package body pkg_control as

  v_user integer;

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

begin -- init des Packages
  if v_user is null then
    case sys_context('USERENV', 'SESSION_USER')
      when 'DARTH_DBA' then
        v_user := 1; -- Deathstar-DBA ist Admin
      else
        v_user := 2; -- Default ist READ
    end case;
  end if;
end;
/

-- Check mit PL/SCOPE
select *
	from user_identifiers
	where object_type = 'PACKAGE'
		and usage = 'DECLARATION'
		and type = 'VARIABLE';

begin
  dbms_output.put_line( 'User-ID: ' || pkg_control.get_user );
  dbms_output.put_line( 'User-ROLE: ' || pkg_control.get_user_role );
end;
/