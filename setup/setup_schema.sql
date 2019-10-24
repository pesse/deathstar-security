create user deathstar identified by :password default tablespace users quota unlimited on users;

grant create session, create sequence, create procedure, create type, create table, create view, create synonym, create trigger to deathstar;

grant alter session to deathstar;


create user connect_only identified by password;

grant create session to connect_only;

create user darth_dba identified by darth_dba;
alter user darth_dba identified by password;
alter user darth_dba default tablespace  users quota unlimited on users;
grant dba to darth_dba with admin option;
grant grant any role to darth_dba;
revoke dba from darth_dba;
grant connect to darth_dba;
grant create session to darth_dba;
