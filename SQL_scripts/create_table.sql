drop table if exists posts_GIS;
create table posts_GIS (
row_Id int,
PostTypeId int,
AcceptedAnswerId int, 
CreationDate timestamp, 
Score int, 
ViewCount int, 
Body text, 
OwnerUserId int, 
LastEditDate timestamp, 
LastActivityDate timestamp, 
Title text, 
AnswerCount int, 
CommentCount int, 
FavoriteCount int);