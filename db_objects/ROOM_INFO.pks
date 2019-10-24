create or replace package room_info as
  function get_room_id( i_name varchar2 ) return integer;

	procedure allow_room_access(
		i_room_id simple_integer,
		i_user_id simple_integer );
end;
/