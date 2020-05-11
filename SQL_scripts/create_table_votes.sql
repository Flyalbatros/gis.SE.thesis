drop table if exists votes_GIS;
create table votes_GIS (
row_Id int,
PostId int, 
VoteTypeId int, 
UserId int,
CreationDate timestamp)