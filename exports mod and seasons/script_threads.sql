--- response time linked to usage of handles --- 
drop table if exists comment_handle_reaction;
create table comment_handle_reaction with OIDs as 
select c.postid, c.creationdate, c.body, c.userid, c.row_id, u.displayname 
from comments_gis c join users_gis u on c.userid=u.row_id order by c.postid, c.creationdate;

---select position('@'||substring(c1.displayname from 0 for 3) in c2.body), extract(epoch from c2.creationdate-c1.creationdate) as reaction_time, c1.*, c2.* from comment_handle_reaction c1 join comment_handle_reaction c2 on cast(c1.OID as int)=cast(c2.OID as int)-1 and c1.postid=c2.postid order by c1.postid, c1.creationdate;
drop view if exists comment_handle_reaction_nodirect cascade;
create view comment_handle_reaction_nodirect as
select c2.row_id
from comment_handle_reaction c1 join comment_handle_reaction c2 on cast(c1.OID as int)=cast(c2.OID as int)-1 and c1.postid=c2.postid 
where position('@'||substring(c1.displayname from 0 for 5) in c2.body)=0;

drop table if exists comment_handle_reaction_ids_direct cascade;
create table comment_handle_reaction_ids_direct as
select c2.row_id
from comment_handle_reaction c1 join comment_handle_reaction c2 on cast(c1.OID as int)=cast(c2.OID as int)-1 and c1.postid=c2.postid 
where position('@'||substring(c1.displayname from 0 for 5) in c2.body)>0;

drop view if exists comment_handle_reaction_nodirect_2;
create view comment_handle_reaction_nodirect_2 as
select c2.row_id
from comment_handle_reaction c1 join comment_handle_reaction c2 on cast(c1.OID as int)=cast(c2.OID as int)-2 and c1.postid=c2.postid 
where position('@'||substring(c1.displayname from 0 for 5) in c2.body)=0;

drop table if exists comment_handle_reaction_ids_direct_2;
create table comment_handle_reaction_ids_direct_2 as
select c2.row_id
from comment_handle_reaction c1 join comment_handle_reaction c2 on cast(c1.OID as int)=cast(c2.OID as int)-2 and c1.postid=c2.postid 
where position('@'||substring(c1.displayname from 0 for 5) in c2.body)<>0;

drop table if exists comment_handle_reaction_time;
create table comment_handle_reaction_time as
select extract(epoch from c2.creationdate-c1.creationdate)as reaction_time
from comment_handle_reaction c1 join comment_handle_reaction c2 on cast(c1.OID as int)=cast(c2.OID as int)-1 and c1.postid=c2.postid 
where position('@'||substring(c1.displayname from 0 for 5) in c2.body)>0
union
select extract(epoch from c2.creationdate-c1.creationdate)as reaction_time
from comment_handle_reaction c1 join comment_handle_reaction c2 on cast(c1.OID as int)=cast(c2.OID as int)-2 and c1.postid=c2.postid 
where position('@'||substring(c1.displayname from 0 for 5) in c2.body)>0 and c2.row_id in (select * from comment_handle_reaction_nodirect)
union
select extract(epoch from c2.creationdate-c1.creationdate)as reaction_time
from comment_handle_reaction c1 join comment_handle_reaction c2 on cast(c1.OID as int)=cast(c2.OID as int)-3 and c1.postid=c2.postid 
where position('@'||substring(c1.displayname from 0 for 5) in c2.body)>0 and c2.row_id in (select * from comment_handle_reaction_nodirect) and c2.row_id in (select * from comment_handle_reaction_nodirect_2);

drop view if exists comment_handle_reaction_time_date;
create view comment_handle_reaction_time_date as
select extract(epoch from c2.creationdate-c1.creationdate)as reaction_time, c1.creationdate
from comment_handle_reaction c1 join comment_handle_reaction c2 on cast(c1.OID as int)=cast(c2.OID as int)-1 and c1.postid=c2.postid 
where position('@'||substring(c1.displayname from 0 for 5) in c2.body)>0
union
select extract(epoch from c2.creationdate-c1.creationdate)as reaction_time, c1.creationdate
from comment_handle_reaction c1 join comment_handle_reaction c2 on cast(c1.OID as int)=cast(c2.OID as int)-2 and c1.postid=c2.postid 
where position('@'||substring(c1.displayname from 0 for 5) in c2.body)>0 and c2.row_id in (select * from comment_handle_reaction_nodirect)
union
select extract(epoch from c2.creationdate-c1.creationdate)as reaction_time, c1.creationdate
from comment_handle_reaction c1 join comment_handle_reaction c2 on cast(c1.OID as int)=cast(c2.OID as int)-3 and c1.postid=c2.postid 
where position('@'||substring(c1.displayname from 0 for 5) in c2.body)>0 and c2.row_id in (select * from comment_handle_reaction_nodirect) and c2.row_id in (select * from comment_handle_reaction_nodirect_2);

select count(*)/15141.0 from comment_handle_reaction_time_date where extract(year from creationdate)>2016 and extract(year from creationdate)<2020 and reaction_time>72*60*60;
---72h: 3702/22941=16.1%--- 
---48h: 4697/22941=20.47%---
---168h: 2480/22941=10.81%---
---336h: 2010/22941=8.76%---
---for data since 1/1/2017 until 1/1/2020 (15141)---
---72h: 1381/17014=8.3%---
---48h: =11.2%
---168h: =4.9%
---336h: 556/15141=3.7%

