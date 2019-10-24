drop table room_inventory;
drop table deathstar_rooms;

create table deathstar_rooms (
  id integer generated by default on null as identity primary key,
  name varchar2(200) not null,
  code varchar2(200) not null unique
);

insert into deathstar_rooms ( name, code ) values ( 'Engine Room 1', 'ENG1' );
insert into deathstar_rooms ( name, code ) values ( 'Vaders Chamber', 'VADER' );
insert into deathstar_rooms ( name, code ) values ( 'Bridge', 'BRIDGE' );
insert into deathstar_rooms ( name, code ) values ( 'Prison 1', 'PRISON1' );

create table room_inventory (
  id integer generated by default on null as identity primary key,
	room_id integer not null,
	item varchar2(400) not null,
	constraint room_inventory_fk_room foreign key ( room_id )
    references deathstar_rooms (id)
);

insert into room_inventory (room_id, item) values ( (select id from deathstar_rooms where code = 'ENG1'), 'Laser-Wrench');
insert into room_inventory (room_id, item) values ( (select id from deathstar_rooms where code = 'ENG1'), 'Sandwich (half eaten)');
insert into room_inventory (room_id, item) values ( (select id from deathstar_rooms where code = 'VADER'), 'Lightsaber (red)');

select * from deathstar_rooms;
select * from room_inventory;

create or replace package room_info as
  function get_room_id( i_name varchar2 ) return integer;

	procedure allow_room_inventory_access( i_room_id simple_integer );
end;
/
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
	      l_id := v_row.id;
      end loop;

      return l_id;
    end;

	procedure allow_room_inventory_access( i_room_id simple_integer )
	as
	  l_room_code varchar2(200);
	  l_view_name varchar2(200);
	  begin
	    select code into l_room_code from deathstar_rooms where id = i_room_id;
	    l_view_name := 'V_ROOM_INV_'||l_room_code;

		  execute immediate '
					begin
						create or replace view "' || l_view_name || '" as
							select * from room_inventory
							where room_id = :roomId;
					end;'
	      using in i_room_id;

	  end;
end;
/

call room_info.allow_room_inventory_access( 2 );