select row_id, postid, creationdate, userid, 'comment' from comments_GIS where postid != '-99';


---let's take care of the edits---
drop index if exists edits_index;
create index edits_index on edits_gis(posthistorytypeid,RollbackGUID);
drop table if exists body_edits;
create table body_edits with oids as
select *, length(content_text) 
from edits_gis where posthistorytypeid in (2,5,8)
order by postid, creationdate;

drop view if exists body_edits_diff;
create view body_edits_diff as
select b1.oid as cur_id, b2.oid as prev_id, b4.oid as prev_prev_id, b3.oid as next_oid, b1.postid, b1.userid, b1.posthistorytypeid, b3.posthistorytypeid as next_typeid, b2.posthistorytypeid as prev_typeid, b2.RevisionGUID as prev_GUID, b4.RevisionGUID as prev_prev_GUID, b3.RollbackGUID, cast(b1.length as float)/cast(b2.length as float) as length_ratio 
from body_edits b1 join body_edits b2 on cast(b1.oid as integer)=cast(b2.oid as integer)+1 and b1.postid=b2.postid
join body_edits b3 on cast(b1.oid as integer)=cast(b3.oid as integer)-1 and b1.postid=b3.postid
join body_edits b4 on cast(b1.oid as integer)=cast(b4.oid as integer)+2 and b1.postid=b4.postid
where b2.length>0;

drop table if exists body_edits_additions;
create table body_edits_additions as 
select * from body_edits_diff where length_ratio>1.1;

---assumption: edits rollbacks do not go more than three posts back, removing edits based on this---
delete from body_edits_additions where cur_id in (select cur_id from body_edits_diff where RollbackGUID !='None' and RollbackGUID=prev_guid); 
delete from body_edits_additions where cur_id in (select cur_id from body_edits_diff where RollbackGUID !='None' and RollbackGUID!=prev_guid and RollbackGUID=prev_prev_GUID);
delete from body_edits_additions where cur_id in (select prev_id from body_edits_diff where RollbackGUID !='None' and RollbackGUID!=prev_guid and RollbackGUID=prev_prev_GUID);
delete from body_edits_additions where cur_id in (select cur_id from body_edits_diff where RollbackGUID !='None' and RollbackGUID!=prev_guid and RollbackGUID!=prev_prev_GUID);
delete from body_edits_additions where cur_id in (select prev_id from body_edits_diff where RollbackGUID !='None' and RollbackGUID!=prev_guid and RollbackGUID!=prev_prev_GUID);
delete from body_edits_additions where cur_id in (select cast(prev_prev_id as int)-1 from body_edits_diff where RollbackGUID !='None' and RollbackGUID!=prev_guid and RollbackGUID!=prev_prev_GUID);

select postid, userid, from body_edits_additions limit 10;
