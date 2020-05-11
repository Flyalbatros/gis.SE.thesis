drop table if exists comments_GIS;
create table comments_GIS (
row_id int,
PostId int, 
score int,
body text,
CreationDate timestamp,
UserId int)
