---first, the comment lists for each question---
drop table if exists list_splitting_raw_data cascade;
create table list_splitting_raw_data with oids as 
select * from sampling_qora_co_prep s join comments_gis c on s.question_id = c.postid order by s.question_id, c.creationdate;

drop view if exists list_splitting_qora_first_comment_OIDs;
create view list_splitting_qora_first_comment_OIDs as
select distinct on (question_id)
OID as first_comment_oid, question_id
from list_splitting_raw_data
order by question_id, OID;

drop table if exists sampling_2nd_comment_is_author;
create table sampling_2nd_comment_is_author as
select l.question_id from list_splitting_raw_data l join list_splitting_qora_first_comment_OIDs i on
cast(l.OID as integer)=cast(i.first_comment_OID as integer)+1 and
l.question_id=i.question_id where l.question_user_id=l.userid;

---now let's get to the real chain splitting---
---there are three rules: 
---72h between two comments (can be checked directly, oid=oid+1)
---no '@' in the message following the gap, not followed by a space (can be checked directly in the comment body)
---the user has not posted a comment or an answer in the preceeding chain (can only be checked retroactively)

---approach:
---any first comment starts a chain
select distinct on (question_id)
OID as first_comment_oid, question_id as qa_id
from list_splitting_raw_data
order by question_id, OID;
---now label for >72h gaps

---among these gaps eliminate the ones containing '@'+username

---create chains by linking comments to closest previous comment??


