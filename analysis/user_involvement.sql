select count(*), sum(number_comments) from list_splitting_interact_chains l where l.count_users_two_comments>1 and extract(year from l.start_date)<2020 and extract(year from l.end_date)>2016;
---7955 eligible chains, 53253 comments---
select count(*) from comments_gis where extract(year from creationdate)<2020 and extract(year from creationdate)>2016;
---146367 comments---

select count(*) from chain_level_stats_a; ---2951
select count(*) from chain_level_stats_q; ---5004
select sum(number_edits) from chain_level_stats_a; ---1227
select sum(number_edits) from chain_level_stats_q; ---2325
select count(*) from edits_output_10percent_rule where extract(year from creationdate)<2020 and extract(year from creationdate)>2016; ---28883

---users---
drop table if exists chain_level_stats_q;
create table chain_level_stats_q as 
select l.*, p.owneruserid=any(high_intensity_users) as author_present, p.score, p.viewcount,
array_agg(m.mod_id) mod_array, false as mod_presence,
count(e.row_id) as number_edits, array_agg(e.userid) as edit_user_array, false as edit_mod_presence
from list_splitting_interact_chains l join posts_gis p on l.parentid=p.row_id 
left join mod_users m on m.mod_id=any(high_intensity_users)
left join edits_output_10percent_rule e 
on e.creationdate+interval '10minutes'>l.start_date and e.creationdate-interval '10 minutes'<l.end_date
and e.userid=any(l.high_intensity_users)
and l.parentid=e.postid
where l.count_users_two_comments>1 and p.parentid=-99 and extract(year from start_date)<2020 and extract(year from end_date)>2016
group by l.parentid, l.chain_oid, l.start_date, l.end_date, l.word_sum, l.number_comments, l.count_users_two_comments, l.high_intensity_users, p.owneruserid, p.viewcount, p.score;

update chain_level_stats_q set mod_presence = mod_array[1] is not null;
update chain_level_stats_q set edit_mod_presence = true where edit_user_array && (select array_agg(mod_id) from mod_users);

---answers
drop table if exists chain_level_stats_a;
create table chain_level_stats_a as 
select l.*, p.owneruserid=any(high_intensity_users) as author_present, p2.owneruserid=any(high_intensity_users) as q_author_present, 
p.score, p2.viewcount, array_agg(m.mod_id) mod_array, false as mod_presence,
count(e.row_id) as number_edits, array_agg(e.userid) as edit_user_array, false as edit_mod_presence
from list_splitting_interact_chains l join posts_gis p on l.parentid=p.row_id 
join posts_gis p2 on p.parentid=p2.row_id
left join mod_users m on m.mod_id=any(high_intensity_users)
left join edits_output_10percent_rule e 
on e.creationdate+interval '10minutes'>l.start_date and e.creationdate-interval '10 minutes'<l.end_date
and e.userid=any(l.high_intensity_users)
and l.parentid=e.postid
where l.count_users_two_comments>1 and p.parentid<>-99 and extract(year from start_date)<2020 and extract(year from end_date)>2016
group by l.parentid, l.chain_oid, l.start_date, l.end_date, l.word_sum, l.number_comments, l.count_users_two_comments, l.high_intensity_users, p.owneruserid, p2.owneruserid, p2.viewcount, p.score;

update chain_level_stats_a set mod_presence = true where mod_array[1] is not null;
update chain_level_stats_a set edit_mod_presence = true where edit_user_array && (select array_agg(mod_id) from mod_users);
---analysis

select count(*) from chain_level_stats_a where author_present is true; ---2837
select count(*) from chain_level_stats_a where author_present is true and q_author_present is true; ---2512
select count(*) from chain_level_stats_a; ---2951

select count(*) from chain_level_stats_q where author_present is true; ---4831
select count(*) from chain_level_stats_q; ---5004



