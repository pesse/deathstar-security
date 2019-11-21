set linesize 111
set pagesize 1000
set trimout on
column name format a30
column user_name format a30
column role_name format a30
column code format a60
column variable_name format a30
column package_name format a30
cl scr
#pause
-- Reset rooms table
update deathstar_rooms set code = 'VADER' where id = 2;
commit;
cl scr
set echo on
------------------------------------------------------------------------------------
-- Episode 1: Die APEX-Bedrohung
------------------------------------------------------------------------------------

#pause
select * from users;

#pause
select * from roles;

#pause
select * from user_roles;

#pause

select * from deathstar_rooms;
#pause
select * from user_room_access;

#pause
desc imperial_secrets;

#pause

#pause/**/
cl scr
------------------------------------------------------------------------------------
-- Episode 2: Angriff der Blind-Injections
------------------------------------------------------------------------------------

#pause

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
        'select * from deathstar_rooms
        where lower(name) like lower(''%' || i_name || '%'')';
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
cl scr
select room_info.get_room_id('Vader') from dual;
#pause

select room_info.get_room_id('''); drop table deathstar_rooms;--') from dual;
#pause /**/
cl scr
------------------------------------------------------------------------------------
-- Episode 3: Die Rache des Room-Codes
------------------------------------------------------------------------------------
#pause

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
          where (i_user_id, i_room_id) not in (
            select id_user, id_room from user_room_access);
#pause
      -- Logging: We need dyn. sql
      select code into l_room_code from deathstar_rooms where id = i_room_id;
      execute immediate '
        begin
          insert into ' || dbms_assert.simple_sql_name(l_log_table) || ' ( message )
            values (''User ' || i_user_id ||
            ' has now access to room ' || l_room_code || ''');
        end;
      ';
    end;
end;
/
#pause
cl scr

#pause/**/
cl scr
------------------------------------------------------------------------------------
-- Episode 4: Invoker’s Hoffnung
------------------------------------------------------------------------------------

#pause
connect darth_dba/darth_dba
#pause
cl scr
create user sabine identified by sabine  default tablespace users quota unlimited on users;
grant connect to sabine;
grant resource to sabine;

#pause/**/
cl scr
------------------------------------------------------------------------------------
-- Episode 5: Der Admin schlägt zurück
------------------------------------------------------------------------------------

connect deathstar/deathstar
#pause
cl scr

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
#pause
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
cl scr
create or replace package pkg_control as

  v_user integer;

  function get_user return number;

  function get_user_role return varchar2;

end;
/
#pause
cl scr
set serveroutput on
begin
  dbms_output.put_line( 'User-ID: ' || pkg_control.get_user );
  dbms_output.put_line( 'User-ROLE: ' || pkg_control.get_user_role );
end;
/
#pause
cl scr
begin
  pkg_control.v_user := 1;
  dbms_output.put_line( 'User-ID: ' || pkg_control.get_user );
  dbms_output.put_line( 'User-ROLE: ' || pkg_control.get_user_role );
end;
/
#pause
cl scr
ALTER SESSION SET PLSCOPE_SETTINGS='IDENTIFIERS:ALL, STATEMENTS:ALL';

begin
  DBMS_UTILITY.compile_schema(schema => 'DEATHSTAR', compile_all => true);
end;
/
#pause
cl scr
select name variable_name, object_name package_name, line
  from user_identifiers
  where object_type = 'PACKAGE'
    and usage = 'DECLARATION'
    and type = 'VARIABLE';
#pause
cl scr
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
cl scr
select name variable_name, object_name package_name, line
  from user_identifiers
  where object_type = 'PACKAGE'
    and usage = 'DECLARATION'
    and type = 'VARIABLE';
#pause
cl scr
begin
  dbms_output.put_line( 'User-ID: ' || pkg_control.get_user );
  dbms_output.put_line( 'User-ROLE: ' || pkg_control.get_user_role );
end;
/
#pause
cl scr
------------------------------------------------------------------------------------
-- Episode 6: Die Rückkehr des Social Engineers
------------------------------------------------------------------------------------
#pause
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
cl scr

select is_admin('ADMIN') from dual;

select is_admin('User') from dual;
#pause
cl scr
grant execute on is_admin to public;

#pause/**/
cl scr

connect darth_dba/darth_dba

grant administer database trigger to sabine;

#pause/**/
cl scr

grant create any synonym to sabine;

#pause/**/
cl scr
set serveroutput on
declare
  l_room_id integer;
begin
  l_room_id := deathstar.room_info.get_room_id('Vader');
  dbms_output.put_line('ID: ' || l_room_id);
end;
/
#pause/**/