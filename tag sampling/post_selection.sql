---this is only taking into account posts that had at least one activity after 31/12/2016 and before 01/01/2020
drop table if exists sampling_post_tags_prep;
create table sampling_post_tags_prep as
select p.row_id as post_id, t.row_id as tag_id, t.tagname
from posts_gis p join tags_gis t on position('&lt;'||t.tagname||'&gt;' in p.tags)>0
where posttypeid=1;

drop table if exists sampling_post_tags cascade;
create table sampling_post_tags as
select post_id, array_agg(tag_id) as agg_tag_ids
from sampling_post_tags_prep
group by post_id;

---now let's get the number of comments per question/answer combination---
---get the date of the most recent comment on the question---
drop view if exists sampling_last_commentdate_prep;
create view sampling_last_commentdate_prep as
select distinct on (c.postid) c.postid, c.creationdate as last_comment_date from comments_gis c order by c.postid, c.creationdate desc;

---get the list of all questions, with or without answers (when no answer there might still be comments)---
drop table if exists sampling_qa_prep;
create table sampling_qa_prep as select p1.row_id as question_id, p1.posttypeid typeid, p1.score as q_score, p1.creationdate as question_creationdate, p1.LastEditorUserId>0 as q_edited, p1.CommunityOwnedDate>'0001-01-01 00:00:00' as wiki, p2.row_Id as answerId, p2.LastEditorUserId>0 as a_edited, p1.AcceptedAnswerId, p2.score as a_score, p2.creationdate as answer_creationdate, p1.viewcount, p1.owneruserid as question_user_id, p2.owneruserid as answer_user_id
from posts_gis p1 left join posts_gis p2 on p1.row_id=p2.parentId
group by p1.row_id, p1.posttypeid, p1.creationdate, p1.LastEditorUserId, p1.CommunityOwnedDate, p1.AcceptedAnswerId, p1.score, p1.viewcount, p1.owneruserid, p2.row_Id, p2.creationdate, p2.LastEditorUserId, p2.owneruserid, p2.score
order by question_id, answer_creationdate;

---now let's get the number of comments for each---
drop table if exists sampling_qa_co_prep cascade;
create table sampling_qa_co_prep as 
select s1.*, t.agg_tag_ids, (Select count(*) from comments_GIS c where c.PostId=s1.question_id) as question_comments, (Select count(*) from comments_GIS c where c.PostId=s1.answerid) as answer_comments, c.last_comment_date
from sampling_qa_prep s1 left join sampling_last_commentdate_prep c on c.postid=s1.question_id left join sampling_post_tags t on t.post_id=s1.question_id 
group by s1.question_id, s1.typeid, s1.question_creationdate, s1.q_edited, s1.wiki, s1.answerId, s1.AcceptedAnswerId, s1.answer_creationdate, s1.a_edited, s1.q_score, s1.a_score, s1.viewcount, s1.question_user_id, s1.answer_user_id, t.agg_tag_ids, c.last_comment_date;

delete from sampling_qa_co_prep
where extract(year from question_creationdate)>2019 or extract(year from last_comment_date)<2017;

drop view if exists sampling_qora_co_prep;
create view sampling_qora_co_prep as
select distinct on (question_id)
*
from sampling_qa_co_prep
order by question_id, answer_comments desc;
---lets create a post count for each tag for the period in questions---
drop view if exists sampling_tag_count_1719;
create view sampling_tag_count_1719 as
select t.row_id, count(*) as post_count
from tags_gis t join sampling_qora_co_prep p on t.row_id = any(p.agg_tag_ids)
where p.typeid=1
group by t.row_id;

---selection: the 50 tags which are most used--- alternative? identify and filter out frequent tag combinations?
select count(*) from posts_gis where posttypeid=1; ---125167 questions in total---
select count(*) from sampling_qora_co_prep where typeid=1; ---77662 question active in timeframe, with at least one comment---
drop table if exists sampling_top_50_tags;
create table sampling_top_50_tags as
select row_id, post_count from sampling_tag_count_1719 order by post_count desc limit 50;
select count(distinct(p.question_id)) from sampling_top_50_tags t join sampling_q_co_prep p on t.row_id=any(p.agg_tag_ids); ---17908 active question
---68067/77662=87.6%---

---identify distribution of the number of comments on questions---
drop table if exists sampling_analysis_question_comments;
create table sampling_analysis_question_comments as			  
select question_id, question_comments
from sampling_qora_co_prep
where typeid=1;

select count(*) from sampling_analysis_question_comments; ---77662
select count(*)/77662.0 from sampling_analysis_question_comments where question_comments>2 or question_id in (select * from sampling_2nd_comment_is_author);
---25.1% elligible
select count(*)/77662.0 from sampling_analysis_question_comments where question_comments<8; ---97.6%
select count(*)/77662.0 from sampling_analysis_question_comments where question_comments<9; ---98.5%, 			  