drop table if exists gstats_co_handle_monthly_percentile_reaction_time;
create table gstats_co_handle_monthly_percentile_reaction_time as
select extract(year from creationdate) as year, extract(month from creationdate) as month, count(*), 
(percentile_disc(0.9) within group (order by reaction_time)/(3600*24.0)) as ninetyth_percentile_reaction_time_days, 
(percentile_disc(0.1) within group (order by reaction_time)/(60.0)) as tenth_percentile_reaction_time_minutes
from comment_handle_reaction_time_date
group by year, month
order by year, month;
															 
drop table if exists gstats_co_handle_weekday_percentile_reaction_time;
create table gstats_co_handle_weekday_percentile_reaction_time as
select extract(year from creationdate) as year, extract(isodow from creationdate) as weekday, count(*), 
(percentile_disc(0.9) within group (order by reaction_time)/(3600*24.0)) as ninetyth_percentile_reaction_time_days, 
(percentile_disc(0.1) within group (order by reaction_time)/(60.0)) as tenth_percentile_reaction_time_minutes
from comment_handle_reaction_time_date
group by year, weekday
order by year, weekday;
															 

---comments per weekday---
drop view if exists gstats_co_weekday;
create view gstats_co_weekday as
select extract(year from creationdate) as year, extract(isodow from creationdate) as weekday, count(*)/365.0 as daily_co_mean
from comments_gis 
group by extract(year from creationdate), extract(isodow from creationdate)
order by year, weekday;

drop view if exists gstats_qs_weekday;
create view gstats_qs_weekday as
select extract(year from creationdate) as year, extract(isodow from creationdate) as weekday, count(*)/365.0 as daily_q_mean
from posts_gis where posttypeid=1
group by extract(year from creationdate), extract(isodow from creationdate)
order by year, weekday;

drop view if exists gstats_as_weekday;
create view gstats_as_weekday as
select extract(year from creationdate) as year, extract(isodow from creationdate) as weekday, count(*)/365.0 as daily_a_mean
from posts_gis where posttypeid=2
group by extract(year from creationdate), extract(isodow from creationdate)
order by year, weekday;

drop view if exists gstats_ed_weekday;
create view gstats_ed_weekday as
select extract(year from creationdate) as year, extract(isodow from creationdate) as weekday, count(*)/365.0 as daily_e_mean
from edits_gis where posthistorytypeid in (4,5,6) and userid>-1 
group by extract(year from creationdate), extract(isodow from creationdate)
order by year, weekday;

drop table if exists gstats_weekday_overview;
create table gstats_weekday_overview as
select q.year, q.weekday, q.daily_q_mean, a.daily_a_mean, c.daily_co_mean, e.daily_e_mean
from gstats_qs_weekday q join gstats_as_weekday a on q.year=a.year and q.weekday=a.weekday
join gstats_co_weekday c on q.year=c.year and q.weekday=c.weekday 
join gstats_ed_weekday e on q.year=e.year and q.weekday=e.weekday;
															 
--- stats for q&as --- !! only qs with >0 answer(s)---
drop table if exists gstats_qa_prep;
create table gstats_qa_prep as select p1.row_id as question_id, p1.score as q_score, p1.creationdate as question_creationdate, p1.LastEditorUserId>0 as q_edited, p1.CommunityOwnedDate>'0001-01-01 00:00:00' as wiki, p2.row_Id as answerId, p2.LastEditorUserId>0 as a_edited, p1.AcceptedAnswerId, p2.score as a_score, p2.creationdate as answer_creationdate, p1.viewcount, p1.owneruserid as question_user_id, p2.owneruserid as answer_user_id
from posts_gis p1 join posts_gis p2 on p1.row_id=p2.parentId
group by p1.row_id, p1.creationdate, p1.LastEditorUserId, p1.CommunityOwnedDate, p1.AcceptedAnswerId, p1.score, p1.viewcount, p1.owneruserid, p2.row_Id, p2.creationdate, p2.LastEditorUserId, p2.owneruserid, p2.score
order by question_id, answer_creationdate;

drop view if exists gstat_qa_reaction_time;
create view gstat_qa_reaction_time as
select distinct on (question_id) 
question_id, question_creationdate, extract(epoch from answer_creationdate-question_creationdate) as reaction_time
from gstats_qa_prep;

drop table if exists gstats_qa_monthly_percentile_reaction_time;
create table gstats_qa_monthly_percentile_reaction_time as
select extract(year from question_creationdate) as year, extract(month from question_creationdate) as month, count(*), 
(percentile_disc(0.9) within group (order by reaction_time)/(3600*24.0)) as ninetyth_percentile_reaction_time_days, 
(percentile_disc(0.1) within group (order by reaction_time)/(60.0)) as tenth_percentile_reaction_time_minutes
from gstat_qa_reaction_time
group by year, month
order by year, month;
															 
drop table if exists gstats_qa_weekday_percentile_reaction_time;
create table gstats_qa_weekday_percentile_reaction_time as
select extract(year from question_creationdate) as year, extract(isodow from question_creationdate) as weekday, count(*), 
(percentile_disc(0.9) within group (order by reaction_time)/(3600*24.0)) as ninetyth_percentile_reaction_time_days, 
(percentile_disc(0.1) within group (order by reaction_time)/(60.0)) as tenth_percentile_reaction_time_minutes
from gstat_qa_reaction_time
group by year, weekday
order by year, weekday;

drop index if exists comment_posts_idx;
create index comment_posts_idx on comments_gis(PostId);
drop index if exists question_id_idex;
create index question_id_idex on gstats_qa_prep(question_id);
drop index if exists answer_id_idex;
create index answer_id_idex on gstats_qa_prep(answerid);

---the reaction time between qs and 1st comment and as and 1st comment is not representative to split chains...															 
															 
															 
---end here----															 
select posttypeid, count(*) from posts_gis where owneruserid=-1 group by posttypeid;

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

