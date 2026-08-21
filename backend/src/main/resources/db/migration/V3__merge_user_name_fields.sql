alter table users add column full_name varchar(200);

update users set full_name = trim(first_name || ' ' || last_name);

alter table users alter column full_name set not null;

alter table users drop column first_name;
alter table users drop column last_name;