---types of users
create table chain_level_user_profiles as 
select l.chain_oid, u.row_id as user_id, l.start_date, u.creationdate, extract(epoch from age(l.start_date, u.creationdate))/(3600*24*365) as years_since_registration,
count(q.row_id) as question_count, count(a.row_id) as answer_count, count(c.row_id) as comment_count, count(e.row_id) as edits_count
from list_splitting_interact_chains l 
join users_gis u on u.row_id=any(l.high_intensity_users)
left join posts_gis q on q.owneruserid=u.row_id and q.creationdate<l.start_date
left join posts_gis a on a.owneruserid=u.row_id and a.creationdate<l.start_date
left join comments_gis c on c.userid=u.row_id and c.creationdate<l.start_date
left join edits_gis e on e.userid=u.row_id and e.creationdate<l.start_date
where l.count_users_two_comments>1 and extract(year from l.start_date)<2020 and extract(year from l.end_date)>2016 and
q.posttypeid=1 and a.posttypeid=2
group by l.chain_oid, user_id, l.start_date, u.creationdate, years_since_registration;

drop view if exists chain_level_user_profiles_1 cascade;																							  																							  
create view chain_level_user_profiles_1 as 
select l.chain_oid, u.row_id as user_id, l.start_date, u.creationdate, extract(epoch from age(l.start_date, u.creationdate))/(3600*24*365) as years_since_registration,
count(q.row_id) as question_count
from list_splitting_interact_chains l 
join users_gis u on u.row_id=any(l.high_intensity_users)
left join posts_gis q on q.owneruserid=u.row_id and q.creationdate<l.start_date
where l.count_users_two_comments>1 and extract(year from l.start_date)<2020 and extract(year from l.end_date)>2016 and
q.posttypeid=1
group by l.chain_oid, user_id, l.start_date, u.creationdate, years_since_registration;

drop view if exists chain_level_user_profiles_2 cascade;																							  
create view chain_level_user_profiles_2 as 
select l.*, count(a.row_id) as answer_count from chain_level_user_profiles_1 l
left join posts_gis a on a.owneruserid=l.user_id and a.creationdate<l.start_date
where a.posttypeid=2
group by l.chain_oid, l.question_count, user_id, l.start_date, l.creationdate, years_since_registration, question_count;

drop view if exists chain_level_user_profiles_3 cascade;																							  																							  
create view chain_level_user_profiles_3 as 
select l.*, count(c.row_id) as comment_count from chain_level_user_profiles_2 l
left join comments_gis c on c.userid=l.user_id and c.creationdate<l.start_date
group by l.chain_oid, l.question_count, l.answer_count, user_id, l.start_date, l.creationdate, years_since_registration, question_count;

drop table if exists chain_level_user_profiles;
create table chain_level_user_profiles as 
select l.*, count(e.row_id) as edits_count from chain_level_user_profiles_3 l
left join edits_gis e on e.userid=l.user_id and e.creationdate<l.start_date
group by l.chain_oid, l.question_count, l.answer_count, l.comment_count, user_id, l.start_date, l.creationdate, years_since_registration, question_count;
																							  
drop table if exists chain_level_user_outputs;
create table chain_level_user_outputs as
select chain_oid, user_id, 
question_count>answer_count and question_count>comment_count and question_count>edits_count as mainly_questions,
answer_count>comment_count and answer_count>edits_count and answer_count>answer_count as mainly_answers,
comment_count>answer_count and comment_count>question_count and comment_count>edits_count  as mainly_comments,
edits_count>answer_count and edits_count>question_count and edits_count>comment_count as mainly_edits,
question_count>answer_count as question_more_answer,
comment_count<edits_count as comment_more_edits																							  
from chain_level_user_profiles;

---output---
select mainly_comments, mainly_edits, mainly_answers, mainly_questions, count(*)/10089.0 as frequency 
from chain_level_user_outputs group by mainly_comments, mainly_edits, mainly_answers, mainly_questions;

select question_more_answer, count(*)/10089.0 as frequency 
from chain_level_user_outputs group by question_more_answer;
																							  
select comment_more_edits, count(*)/10089.0 as frequency 
from chain_level_user_outputs group by comment_more_edits;
													  
																							  