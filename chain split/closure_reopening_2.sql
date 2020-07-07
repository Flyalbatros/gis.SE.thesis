---620  (out of 394273) edits affected by delete accounts in 2017-2019, 4037 over entire forum existence---
select count(*) from edits_gis where extract(year from creationdate)>2016 and extract(year from creationdate)<2020;

---link to closure/reopening votes---
---10:closed ---11:reopened
---12:deleted ---13:undeleted
---14:locked ---15:unlocked
---extract number of voters possible from the content_text column (useful as not complete data???)---
drop table if exists edits_gis_w_mods;
create table edits_gis_w_mods as
select * from edits_gis e left join mod_users m on e.userid=m.mod_id;

drop table if exists spstats_closed_posts;
create table spstats_closed_posts as
select postid, array_agg(mod_id) as mod_presence, count(*), array_agg(creationdate) from edits_gis_w_mods where posthistorytypeid=10 group by postid order by count(*) desc;

drop table if exists spstats_reopened_posts;
create table spstats_reopened_posts as
select postid, array_agg(mod_id) as mod_presence, count(*), array_agg(creationdate) from edits_gis_w_mods where posthistorytypeid=11 group by postid order by count(*) desc;

drop table if exists spstats_deleted_posts;
create table spstats_deleted_posts as
select postid, count(*), array_agg(creationdate) from edits_gis where posthistorytypeid=12 group by postid order by count(*) desc;

drop table if exists spstats_undeleted_posts;
create table spstats_undeleted_posts as
select postid, count(*), array_agg(creationdate) from edits_gis where posthistorytypeid=13 group by postid order by count(*) desc;

drop table if exists spstats_locked_posts;
create table spstats_locked_posts as
select postid, count(*), array_agg(creationdate) from edits_gis where posthistorytypeid=14 group by postid order by count(*) desc;

drop table if exists spstats_unlocked_posts;
create table spstats_unlocked_posts as
select postid, count(*), array_agg(creationdate) from edits_gis where posthistorytypeid=15 group by postid order by count(*) desc;

---data fusion----

drop table if exists spstats_per_thread_closings_no_mods;
create table spstats_per_thread_closings_no_mods as
select t.question_id, t.number_hi_chains, s1.count as count_closings_no_mods
from thread_analysis_interaction_count t join spstats_closed_posts s1 on t.question_id=s1.postid
where s1.mod_presence[1] is null;

drop table if exists spstats_per_thread_reopen_no_mods;
create table spstats_per_thread_reopen_no_mods as
select t.question_id, t.number_hi_chains, s2.count as count_reopen_no_mods
from thread_analysis_interaction_count t join spstats_reopened_posts s2 on t.question_id=s2.postid
where s2.mod_presence[1] is null;

drop table if exists spstats_per_thread_closings_mods;
create table spstats_per_thread_closings_mods as
select t.question_id, t.number_hi_chains, s1.count as count_closings_mods
from thread_analysis_interaction_count t join spstats_closed_posts s1 on t.question_id=s1.postid
where s1.mod_presence[1] is not null;

drop table if exists spstats_per_thread_reopen_mods;
create table spstats_per_thread_reopen_mods as
select t.question_id, t.number_hi_chains, s2.count as count_reopen_mods
from thread_analysis_interaction_count t join spstats_reopened_posts s2 on t.question_id=s2.postid
where s2.mod_presence[1] is not null;

drop table if exists spstats_per_thread;
create table spstats_per_thread as
select t.question_id, t.number_hi_chains, count_closings_no_mods, count_closings_mods, count_reopen_no_mods, count_reopen_mods 
from thread_analysis_interaction_count t left join spstats_per_thread_closings_no_mods s1 on t.question_id=s1.question_id 
left join spstats_per_thread_reopen_no_mods s2 on t.question_id=s2.question_id
left join spstats_per_thread_closings_mods s3 on t.question_id=s3.question_id
left join spstats_per_thread_reopen_mods s4 on t.question_id=s4.question_id;

update spstats_per_thread set count_closings_no_mods=0 where count_closings_no_mods is null;
update spstats_per_thread set count_closings_mods=0 where count_closings_mods is null;
update spstats_per_thread set count_reopen_no_mods=0 where count_reopen_no_mods is null;
update spstats_per_thread set count_reopen_mods=0 where count_reopen_mods is null;
---output---
create table spstats_output as
select number_hi_chains, count(*), sum(count_closings_mods)/count(*) as mods_closings, sum(count_closings_no_mods)/count(*) as frequency_no_mods_closings,
sum(count_reopen_mods)/count(*) as mods_reopen, sum(count_reopen_no_mods)/count(*) as no_mods_reopen
from spstats_per_thread where number_hi_chains<3 group by number_hi_chains; 

select number_hi_chains, count(*), sum(count_closings_mods) as mods_closings, sum(count_closings_no_mods) as frequency_no_mods_closings,
sum(count_reopen_mods) as mods_reopen, sum(count_reopen_no_mods) as no_mods_reopen
from spstats_per_thread where number_hi_chains<3 group by number_hi_chains; 

select * from spstats_output_old where number_hi_chains<2;

select count(*) from thread_analysis_interaction_count;
select question_id, count(*) from spstats_per_thread group by question_id order by count desc;
select * from spstats_reopened_posts where postid=229397;
spstats_per_thread
