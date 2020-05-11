drop table if exists edits_GIS;
create table edits_GIS (
row_Id int,
PostHistoryTypeId int, 
PostId int, 
RevisionGUID text,
CreationDate timestamp null, 
UserId int, 
Comment text,
RollbackGUID text,
Content_text text)