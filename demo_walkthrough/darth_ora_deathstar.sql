/* 1. Update Injection: Poison a data-table */
-- Vorstellung Tabellen
#pause
set echo on
select * from users;

#pause
select * from roles;

#pause
select * from user_roles;

#pause
select * from deathstar_rooms;
select * from user_room_access;

--------------------------
-- --> Continue Sabine
--------------------------
#pause

/* 2. Blind Injection */

--package to get Room-name by ID
create or replace package room_info as
  function get_room_id( i_name varchar2 ) return integer;
end;
/
#pause
create or replace package body room_info as
  function get_room_id( i_name varchar2 ) return integer
  as
    c_curs sys_refcursor;
    v_row deathstar_rooms%rowtype;
    l_id integer;
    begin
      open c_curs for
        'select * from deathstar_rooms where lower(name) like lower(''%' || i_name || '%'')';
      loop
	      fetch c_curs into v_row;
	      exit when c_curs%notfound or l_id is not null;
	      dbms_output.put_line('Room found: ' || v_row.name);
	      l_id := v_row.id;
      end loop;

      return l_id;
    end;
end;
/
#pause

select room_info.get_room_id('Vader') from dual;
#pause

-- Funktioniert nicht, weil nur 1 Statement + Read-context
select room_info.get_room_id('''); drop table deathstar_rooms;--') from dual;
#pause

--------------------------
-- --> Continue Sabine
--------------------------
#pause

/* 3. 2nd Order Attack */
-- Verwaltungsscript
create or replace package room_info as
  function get_room_id( i_name varchar2 ) return integer;

	procedure allow_room_access(
		i_room_id simple_integer,
		i_user_id simple_integer );
end;
/
#pause

create or replace package body room_info as
  function get_room_id( i_name varchar2 ) return integer
  as
    c_curs sys_refcursor;
    v_row deathstar_rooms%rowtype;
    l_id integer;
    begin
      open c_curs for
        'select * from deathstar_rooms where lower(name) like lower(''%' || i_name || '%'')';
      loop
	      fetch c_curs into v_row;
	      exit when c_curs%notfound or l_id is not null;
	      dbms_output.put_line('Room found: ' || v_row.name);
	      l_id := v_row.id;
      end loop;

      return l_id;
    end;

  procedure allow_room_access(
    i_room_id simple_integer,
    i_user_id simple_integer )
  as
    l_room_code varchar2(200);
    l_log_table varchar2(40) := 'LOG_'||to_char(sysdate, 'YYYYMM');
    begin
      insert into user_room_access ( id_user, id_room )
        select i_user_id, i_room_id
          from dual
          where (i_user_id, i_room_id) not in (select id_user, id_room from user_room_access);

      -- Logging: We need dyn. sql
      select code into l_room_code from deathstar_rooms where id = i_room_id;
      execute immediate '
        begin
          insert into ' || dbms_assert.simple_sql_name(l_log_table) || ' ( message )
            values (''User ' || i_user_id || ' has now access to room ' || l_room_code || ''');
        end;
      ';
    end;
end;
/
#pause

--------------------------
-- --> Continue Sabine
--------------------------
#pause

/* 4. Invoker's rights  */
#pause
--------------------------
-- --> AS DARTH_DBA
--------------------------
connect darth_dba/darth_dba@localhost:1522/ORCLPDB1
#pause
create user sabine identified by sabine  default tablespace users quota unlimited on users;
grant connect to sabine;
grant resource to sabine;

--------------------------
-- --> Continue Sabine
--------------------------
#pause
/* 5. Variable Poisoning */
--------------------------
-- --> AS DEATHSTAR
--------------------------

connect deathstar/deathstar@localhost:1522/ORCLPDB1
#pause
create or replace package pkg_control as

  v_user integer;

  function get_user return number;

  function get_user_role return varchar2;

end;
/
#pause
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
#pause
create or replace package pkg_control as

  v_user integer;

  function get_user return number;

  function get_user_role return varchar2;

end;
/
#pause
set serveroutput on
begin
  dbms_output.put_line( 'User-ID: ' || pkg_control.get_user );
  dbms_output.put_line( 'User-ROLE: ' || pkg_control.get_user_role );
end;
/
#pause
-- Exploit! Public User-Variable
begin
  pkg_control.v_user := 1;
  dbms_output.put_line( 'User-ID: ' || pkg_control.get_user );
  dbms_output.put_line( 'User-ROLE: ' || pkg_control.get_user_role );
end;
/
#pause
-- Kann mit PL/SCOPE gefunden werden
ALTER SESSION SET PLSCOPE_SETTINGS='IDENTIFIERS:ALL, STATEMENTS:ALL';

-- Alle Schema-Objekte neu compilieren
begin
  DBMS_UTILITY.compile_schema(schema => 'DEATHSTAR', compile_all => true);
end;
/
#pause
select *
	from user_identifiers
	where object_type = 'PACKAGE'
		and usage = 'DECLARATION'
		and type = 'VARIABLE';
#pause

-- Fix it!
create or replace package pkg_control as

  function get_user return number;

  function get_user_role return varchar2;

end;
/
#pause
create or replace package body pkg_control as

  v_user integer;

  function get_user return number
  as
    v_id integer;
  begin
    return v_user;
  end get_user ;
#pause
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
#pause
-- Check mit PL/SCOPE
select *
	from user_identifiers
	where object_type = 'PACKAGE'
		and usage = 'DECLARATION'
		and type = 'VARIABLE';
#pause
begin
  dbms_output.put_line( 'User-ID: ' || pkg_control.get_user );
  dbms_output.put_line( 'User-ROLE: ' || pkg_control.get_user_role );
end;
/
#pause

/* 6. Collation Attack */
create or replace function is_admin( i_username varchar2 )
 return integer
as
  begin
	  if ( i_username = 'ADMIN') then
      return 1;
    else
	    return 0;
		end if;
	end;
/
#pause
grant execute on is_admin to public;
--------------------------
-- --> Continue Sabine
--------------------------
#pause


--------------------------
-- --> AS DARTH_DBA
--------------------------
connect darth_dba/darth_dba@localhost:1522/ORCLPDB1

grant administer database trigger to sabine;

--------------------------
-- --> Continue Sabine
--------------------------
#pause

/* 7. Synonym Attack */
--------------------------
-- --> Continue Sabine
--------------------------

--------------------------
-- --> AS DARTH_DBA
--------------------------
grant create any synonym to sabine;

--------------------------
-- --> Continue Sabine
--------------------------
#pause

declare
  l_room_id integer;
begin
	l_room_id := deathstar.room_info.get_room_id('Vader');
	dbms_output.put_line('ID: ' || l_room_id);
end;
/
-- Funktioniert doch...

--------------------------
-- --> Continue Sabine
--------------------------
#pause