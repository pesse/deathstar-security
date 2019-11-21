-- Als SYS
drop synonym deathstar.dbms_output;
drop synonym darth_dba.dbms_output;

drop user sabine cascade;

truncate table deathstar.log_201911;
truncate table deathstar.imperial_secrets;

-- Reset Data

delete from deathstar.user_roles;
delete from deathstar.users;
delete from deathstar.roles;
delete from deathstar.room_inventory;
delete from deathstar.deathstar_rooms;

insert into deathstar.users values (1, 'Dark Admin');
insert into deathstar.users values (2, 'Trainee Sam');
insert into deathstar.users values (3, 'Editor JarJar');
insert into deathstar.users values (4, 'Rebel');

insert into deathstar.roles values (1, 'ADMIN');
insert into deathstar.roles values (2, 'READ');
insert into deathstar.roles values (3, 'WRITE');

insert into deathstar.user_roles values (1, 1);
insert into deathstar.user_roles values (2, 2);
insert into deathstar.user_roles values (3, 3);

insert into deathstar.deathstar_rooms (id, name, code ) values (1, 'Engine Room 1', 'ENG1' );
insert into deathstar.deathstar_rooms (id, name, code ) values (2, 'Vaders Chamber', 'VADER' );
insert into deathstar.deathstar_rooms (id, name, code ) values (3, 'Bridge', 'BRIDGE' );
insert into deathstar.deathstar_rooms (id, name, code ) values (4, 'Prison 1', 'PRISON1' );


insert into deathstar.imperial_secrets (id, secret ) values (1, 'Vader is Lukes father');
insert into deathstar.imperial_secrets (id, secret ) values (2, 'The real, secret Sith master is Jar Jar Binks');
insert into deathstar.imperial_secrets (id, secret ) values (3, 'The Empire has no cookies');
commit;
