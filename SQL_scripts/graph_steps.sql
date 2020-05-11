--- part 1: for each branch of a thread, obtain a list of connected users ---
---for each chain of comments---
drop view if exists graph_subthread_comments;
create view graph_subthread_comments as select postid as subthread_id, array_agg(userid) as comment_user_agg from comments_gis group by postid;
---for each chain of answers---
drop view if exists graph_thread_answers;
create view graph_thread_answers as select parentid as thread_id, array_agg(owneruserid) as answer_user_agg from posts_gis where parentid>-99 group by parentid;
---list of subthreads (answers & associated user)---
drop view if exists graph_subthread_owners;
create view graph_subthread_owners as select row_id as subthread_id, owneruserid, parentid from posts_gis where posttypeid=2;
---list of threads (central user)---
drop view if exists graph_thread_owners;
create view graph_thread_owners as select row_id as thread_id, owneruserid from posts_gis where posttypeid!=2;

---for subthreads linked to an answer---
drop table if exists question_answer_subthreads;
create table question_answer_subthreads as
select g3.thread_id, g1.subthread_id, array_append( array_append(g2. comment_user_agg, g3.owneruserid), g1.owneruserid) as subthread_users
from graph_subthread_owners g1 join graph_subthread_comments g2 on g1.subthread_id=g2.subthread_id 
join graph_thread_owners g3 on g3.thread_id=g1.parentid;

---for subthreads directly linked to the question---
drop table if exists question_comment_subthreads;
create table question_comment_subthreads as 
select g2.thread_id, array_append(g1.comment_user_agg, g2.owneruserid)  as subthread_users
from graph_subthread_comments g1 join graph_thread_owners g2 on g1.subthread_id=g2.thread_id;

---part 2: now let's take care of the edits---
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
delete from  body_edits_additions where cur_id in (select cur_id from body_edits_diff where RollbackGUID !='None' and RollbackGUID=prev_guid); 
delete from  body_edits_additions where cur_id in (select cur_id from body_edits_diff where RollbackGUID !='None' and RollbackGUID!=prev_guid and RollbackGUID=prev_prev_GUID);
delete from body_edits_additions where cur_id in (select prev_id from body_edits_diff where RollbackGUID !='None' and RollbackGUID!=prev_guid and RollbackGUID=prev_prev_GUID);
delete from body_edits_additions where cur_id in (select cur_id from body_edits_diff where RollbackGUID !='None' and RollbackGUID!=prev_guid and RollbackGUID!=prev_prev_GUID);
delete from body_edits_additions where cur_id in (select prev_id from body_edits_diff where RollbackGUID !='None' and RollbackGUID!=prev_guid and RollbackGUID!=prev_prev_GUID);
delete from body_edits_additions where cur_id in (select cast(prev_prev_id as int)-1 from body_edits_diff where RollbackGUID !='None' and RollbackGUID!=prev_guid and RollbackGUID!=prev_prev_GUID);

---now, let's merge the data---
drop view if exists edit_users_by_subthread;
create view edit_users_by_subthread as 
select postid, array_agg(userid) as agg_edit_users from body_edits_additions group by postid;

drop table if exists question_comment_subthreads_with_edits;
create table question_comment_subthreads_with_edits as
select q.thread_id, array_cat(q.subthread_users, e.agg_edit_users) as subthread_users from question_comment_subthreads q join edit_users_by_subthread e on q.thread_id = e.postid;

drop table if exists question_answer_subthreads_with_edits;
create table question_answer_subthreads_with_edits as
select q.thread_id, array_cat(q.subthread_users, e.agg_edit_users) as subthread_users from question_answer_subthreads q join edit_users_by_subthread e on q.thread_id = e.postid;

--- last but not least, the answer clusters: here, edits are not included (to edit an answer, people do not necessarily read the other's answers)---
drop table if exists answer_clusters;
create table answer_clusters as
select array_agg(owneruserid) as subthread_users from graph_subthread_owners group by parentid;