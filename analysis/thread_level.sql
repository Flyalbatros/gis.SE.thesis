---thread level:popularity = views ---

drop view if exists thread_analysis_interaction_count_prep;
create view thread_analysis_interaction_count_prep as
select s.question_id, s.parentid, s.viewcount, s.question_creationdate, s.q_score, s.a_score, l.count as high_interaction_chains from list_splitting_all_high_interact_chains_agg l right join sampling_qora_co_prep s on l.parentid=s.question_id;

drop table if exists thread_analysis_interaction_count;
create table thread_analysis_interaction_count as
select t1.question_id, t1.high_interaction_chains, t1.viewcount, t1.viewcount/(extract(epoch from age(timestamp '2020-06-01', t1.question_creationdate))/(3600*24)) as views_per_day, sum(t2.high_interaction_chains) number_hi_chains
from thread_analysis_interaction_count_prep t1 left join thread_analysis_interaction_count_prep t2 on t1.question_id=t2.parentid 
where t1.parentid=-99 group by t1.question_id, t1.high_interaction_chains, t1.viewcount, t1.question_creationdate order by number_hi_chains desc;

update thread_analysis_interaction_count set number_hi_chains = 0 
where number_hi_chains is null;

create table thread_analysis_stats_view_per_day as
select number_hi_chains, avg(views_per_day), stddev(views_per_day), 
percentile_disc(0.1) within group (order by views_per_day) as percentile_10, percentile_disc(0.9) within group (order by views_per_day) as percentile_90 
from thread_analysis_interaction_count 
where number_hi_chains<3
group by number_hi_chains;

drop table if exists thread_analysis_stats_view_total;
create table thread_analysis_stats_view_total as
select number_hi_chains, count(*), avg(viewcount), stddev(viewcount), 
percentile_disc(0.1) within group (order by viewcount) as percentile_10, percentile_disc(0.9) within group (order by viewcount) as percentile_90 
from thread_analysis_interaction_count 
where number_hi_chains<3
group by number_hi_chains;

--- get the up/downvotes ---
create view thread_analysis_upvotes_prep as
select postid, count(*) as upvotes from votes_gis where votetypeid=2 group by postid;

create view thread_analysis_downvotes_prep as
select postid, count(*) as downvotes from votes_gis where votetypeid=3 group by postid;

drop table if exists thread_analysis_up_downvotes;
create table thread_analysis_up_downvotes as 
select t1.postid, upvotes, downvotes from thread_analysis_upvotes_prep t1 full join thread_analysis_downvotes_prep t2 on t1.postid=t2.postid;

drop table if exists thread_analysis_up_downvotes_output;
create table thread_analysis_up_downvotes_output as
select p.question_id, p.parentid, p.high_interaction_chains, v.upvotes, v.downvotes, v.upvotes+v.downvotes as total_votes, v.upvotes-v.downvotes as net_score
from thread_analysis_interaction_count_prep p left join thread_analysis_up_downvotes v on p.question_id=v.postid;

update thread_analysis_up_downvotes_output set high_interaction_chains = 0 
where high_interaction_chains is null;


create table thread_analysis_up_downvotes_output_answers as
select high_interaction_chains, count(*), avg(total_votes), stddev(total_votes), 
percentile_disc(0.1) within group (order by total_votes) as percentile_10, percentile_disc(0.9) within group (order by total_votes) as percentile_90,
avg(net_score) as avg_score, stddev(net_score) as stddev_score, 
percentile_disc(0.1) within group (order by net_score) as percentile_10_score, percentile_disc(0.9) within group (order by net_score) as percentile_90_score 
from thread_analysis_up_downvotes_output 
where parentid<>-99
group by high_interaction_chains;

create table thread_analysis_up_downvotes_output_questions as
select high_interaction_chains, count(*), avg(total_votes), stddev(total_votes), 
percentile_disc(0.1) within group (order by total_votes) as percentile_10, percentile_disc(0.9) within group (order by total_votes) as percentile_90, 
avg(net_score) as avg_score, stddev(net_score) as stddev_score, 
percentile_disc(0.1) within group (order by net_score) as percentile_10_score, percentile_disc(0.9) within group (order by net_score) as percentile_90_score 
from thread_analysis_up_downvotes_output 
where parentid=-99
group by high_interaction_chains;

---question typology: number of answers
drop table if exists thread_analysis_typology_raw;
create table thread_analysis_typology_raw as
select question_id, count(*) as answer_count from sampling_qa_co_prep where answerid is not null group by question_id;

create table thread_analysis_typology_prep as
select t.question_id, t.number_hi_chains, a.answer_count from thread_analysis_interaction_count t left join thread_analysis_typology_raw a on t.question_id=a.question_id;

create table thread_analysis_typology_out as
select number_hi_chains, avg(answer_count), stddev(answer_count), count(*) from thread_analysis_typology_prep group by number_hi_chains;

---tags

create table sampling_top_50_tags_exp as
select tagname, s.post_count from tags_gis t join sampling_top_50_tags s on t.row_id=s.row_id order by s.post_count desc;

create table thread_analysis_tags_raw as
select t.number_hi_chains, s.agg_tag_ids from thread_analysis_interaction_count t join sampling_post_tags s on t.question_id=s.post_id;

drop table if exists thread_analysis_tags_raw_top;
create table thread_analysis_tags_raw_top as
select tagname, number_hi_chains, count(*) as num_occurences from tags_gis t join thread_analysis_tags_raw r on t.row_id=any(r.agg_tag_ids) group by number_hi_chains, tagname order by number_hi_chains, num_occurences desc;

create table thread_analysis_tags_output as
select t1.tagname, t1.num_occurences as num_occurences_zero, t2.num_occurences as num_occurences_one, t1.num_occurences/162175.0 freq_occurences_zero, t2.num_occurences/10204.0 freq_occurences_one, abs((t1.num_occurences/162175.0) - (t2.num_occurences/10204.0)) as diff_frequency 
from thread_analysis_tags_raw_top t1 left join thread_analysis_tags_raw_top t2 on t1.tagname=t2.tagname
where t1.number_hi_chains=0 and t2.number_hi_chains=1 group by t1.tagname, t1.num_occurences, t2.num_occurences order by diff_frequency desc;
