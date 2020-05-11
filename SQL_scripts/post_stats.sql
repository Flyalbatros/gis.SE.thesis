drop table if exists question_answer_stats_GIS;
create table question_answer_stats_GIS as select p1.row_id as question_id, p1.score as q_score, p1.LastEditorUserId>0 as q_edited, p1.CommunityOwnedDate>'0001-01-01 00:00:00' as wiki, p2.row_Id as answerId, p2.LastEditorUserId>0 as a_edited, p1.AcceptedAnswerId, p2.score as a_score, p1.viewcount, p1.owneruserid as question_user_id, p2.owneruserid as answer_user_id
from posts_gis p1 join posts_gis p2 on p1.row_id=p2.parentId
group by p1.row_id, p1.LastEditorUserId, p1.CommunityOwnedDate, p1.AcceptedAnswerId, p1.score, p1.viewcount, p1.owneruserid, p2.row_Id, p2.LastEditorUserId, p2.owneruserid, p2.score;

drop index if exists comment_posts_idx;
create index comment_posts_idx on comments_GIS(PostId);
drop index if exists question_id_idex;
create index question_id_idex on question_answer_stats_GIS(question_id);
drop index if exists answer_id_idex;
create index answer_id_idex on question_answer_stats_GIS(answerid);

drop table if exists question_answer_comment_stats_GIS;
create table question_answer_comment_stats_GIS as 
select s1.*, (Select count(*) from comments_GIS c where c.PostId=s1.question_id) as question_comments, (Select count(*) from comments_GIS c where c.PostId=s1.answerid) as answer_comments
from question_answer_stats_GIS s1
group by s1.question_id, s1.q_edited, s1.wiki, s1.answerId, s1.AcceptedAnswerId, s1.a_edited, s1.q_score, s1.a_score, s1.viewcount, s1.question_user_id, s1.answer_user_id;

drop view if exists answer_by_user;

create view answer_by_user as select answer_user_id, count(*) as number_answers from question_answer_comment_stats_GIS group by answer_user_id;
drop view if exists questions_by_user;
create view questions_by_user as select question_user_id, count(*) as number_questions from question_answer_comment_stats_GIS group by question_user_id;

drop table if exists user_activity;
create table user_activity as select a.answer_user_id as user_id, a.number_answers, q.number_questions, u.reputation, u.upvotes, u.downvotes, u.upvotes-u.downvotes as net_votes from answer_by_user a join questions_by_user q on a.answer_user_id=q.question_user_id join users_gis u on a.answer_user_id=u.row_id;

select * from user_activity limit 5;

create table export_3 as select q.*, u.number_answers as answerer_number_answers, u.number_questions as answerer_number_questions, u.reputation as answerer_reputation, v.number_answers as asker_number_answers, v.number_questions as asker_number_questions, v.reputation as asker_reputation from question_answer_comment_stats_GIS q join user_activity u on q.answer_user_id=u.user_id join user_activity v on q.question_user_id=v.user_id;

--- export part ---

drop table if exists export_2;
create table export_2 as 
select question_id, max(q_score) + sum(a_score) as total_score, max(viewcount) as viewcount, count(*) as answer_number, max(question_comments) + sum(answer_comments) as comment_number, bool_or(q_edited) as q_edited, bool_or(a_edited) as a_edited, bool_or(wiki) as wiki
from question_answer_comment_stats_GIS
group by question_id;

select * from question_answer_comment_stats_GIS where question_id = '124583';

select question_id, max(q_score) + sum(a_score) as total_score, max(viewcount) as viewcount, count(*) as answer_number, max(question_comments) + sum(answer_comments) as comment_number, bool_or(q_edited) as q_edited, bool_or(a_edited) as a_edited, bool_or(wiki) as wiki
from question_answer_comment_stats_GIS
group by question_id
order by comment_number desc;

select count(*) from posts_gis where posttypeid='1';

