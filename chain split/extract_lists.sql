---first, the comment lists for each question---
drop table if exists list_splitting_raw_data cascade;
create table list_splitting_raw_data with oids as 
select * from sampling_qora_co_prep s join comments_gis c on s.question_id = c.postid order by s.question_id, c.creationdate;

drop view if exists list_splitting_qora_first_comment_OIDs;
create view list_splitting_qora_first_comment_OIDs as
select distinct on (question_id)
OID as first_comment_oid, question_id as parentid, 0 as ordernumber
from list_splitting_raw_data
order by question_id, OID;

drop table if exists sampling_2nd_comment_is_author;
create table sampling_2nd_comment_is_author as
select l.question_id from list_splitting_raw_data l join list_splitting_qora_first_comment_OIDs i on
cast(l.OID as integer)=cast(i.first_comment_OID as integer)+1 and
l.question_id=i.parentid where l.question_user_id=l.userid;

---now let's get to the real chain splitting---
---there are three rules: 
---72h between two comments (can be checked directly, oid=oid+1)
---no '@' in the message following the gap, not followed by a space (can be checked directly in the comment body)
---the user has not posted a comment or an answer in the preceeding chain (can only be checked retroactively)

---approach:
---any first comment starts a chain, see list_splitting_qora_first_comment_OIDs
---any last comment closes a chain:
drop view if exists list_splitting_qora_last_comment_OIDs;
create view list_splitting_qora_last_comment_OIDs as
select distinct on (question_id)
OID as first_comment_oid, question_id as parentid, 999999 as ordernumber
from list_splitting_raw_data
order by question_id, OID desc;

---now label for >72h gaps and comments containing '@'+username
create index list_splitting_idx1 on list_splitting_raw_data(OID, postid, userid, creationdate, position('@' in body));

select l1.OID as comment_oid, l1.body, l1.userid, l1.userid in (select userid from list_splitting_raw_data where postid=l1.postid and creationdate<l1.creationdate) as new_user,
l1.question_id as comment_parentid, position('@' in l1.body)=0 as no_handle_check, extract(epoch from l1.creationdate-l2.creationdate)>3600*72 as check72h, 
l1.creationdate as creationdate_new_chain																										
from list_splitting_raw_data l1 join list_splitting_raw_data l2 on l1.postid=l2.postid and cast(l1.oid as int)=cast(l2.oid as int)+1
where position('@' in l1.body)=0 and extract(epoch from l1.creationdate-l2.creationdate)>3600*72 and 
l1.userid not in (select userid from list_splitting_raw_data where postid=l1.postid and creationdate<l1.creationdate)
and l1.question_id=290805 limit 10;

drop table if exists list_splitting_splitcomments;
create table list_splitting_splitcomments as
select l1.OID as comment_oid, l1.body, l1.userid,
l1.question_id as comment_parentid, l1.creationdate as creationdate_new_chain																										
from list_splitting_raw_data l1 join list_splitting_raw_data l2 on l1.postid=l2.postid and cast(l1.oid as int)=cast(l2.oid as int)+1
where position('@' in l1.body)=0 and extract(epoch from l1.creationdate-l2.creationdate)>3600*72 and 
l1.userid not in (select userid from list_splitting_raw_data where postid=l1.postid and creationdate<l1.creationdate);

drop table if exists list_splitting_chain_number;
create table list_splitting_chain_number as
select comment_parentid, count(*) from list_splitting_splitcomments group by comment_parentid;																										

---create selection of answer lists---
drop table if exists list_splitting_validation_as;
create table list_splitting_validation_as
(answer_id int, count int);
drop table if exists list_splitting_validation_as_tag_ids;
create table list_splitting_validation_as_tag_ids
(tag_id int);

DO $$
BEGIN
FOR counter IN 1..25 LOOP
	drop table if exists inserter;
	create table inserter as 
	select c.count, s.answerid, t.row_id as tag_id from sampling_qa_co_prep s 
	join sampling_top_50_tags t on  t.row_id=any(s.agg_tag_ids)
	left join list_splitting_chain_number c on s.answerid=c.comment_parentid
	where s.typeid=1 and t.row_id not in (select * from list_splitting_validation_as_tag_ids) 
	and s.answerid not in (select answer_id from list_splitting_validation_as) and c.count is null
	order by s.answer_comments desc limit 1;
	insert into list_splitting_validation_as
	select answerid, count from inserter;
	insert into list_splitting_validation_as_tag_ids
	select tag_id from inserter;																									
END LOOP;																										

FOR counter IN 1..25 LOOP
	drop table if exists inserter;
	create table inserter as 
	select c.count, s.answerid, t.row_id as tag_id from sampling_qa_co_prep s 
	join sampling_top_50_tags t on  t.row_id=any(s.agg_tag_ids)
	left join list_splitting_chain_number c on s.answerid=c.comment_parentid
	where s.typeid=1 and t.row_id not in (select * from list_splitting_validation_as_tag_ids) 
	and s.answerid not in (select answer_id from list_splitting_validation_as) 
	and c.count>1
	order by s.answer_comments desc limit 1;
	insert into list_splitting_validation_as
	select answerid, count from inserter;
	insert into list_splitting_validation_as_tag_ids
	select tag_id from inserter;																									
END LOOP;																										
END; $$	

select * from list_splitting_validation_as;																											

---create selection of question lists---
drop table if exists list_splitting_validation_qs;
create table list_splitting_validation_qs
(question_id int, count int);
drop table if exists list_splitting_validation_qs_tag_ids;
create table list_splitting_validation_qs_tag_ids
(tag_id int);																										

DO $$
BEGIN
FOR counter IN 1..25 LOOP
	drop table if exists inserter;
	create table inserter as 
	select c.count, s.question_id, t.row_id as tag_id from sampling_qora_co_prep s 
	join sampling_top_50_tags t on  t.row_id=any(s.agg_tag_ids)
	left join list_splitting_chain_number c on s.question_id=c.comment_parentid
	where s.typeid=1 and t.row_id not in (select * from list_splitting_validation_qs_tag_ids) 
	and s.question_id not in (select question_id from list_splitting_validation_qs)
	and c.count is null
	order by s.question_comments desc limit 1;
	insert into list_splitting_validation_qs
	select question_id, count from inserter;
	insert into list_splitting_validation_qs_tag_ids
	select tag_id from inserter;																									
END LOOP;

FOR counter IN 1..25 LOOP
	drop table if exists inserter;
	create table inserter as 
	select c.count, s.question_id, t.row_id as tag_id from sampling_qa_co_prep s 
	join sampling_top_50_tags t on  t.row_id=any(s.agg_tag_ids)
	left join list_splitting_chain_number c on s.question_id=c.comment_parentid
	where s.typeid=1 and t.row_id not in (select * from list_splitting_validation_qs_tag_ids) 
	and s.answerid not in (select question_id from list_splitting_validation_qs) 
	and c.count>1
	order by s.answer_comments desc limit 1;
	insert into list_splitting_validation_qs
	select question_id, count from inserter;
	insert into list_splitting_validation_qs_tag_ids
	select tag_id from inserter;																									
END LOOP;																										
END; $$	
