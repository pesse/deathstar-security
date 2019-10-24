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