create table if not exists test_table (id int, col1 varchar(255), col2 varchar(255));
insert into test_table values (1, 'a', 'aaa'),(2, 'b', 'bbb');
select * from test_table limit 10;
