drop table if exists users_GIS;
create table users_GIS (
row_id int, 
Reputation int, 
CreationDate timestamp,
DisplayName text, 
LastAccessDate timestamp,
Location text, 
AboutMe text, 
Views int, 
UpVotes int, 
DownVotes int, 
AccountId int)