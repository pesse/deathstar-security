-- Als SYS
drop synonym deathstar.dbms_output;
drop synonym darth_dba.dbms_output;

drop user scott cascade;

delete from deathstar.user_roles where id_user = 4;
update deathstar.deathstar_rooms set code = 'VADER' where id = 2;
commit;