---select the questions to be analysed, budget=50 questions---
select count(*) from sampling_analysis_question_comments where question_comments=2 and question_id in (select * from sampling_2nd_comment_is_author);					  
---4120				  
select count(*) from sampling_analysis_question_comments where question_comments=3;	---5144
select count(*) from sampling_analysis_question_comments where question_comments=4;	---3574
select count(*) from sampling_analysis_question_comments where question_comments=5;	---2340
select count(*) from sampling_analysis_question_comments where question_comments=6;	---1548	
select count(*) from sampling_analysis_question_comments where question_comments=7;	---1028			  
select count(*) from sampling_analysis_question_comments where question_comments=8;	---641			  
select count(*) from sampling_analysis_question_comments where question_comments=9;	---379			  
select count(*) from sampling_analysis_question_comments where question_comments=10;	---264
---
create index sampling_top50_ids on sampling_top_50_tags(row_id);
drop table if exists sampling_selected_questions;
create table sampling_selected_questions 
(question_id int);
drop table if exists sampling_selected_q_tag_log;
create table sampling_selected_q_tag_log
(tag_id int);
					  
drop table if exists inserter;
create table inserter as
select t.row_id, s.question_id from sampling_qora_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and question_comments=10 order by random() limit 1;
insert into sampling_selected_questions					  
select question_id from inserter;
insert into sampling_selected_q_tag_log
select row_id from inserter;

drop table if exists inserter;
create table inserter as
select t.row_id, s.question_id from sampling_qora_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and question_comments=9 and t.row_id not in (select * from sampling_selected_q_tag_log) order by random() limit 1;
insert into sampling_selected_questions					  
select question_id from inserter;
insert into sampling_selected_q_tag_log
select row_id from inserter;
					  
DO $$					  
BEGIN					  
FOR counter IN 1..2 LOOP
	drop table if exists inserter;
	create table inserter as
	select t.row_id, s.question_id from sampling_qora_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and question_comments=8 and t.row_id not in (select * from sampling_selected_q_tag_log) order by random() limit 1;
	insert into sampling_selected_questions					  
	select question_id from inserter;
	insert into sampling_selected_q_tag_log
	select row_id from inserter;
end loop;
				  				  
FOR counter IN 1..3 LOOP
	drop table if exists inserter;
	create table inserter as
	select t.row_id, s.question_id from sampling_qora_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and question_comments=7 and t.row_id not in (select * from sampling_selected_q_tag_log) order by random() limit 1;
	insert into sampling_selected_questions					  
	select question_id from inserter;
	insert into sampling_selected_q_tag_log
	select row_id from inserter;
end loop;
					  
FOR counter IN 1..4 LOOP
	drop table if exists inserter;
	create table inserter as
	select t.row_id, s.question_id from sampling_qora_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and question_comments=6 and t.row_id not in (select * from sampling_selected_q_tag_log) order by random() limit 1;
	insert into sampling_selected_questions					  
	select question_id from inserter;
	insert into sampling_selected_q_tag_log
	select row_id from inserter;
end loop;
					  
FOR counter IN 1..6 LOOP
	drop table if exists inserter;
	create table inserter as
	select t.row_id, s.question_id from sampling_qora_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and question_comments=5 and t.row_id not in (select * from sampling_selected_q_tag_log) order by random() limit 1;
	insert into sampling_selected_questions					  
	select question_id from inserter;
	insert into sampling_selected_q_tag_log
	select row_id from inserter;
end loop;
					  
FOR counter IN 1..9 LOOP
	drop table if exists inserter;
	create table inserter as
	select t.row_id, s.question_id from sampling_qora_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and question_comments=4 and t.row_id not in (select * from sampling_selected_q_tag_log) order by random() limit 1;
	insert into sampling_selected_questions					  
	select question_id from inserter;
	insert into sampling_selected_q_tag_log
	select row_id from inserter;
end loop;
				  
FOR counter IN 1..13 LOOP
	drop table if exists inserter;
	create table inserter as
	select t.row_id, s.question_id from sampling_qora_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and question_comments=3 and t.row_id not in (select * from sampling_selected_q_tag_log) order by random() limit 1;
	insert into sampling_selected_questions					  
	select question_id from inserter;
	insert into sampling_selected_q_tag_log
	select row_id from inserter;
end loop;
				  
FOR counter IN 1..11 LOOP
	drop table if exists inserter;
	create table inserter as
	select t.row_id, s.question_id from sampling_qora_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and question_comments=2 and question_id in (select * from sampling_2nd_comment_is_author) and t.row_id not in (select * from sampling_selected_q_tag_log) order by random() limit 1;
	insert into sampling_selected_questions					  
	select question_id from inserter;
	insert into sampling_selected_q_tag_log
	select row_id from inserter;
end loop;
END; $$
					  
select * from sampling_selected_questions;
					  
---identify ditribution of the number of comments on answers---
drop table if exists sampling_analysis_answer_comments;
create table sampling_analysis_answer_comments as			  
select question_id as answer_id, question_comments as answer_comments
from sampling_qora_co_prep
where typeid=2;

