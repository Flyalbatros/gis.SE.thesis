drop table if exists sampling_post_tags_prep;
create table sampling_post_tags_prep as
select p.row_id as post_id, t.row_id as tag_id, t.tagname
from posts_gis p join tags_gis t on position('&lt;'||t.tagname||'&gt;' in p.tags)>0
where posttypeid=1 and p.;

select * from posts_gis;
drop table if exists sampling_post_tags;
create table sampling_post_tags as
select post_id, array_agg(tag_id) as agg_tag_ids
from sampling_post_tags_prep
group by post_id;

---now let's get the number of comments per question/answer combination---
drop table if exists gstats_qa_co_prep;
create table gstats_qa_co_prep as 
select s1.*, t.agg_tag_ids, (Select count(*) from comments_GIS c where c.PostId=s1.question_id) as question_comments, (Select count(*) from comments_GIS c where c.PostId=s1.answerid) as answer_comments
from gstats_qa_prep s1 join sampling_post_tags t on t.post_id=s1.question_id
group by s1.question_id, s1.question_creationdate, s1.q_edited, s1.wiki, s1.answerId, s1.AcceptedAnswerId, s1.answer_creationdate, s1.a_edited, s1.q_score, s1.a_score, s1.viewcount, s1.question_user_id, s1.answer_user_id, t.agg_tag_ids;

---selection: the 50 tags which are most used--- alternative? identify and filter out frequent tag combinations?
select sum(post_count) from tags_gis; ---379714
drop view if exists sampling_top_50_tags;
create view sampling_top_50_tags as
select row_id, post_count from tags_gis order by post_count desc limit 50;
select sum(post_count) from sampling_top_50_tags; ---192675.0/379714.0---50.7%

---to debug: sth goes wrong in the aggregation of tag_ids---
select distinct on (t.row_id)
t.row_id, s.question_id, s.question_comments, s.agg_tag_ids
from sampling_top_50_tags t join gstats_qa_co_prep s on t.row_id= any(s.agg_tag_ids)
order by t.row_id, s.question_comments desc;

select * from gstats_qa_co_prep where 2 = any(agg_tag_ids)
order by question_comments desc;

select * from posts_gis where row_id=60120;
