---620  (out of 394273) edits affected by delete accounts in 2017-2019, 4037 over entire forum existence---
select count(*) from edits_gis where extract(year from creationdate)>2016 and extract(year from creationdate)<2020;

---link to closure/reopening votes---
---10:closed ---11:reopened
---12:deleted ---13:undeleted
---14:locked ---15:unlocked
---extract number of voters possible from the content_text column (useful as not complete data???)---
drop table if exists spstats_closed_posts;
create table spstats_closed_posts as
select postid, count(*), array_agg(creationdate) from edits_gis where posthistorytypeid=10 group by postid order by count(*) desc;

drop table if exists spstats_reopened_posts;
create table spstats_reopened_posts as
select postid, count(*), array_agg(creationdate) from edits_gis where posthistorytypeid=11 group by postid order by count(*) desc;

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

drop table if exists spstats_per_thread;
create table spstats_per_thread as
select t.question_id, t.number_hi_chains, s1.count as count_closings, s2.count as count_reopen, s3.count as count_delete, s4.count as count_locked
from thread_analysis_interaction_count t left join spstats_closed_posts s1 on t.question_id=s1.postid
left join spstats_reopenened_posts s2 on t.question_id=s2.postid
left join spstats_deleted_posts s3 on t.question_id=s3.postid
left join spstats_locked_posts s4 on t.question_id=s4.postid;

create table spstats_output as
select number_hi_chains, count(*), sum(count_closings)/count(*) as frequency_closings, sum(count_reopen)/count(*) as frequency_reopen, sum(count_delete)/count(*) as frequency_delete, sum(count_locked)/count(*) as frequency_locked from spstats_per_thread where number_hi_chains<3 group by number_hi_chains; 




