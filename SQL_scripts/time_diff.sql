drop table if exists posts_comments_GIS;
create table posts_comments_GIS with OIDS as
select postid, creationdate, 99 as type
from comments_gis
union
select row_id, creationdate, posttypeid
from posts_gis
order by postid, creationdate;
create index time_diff_index on posts_comments_GIS(postid, creationdate);

select p1.OID, p2.OID, p3.OID, p1.userid, p2.userid, p3.userid, p1.postid
from posts_comments_GIS p1 join posts_comments_GIS p2 
on cast(p1.OID as integer)=cast(p2.OID as integer)-1 and p1.postid=p2.postid 
join posts_comments_GIS p3 
on cast(p1.OID as integer)=cast(p3.OID as integer)+1 and p1.postid=p3.postid
and p2.userid=p3.userid
where p1.postid!='-99' 
order by p1.OID;

drop table if exists time_diff;
create table time_diff as 
select extract(epoch from p2.creationdate-p1.creationdate) as time_diff_next, extract(epoch from p1.creationdate-p3.creationdate) as time_diff_prev
from posts_comments_GIS p1 join posts_comments_GIS p2 
on cast(p1.OID as integer)=cast(p2.OID as integer)-1 and p1.postid=p2.postid 
join posts_comments_GIS p3 
on cast(p1.OID as integer)=cast(p3.OID as integer)+1 and p1.postid=p3.postid
and p2.userid=p3.userid
where p1.postid!='-99' 
order by p1.OID;

select count(*) from time_diff; ---74856---
select cast(count(*) as float)/74856 from time_diff where time_diff_next<72*3600; ---66507--- 94.7%
select cast(count(*) as float)/74856 from time_diff where time_diff_prev<72*3600; ---68007--- 95.7%

select cast(count(*) as float)/74856 from time_diff where time_diff_next<48*3600; ---66507--- 92.7%
select cast(count(*) as float)/74856 from time_diff where time_diff_prev<48*3600; ---68007--- 94.2%

select cast(count(*) as float)/74856 from time_diff where time_diff_next<24*3600; ---66507--- 88%
select cast(count(*) as float)/74856 from time_diff where time_diff_prev<24*3600; ---68007--- 90%

select cast(count(*) as float)/74856 from time_diff where time_diff_next<4*3600; ---53420--- 71%
select cast(count(*) as float)/74856 from time_diff where time_diff_prev<4*3600; ---55570--- 74%



