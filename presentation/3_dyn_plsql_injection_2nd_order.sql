
select * from deathstar_rooms;
select * from room_inventory;

-- Neuer User mit keinerlei Rechten
insert into users values (4, 'Rebel');

select * from users;
select * from user_roles;

create or replace package room_info as
	procedure allow_room_access(
		i_room_id simple_integer,
		i_user_id simple_integer );
end;
/

create or replace package body room_info as
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

-- Exploit!

-- Poisoned room-code
select code from deathstar_rooms;

select * from user_roles;

-- Just wait until someone gets access to the room!
call room_info.allow_room_access(2, 1);

select * from user_roles;
select * from log_201910;