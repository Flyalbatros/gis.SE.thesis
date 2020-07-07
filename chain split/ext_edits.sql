---first identify edits with rollbacks---
drop table if exists edits_rolled_back;
create table edits_rolled_back as
select * from edits_gis where revisionguid in (select * from edits_gis where posthistorytypeid=8);

---now let's keep only the edits with an impact on at least 10% of the original post---
drop table if exists edits_w_length;
create table edits_w_length with oids as
select *, length(content_text) 
from edits_gis where posthistorytypeid in (2,5,8)
and length(content_text)>0
order by postid, creationdate;
---(some cases have a length of 0 as they are tag wikis, so we delete these instances to avoid errors in the next step)

drop table if exists edits_output_10percent_rule;
create table edits_output_10percent_rule as
select e1.row_id, e1.row_id in (select row_id from edits_rolled_back) as rolled_back, e1.creationdate, e1.userid, e1.postid
from edits_w_length e1 join edits_w_length e2 on cast(e1.oid as integer)=cast(e2.oid as integer)+1 and e1.postid=e2.postid
where cast(e2.length as float)/cast(e1.length as float)>1.1 or cast(e2.length as float)/cast(e1.length as float)<0.9;

create index edits_output_10percent_time_idx on edits_output_10percent_rule(creationdate);

drop table if exists edits_chains_output_merged;
create table edits_chains_output_merged as
select l.parentid, l.high_intensity_users, l.start_date, l.end_date, l.number_comments, count(row_id) as number_edits, array_agg(row_id) as edit_id_agg, array_agg(rolled_back) as edit_rollback_agg, 'false' as rollback_presence
from list_splitting_interact_chains l left join edits_output_10percent_rule e 
on e.creationdate+interval '10minutes'>l.start_date and e.creationdate-interval '10 minutes'<l.end_date
and e.userid=any(l.high_intensity_users)
and l.parentid=e.postid
group by l.parentid, l.start_date, l.high_intensity_users, l.end_date, l.number_comments;

update edits_chains_output_merged set rollback_presence = true where edit_rollback_agg && array[true];



select * from list_splitting_interact_chains;

---get the sum of edits linked to the gg
select parentid, sum(number_edits) from edits_chains_output_merged
group by parentid;


