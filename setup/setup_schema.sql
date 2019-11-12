-- User DEATHSTAR (application)
create user deathstar identified by :password default tablespace users quota unlimited on users;

grant create session, create sequence, create procedure, create type, create table, create view, create synonym, create trigger to deathstar;

grant alter session to deathstar;

-- User DARTH_DBA
create user darth_dba identified by darth_dba default tablespace  users quota unlimited on users;

grant connect to darth_dba;
grant dba to darth_dba with admin option;