select count(*) from sampling_analysis_answer_comments; ---96775
select count(*)/96775.0 from sampling_analysis_answer_comments where answer_comments>2 or answer_id in (select * from sampling_2nd_comment_is_author); 
---12.0% eligible
select count(*)/96775.0 from sampling_analysis_answer_comments where answer_comments<5; ---96.7%
select count(*)/96775.0 from sampling_analysis_answer_comments where answer_comments<6; ---96.1%
---final distribution---
select count(*) from sampling_analysis_answer_comments where answer_comments=2 and answer_id in (select * from sampling_2nd_comment_is_author); 
---3667
select count(*) from sampling_analysis_answer_comments where answer_comments=3;
---2897
select count(*) from sampling_analysis_answer_comments where answer_comments=4;
---1856
select count(*) from sampling_analysis_answer_comments where answer_comments=5;
---1096
select count(*) from sampling_analysis_answer_comments where answer_comments=6;
---716
select count(*) from sampling_analysis_answer_comments where answer_comments=7;
---477
select count(*) from sampling_analysis_answer_comments where answer_comments=8;
--294
select count(*) from sampling_analysis_answer_comments where answer_comments=9;
---188
select count(*) from sampling_analysis_answer_comments where answer_comments=10;
---118
select count(*) from sampling_analysis_answer_comments where answer_comments=11;

---now let's perform the selection of threads---
drop table if exists sampling_selected_answers;
create table sampling_selected_answers 
(question_id int);
drop table if exists sampling_selected_a_tag_log;
create table sampling_selected_a_tag_log
(tag_id int);
					  
drop table if exists inserter;
create table inserter as
select t.row_id, s.answerid from sampling_qa_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and answer_comments=10 order by random() limit 1;
insert into sampling_selected_answers					  
select answerid from inserter;
insert into sampling_selected_a_tag_log
select row_id from inserter;

drop table if exists inserter;
create table inserter as
select t.row_id, s.answerid from sampling_qa_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and answer_comments=9 and t.row_id not in (select * from sampling_selected_a_tag_log) order by random() limit 1;
insert into sampling_selected_answers					  
select answerid from inserter;
insert into sampling_selected_a_tag_log
select row_id from inserter;

drop table if exists inserter;
create table inserter as
select t.row_id, s.answerid from sampling_qa_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and answer_comments=8 and t.row_id not in (select * from sampling_selected_a_tag_log) order by random() limit 1;
insert into sampling_selected_answers					  
select answerid from inserter;
insert into sampling_selected_a_tag_log
select row_id from inserter;
					  
DO $$					  
BEGIN					  
FOR counter IN 1..2 LOOP
	drop table if exists inserter;
	create table inserter as
	select t.row_id, s.answerid from sampling_qa_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and answer_comments=7 and t.row_id not in (select * from sampling_selected_a_tag_log) order by random() limit 1;
	insert into sampling_selected_answers					  
	select answerid from inserter;
	insert into sampling_selected_a_tag_log
	select row_id from inserter;
end loop;

FOR counter IN 1..3 LOOP
	drop table if exists inserter;
	create table inserter as
	select t.row_id, s.answerid from sampling_qa_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and answer_comments=6 and t.row_id not in (select * from sampling_selected_a_tag_log) order by random() limit 1;
	insert into sampling_selected_answers					  
	select answerid from inserter;
	insert into sampling_selected_a_tag_log
	select row_id from inserter;
end loop;
					  
FOR counter IN 1..5 LOOP
	drop table if exists inserter;
	create table inserter as
	select t.row_id, s.answerid from sampling_qa_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and answer_comments=5 and t.row_id not in (select * from sampling_selected_a_tag_log) order by random() limit 1;
	insert into sampling_selected_answers					  
	select answerid from inserter;
	insert into sampling_selected_a_tag_log
	select row_id from inserter;
end loop;
					  
FOR counter IN 1..8 LOOP
	drop table if exists inserter;
	create table inserter as
	select t.row_id, s.answerid from sampling_qa_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and answer_comments=4 and t.row_id not in (select * from sampling_selected_a_tag_log) order by random() limit 1;
	insert into sampling_selected_answers					  
	select answerid from inserter;
	insert into sampling_selected_a_tag_log
	select row_id from inserter;
end loop;
					  
FOR counter IN 1..13 LOOP
	drop table if exists inserter;
	create table inserter as
	select t.row_id, s.answerid from sampling_qa_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and answer_comments=3 and t.row_id not in (select * from sampling_selected_a_tag_log) order by random() limit 1;
	insert into sampling_selected_answers					  
	select answerid from inserter;
	insert into sampling_selected_a_tag_log
	select row_id from inserter;
end loop;
					  
FOR counter IN 1..16 LOOP
	drop table if exists inserter;
	create table inserter as
	select t.row_id, s.answerid from sampling_qa_co_prep s join sampling_top_50_tags t on t.row_id=any(s.agg_tag_ids) where typeid=1 and answer_comments=2 and t.row_id not in (select * from sampling_selected_a_tag_log) and s.answerid in (select * from sampling_2nd_comment_is_author) order by random() limit 1;
	insert into sampling_selected_answers					  
	select answerid from inserter;
	insert into sampling_selected_a_tag_log
	select row_id from inserter;
end loop;
END; $$