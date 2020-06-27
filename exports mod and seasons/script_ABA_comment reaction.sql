drop table if exists comment_ABA_reaction_prep;
create table comment_ABA_reaction_prep with OIDS as
select postid, creationdate, userid, 99 as type, row_id as comment_row_id
from comments_gis
union
select row_id, creationdate, owneruserid, posttypeid, -99
from posts_gis
order by postid, creationdate;
create index time_diff_index on comment_ABA_reaction_prep(postid, creationdate);

drop table if exists comment_ABA_reaction_ids;
create table comment_ABA_reaction_ids as 
select p1.comment_row_id as cur_row_id, p2.comment_row_id as next_row_id
from comment_ABA_reaction_prep p1 join comment_ABA_reaction_prep p2 
on cast(p1.OID as integer)=cast(p2.OID as integer)-1 and p1.postid=p2.postid 
join comment_ABA_reaction_prep p3 
on cast(p1.OID as integer)=cast(p3.OID as integer)+1 and p1.postid=p3.postid
and p2.userid=p3.userid and p2.userid<>p1.userid
where p1.postid!='-99' 
order by p1.OID;

---calculate overlap---
select count(*)/22941.0 from comment_ABA_reaction_ids where cur_row_id>0 and cur_row_id in (select * from comment_handle_reaction_ids_direct) and cur_row_id in (select * from comment_handle_reaction_ids_direct_2);
select count(*)/124863.0 from comment_ABA_reaction_ids where next_row_id>0 and next_row_id in (select * from comment_handle_reaction_ids_direct) and next_row_id in (select * from comment_handle_reaction_ids_direct_2);
select count(*) from comment_ABA_reaction_ids where next_row_id in (select * from comment_ABA_handle_reaction_overlap_ids_cur) and next_row_id>0 and next_row_id not in (select * from comment_handle_reaction_ids_direct) and next_row_id not in (select * from comment_handle_reaction_ids_direct_2);
---total: 124863 entries in table (22941 in handle table) of which
---1084 cur_row_ids overlap with handle analysis(0.8%/4.7%)---
---20 next_row_ids overlap with handle analysis(.02%/.08%)---
---0 both row_ids overlap with handle analysis---
create view comment_ABA_handle_reaction_overlap_ids_cur as
select cur_row_id from comment_ABA_reaction_ids where cur_row_id>0 and cur_row_id in (select * from comment_handle_reaction_ids_direct) and cur_row_id in (select * from comment_handle_reaction_ids_direct_2);

drop table if exists comment_ABA_reaction_time;
create table comment_ABA_reaction_time as 
select extract(epoch from p2.creationdate-p1.creationdate) as time_diff_next, extract(epoch from p1.creationdate-p3.creationdate) as time_diff_prev, p1.creationdate
from comment_ABA_reaction_prep p1 join comment_ABA_reaction_prep p2 
on cast(p1.OID as integer)=cast(p2.OID as integer)-1 and p1.postid=p2.postid 
join comment_ABA_reaction_prep p3 
on cast(p1.OID as integer)=cast(p3.OID as integer)+1 and p1.postid=p3.postid
and p2.userid=p3.userid and p2.userid<>p1.userid
where p1.postid!='-99' 
order by p1.OID;

drop table if exists gstats_co_ABA_monthly_percentile_reaction_time;
create table gstats_co_ABA_monthly_percentile_reaction_time as
select extract(year from creationdate) as year, extract(month from creationdate) as month, count(*), 
(percentile_disc(0.9) within group (order by time_diff_next)/(3600*24.0)) as next_ninetyth_percentile_reaction_time_days, 
(percentile_disc(0.1) within group (order by time_diff_next)/(60.0)) as next_tenth_percentile_reaction_time_minutes,
(percentile_disc(0.9) within group (order by time_diff_prev)/(3600*24.0)) as prev_ninetyth_percentile_reaction_time_days, 
(percentile_disc(0.1) within group (order by time_diff_prev)/(60.0)) as prev_tenth_percentile_reaction_time_minutes
from comment_ABA_reaction_time
group by year, month
order by year, month;
															 
drop table if exists gstats_co_ABA_weekday_percentile_reaction_time;
create table gstats_co_ABA_weekday_percentile_reaction_time as
select extract(year from creationdate) as year, extract(isodow from creationdate) as weekday, count(*), 
(percentile_disc(0.9) within group (order by time_diff_next)/(3600*24.0)) as next_ninetyth_percentile_reaction_time_days, 
(percentile_disc(0.1) within group (order by time_diff_next)/(60.0)) as next_tenth_percentile_reaction_time_minutes,
(percentile_disc(0.9) within group (order by time_diff_prev)/(3600*24.0)) as prev_ninetyth_percentile_reaction_time_days, 
(percentile_disc(0.1) within group (order by time_diff_prev)/(60.0)) as prev_tenth_percentile_reaction_time_minutes
from comment_ABA_reaction_time
group by year, weekday
order by year, weekday;

drop index if exists comment_posts_idx;
create index comment_posts_idx on comments_gis(PostId);
drop index if exists question_id_idex;
create index question_id_idex on gstats_qa_prep(question_id);
drop index if exists answer_id_idex;
create index answer_id_idex on gstats_qa_prep(answerid);

---results---
select count(*) from comment_ABA_reaction_time where extract(year from creationdate)>2016 and extract(year from creationdate)<2020; ---124863--- 46434
select cast(count(*) as float)/46434 from comment_ABA_reaction_time where time_diff_next<72*3600 and extract(year from creationdate)>2016 and extract(year from creationdate)<2020; ---66507--- 95.6% ---95.8%
select cast(count(*) as float)/46434 from comment_ABA_reaction_time where time_diff_prev<72*3600 and extract(year from creationdate)>2016 and extract(year from creationdate)<2020; ---68007--- 94.6% ---94.2%

select cast(count(*) as float)/46434 from comment_ABA_reaction_time where time_diff_next<48*3600 and extract(year from creationdate)>2016 and extract(year from creationdate)<2020; ---66507--- 93.7% ---93.8%
select cast(count(*) as float)/46434 from comment_ABA_reaction_time where time_diff_prev<48*3600 and extract(year from creationdate)>2016 and extract(year from creationdate)<2020; ---68007--- 92.9%v ---92.5

select cast(count(*) as float)/46434 from comment_ABA_reaction_time where time_diff_next<168*3600 and extract(year from creationdate)>2016 and extract(year from creationdate)<2020; ---98.1%
select cast(count(*) as float)/46434 from comment_ABA_reaction_time where time_diff_prev<168*3600 and extract(year from creationdate)>2016 and extract(year from creationdate)<2020; ---96.4%

select cast(count(*) as float)/46434 from comment_ABA_reaction_time where time_diff_next<336*3600 and extract(year from creationdate)>2016 and extract(year from creationdate)<2020; ---99.0%
select cast(count(*) as float)/46434 from comment_ABA_reaction_time where time_diff_prev<336*3600 and extract(year from creationdate)>2016 and extract(year from creationdate)<2020; ---97.2%
												  								  
select cast(count(*) as float)/46434 from comment_ABA_reaction_time where time_diff_next<24*3600; ---66507--- 89.3%
select cast(count(*) as float)/46434 from comment_ABA_reaction_time where time_diff_prev<24*3600; ---68007--- 89.3%

select cast(count(*) as float)/46434 from comment_ABA_reaction_time where time_diff_next<4*3600; ---53420--- 69.6%
select cast(count(*) as float)/46434 from comment_ABA_reaction_time where time_diff_prev<4*3600; ---55570--- 70.6%



