drop table if exists posts_GIS;
create table posts_GIS (
row_Id int,
PostTypeId int,
ParentId int,
AcceptedAnswerId int, 
CreationDate timestamp null, 
Score int, 
ViewCount int, 
Body text, 
OwnerUserId int,
LastEditorUserId int,
LastEditDate timestamp null,
LastActivityDate timestamp null,
Tags text,
Title text, 
AnswerCount int, 
CommentCount int, 
FavoriteCount int,
CommunityOwnedDate timestamp null);