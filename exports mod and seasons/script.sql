--- questions ---
--- by year ---
drop view if exists gstats_qs_mod_by_year;
create view gstats_qs_mod_by_year as 
select extract(year from creationdate)as year , count(*) from posts_gis where posttypeid=1 and owneruserid in 
(select mod_id from mod_users) group by extract(year from creationdate) order by year; 
drop view if exists gstats_qs_all_by_year;
create view gstats_qs_all_by_year as
select extract(year from creationdate)as year , count(*) from posts_gis where posttypeid=1 
group by extract(year from creationdate) order by year;
drop view if exists gstats_qs_mod_share_by_year;
create view gstats_qs_mod_share_by_year as 
select qa.year, qa.count as count_all, qm.count as count_mods, cast(qm.count as float)/cast(qa.count as float) as mod_q_share 
from gstats_qs_all_by_year qa 
join gstats_qs_mod_by_year qm on qa.year=qm.year;

---by month for the years 2017 and 2019---
drop view if exists gstats_qs_mod_by_month_2019;
create view gstats_qs_mod_by_month_2019 as 
select extract(month from creationdate)as month , count(*) from posts_gis where posttypeid=1 and owneruserid in 
(select mod_id from mod_users) and extract(year from creationdate)=2019 group by extract(month from creationdate) order by month;

drop view if exists gstats_qs_all_by_month_2019;
create view gstats_qs_all_by_month_2019 as 
select extract(month from creationdate)as month , count(*) as count_2019 from posts_gis where posttypeid=1
and extract(year from creationdate)=2019 group by extract(month from creationdate) order by month;

drop view if exists gstats_qs_all_by_month_2017;
create view gstats_qs_all_by_month_2017 as 
select extract(month from creationdate)as month , count(*) as count_2017 from posts_gis where posttypeid=1
and extract(year from creationdate)=2017 group by extract(month from creationdate) order by month;

drop table if exists gstats_qs_all_by_month_1719;
create table gstats_qs_all_by_month_1719 as 
select qa.month, qa.count_2017, qm.count_2019, cast (qm.count_2019 as float)/qa.count_2017 as ratio_increase
from gstats_qs_all_by_month_2017 qa 
join gstats_qs_all_by_month_2019 qm on qa.month=qm.month;

---by month & year for 2017-2019---
drop view if exists gstats_qs_mod_by_monthyear;
create view gstats_qs_mod_by_monthyear as 
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from posts_gis
where posttypeid=1 and owneruserid in (select mod_id from mod_users) and extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

drop view if exists gstats_qs_all_by_monthyear;
create view gstats_qs_all_by_monthyear as 
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from posts_gis
where posttypeid=1 and extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

drop table if exists gstats_qs_share_by_monthyear;
create table gstats_qs_share_by_monthyear as 
select mo.year, mo.month, al.count as count_all, mo.count as count_mods, cast(mo.count as float)/cast(al.count as float) as mod_co_share 
from gstats_qs_mod_by_monthyear mo 
join gstats_qs_all_by_monthyear al on mo.year=al.year and mo.month=al.month
order by mo.year, mo.month;
--- extra: qs_wo_answers --- 
drop table if exists gstats_qs_no_answer;
create table gstats_qs_no_answer as
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from posts_gis
where posttypeid=1 and answercount=0 and extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

--- extra: qs_no_answers_nor_comments --- 
drop table if exists gstats_qs_no_answercomment;
create table gstats_qs_no_answercomment as
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from posts_gis
where posttypeid=1 and answercount=0 and commentcount=0 and extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

--- answers ---
--- by year ---
drop view if exists gstats_as_mod_by_year;
create view gstats_as_mod_by_year as 
select extract(year from creationdate)as year , count(*) from posts_gis where posttypeid=2 and owneruserid in 
(select mod_id from mod_users) group by extract(year from creationdate) order by year; 
drop view if exists gstats_as_all_by_year;
create view gstats_as_all_by_year as
select extract(year from creationdate)as year , count(*) from posts_gis where posttypeid=2 
group by extract(year from creationdate) order by year;
drop view if exists gstats_as_mod_share_by_year;
create view gstats_as_mod_share_by_year as 
select aa.year, aa.count as count_all, am.count as count_mods, cast(am.count as float)/cast(aa.count as float) as mod_a_share 
from gstats_as_all_by_year aa 
join gstats_as_mod_by_year am on aa.year=am.year 
order by aa.year;

---by month for the years 2017 and 2019---
drop view if exists gstats_as_mod_by_month_2019;
create view gstats_as_mod_by_month_2019 as 
select extract(month from creationdate)as month , count(*) from posts_gis where posttypeid=2 and owneruserid in 
(select mod_id from mod_users) and extract(year from creationdate)=2019 group by extract(month from creationdate) order by month;

drop view if exists gstats_as_all_by_month_2019;
create view gstats_as_all_by_month_2019 as 
select extract(month from creationdate)as month , count(*) as count_2019 from posts_gis where posttypeid=2
and extract(year from creationdate)=2019 group by extract(month from creationdate) order by month;

drop view if exists gstats_as_all_by_month_2017;
create view gstats_as_all_by_month_2017 as 
select extract(month from creationdate)as month , count(*) as count_2017 from posts_gis where posttypeid=2
and extract(year from creationdate)=2017 group by extract(month from creationdate) order by month;

drop table if exists gstats_as_all_by_month_1719;
create table gstats_as_all_by_month_1719 as 
select qa.month, qa.count_2017, qm.count_2019, cast (qm.count_2019 as float)/qa.count_2017 as ratio_increase
from gstats_qs_all_by_month_2017 qa 
join gstats_qs_all_by_month_2019 qm on qa.month=qm.month;

---by month & year for 2017-2019---
drop view if exists gstats_as_mod_by_monthyear;
create view gstats_as_mod_by_monthyear as 
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from posts_gis
where posttypeid=2 and owneruserid in (select mod_id from mod_users) and extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

drop view if exists gstats_as_all_by_monthyear;
create view gstats_as_all_by_monthyear as 
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from posts_gis
where posttypeid=2 and extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

drop table if exists gstats_as_share_by_monthyear;
create table gstats_as_share_by_monthyear as 
select mo.year, mo.month, al.count as count_all, mo.count as count_mods, cast(mo.count as float)/cast(al.count as float) as mod_co_share 
from gstats_as_mod_by_monthyear mo 
join gstats_as_all_by_monthyear al on mo.year=al.year and mo.month=al.month
order by mo.year, mo.month;

---edits---
--- by year ---
drop view if exists gstats_ed_mod_by_year cascade;
create view gstats_ed_mod_by_year as 
select extract(year from creationdate)as year , count(*) from edits_gis where posthistorytypeid in (4,5,6) and userid in 
(select mod_id from mod_users) group by extract(year from creationdate) order by year;
drop view if exists gstats_ed_all_by_year;
create view gstats_ed_all_by_year as 
select extract(year from creationdate)as year , count(*) from edits_gis where posthistorytypeid in (4,5,6) and userid>-1 
group by extract(year from creationdate) order by year;
drop view if exists gstats_ed_mod_share_by_year;
create view gstats_ed_mod_share_by_year as 
select ea.year, ea.count as count_all, em.count as count_mods, cast(em.count as float)/cast(ea.count as float) as mod_e_share 
from gstats_ed_all_by_year ea 
join gstats_ed_mod_by_year em on ea.year=em.year 
order by ea.year;

---by month for the years 2017 and 2019---
drop view if exists gstats_ed_mod_by_month_2019;
create view gstats_ed_mod_by_month_2019 as 
select extract(month from creationdate)as month , count(*) as count_2019 from edits_gis where posthistorytypeid in (4,5,6) and userid in 
(select mod_id from mod_users) and extract(year from creationdate)=2019 group by extract(month from creationdate) order by month;

drop view if exists gstats_ed_mod_by_month_2017;
create view gstats_ed_mod_by_month_2017 as 
select extract(month from creationdate)as month , count(*) as count_2017 from edits_gis where posthistorytypeid in (4,5,6) and userid in 
(select mod_id from mod_users) and extract(year from creationdate)=2017 group by extract(month from creationdate) order by month;

drop view if exists gstats_ed_all_by_month_2019;
create view gstats_ed_all_by_month_2019 as 
select extract(month from creationdate)as month , count(*) as count_2019 from edits_gis where posthistorytypeid in (4,5,6) and userid>-1
and extract(year from creationdate)=2019 group by extract(month from creationdate) order by month;

drop view if exists gstats_ed_all_by_month_2017;
create view gstats_ed_all_by_month_2017 as 
select extract(month from creationdate)as month , count(*) as count_2017 from edits_gis where posthistorytypeid in (4,5,6) and userid>-1
and extract(year from creationdate)=2017 group by extract(month from creationdate) order by month;

drop table if exists gstats_ed_all_by_month_1719;
create table gstats_ed_all_by_month_1719 as 
select qa.month, qa.count_2017, q7.count_2017 as mod_count_2017, qm.count_2019, q9.count_2019 as mod_count_2019,
cast (qm.count_2019 as float)/qa.count_2017 as ratio_increase_total,
cast (q7.count_2017 as float)/qa.count_2017 as mod_share_2017,
cast (q9.count_2019 as float)/qm.count_2019 as mod_share_2019
from gstats_ed_all_by_month_2017 qa 
join gstats_ed_all_by_month_2019 qm on qa.month=qm.month
join gstats_ed_mod_by_month_2017 q7 on qa.month=q7.month
join gstats_ed_mod_by_month_2019 q9 on qa.month=q9.month;

---by month & year for 2017-2019---
drop view if exists gstats_ed_mod_by_monthyear;
create view gstats_ed_mod_by_monthyear as 
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from  edits_gis 
where posthistorytypeid in (4,5,6) and userid in (select mod_id from mod_users) and extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

drop view if exists gstats_ed_all_by_monthyear;
create view gstats_ed_all_by_monthyear as 
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from  edits_gis 
where posthistorytypeid in (4,5,6) and userid<>-1 and extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

drop table if exists gstats_ed_share_by_monthyear;
create table gstats_ed_share_by_monthyear as 
select mo.year, mo.month, al.count as count_all, mo.count as count_mods, cast(mo.count as float)/cast(al.count as float) as mod_co_share 
from gstats_ed_mod_by_monthyear mo 
join gstats_ed_all_by_monthyear al on mo.year=al.year and mo.month=al.month
order by mo.year, mo.month;

---comments---
--- by year ---
drop view if exists gstats_co_mod_by_year;
create view gstats_co_mod_by_year as 
select extract(year from creationdate)as year , count(*) from comments_gis where userid in 
(select mod_id from mod_users) group by extract(year from creationdate) order by year;
drop view if exists gstats_co_all_by_year;
create view gstats_co_all_by_year as 
select extract(year from creationdate)as year , count(*) from comments_gis group by extract(year from creationdate) order by year;
drop view if exists gstats_co_mod_share_by_year;
create view gstats_co_mod_share_by_year as 
select ea.year, ea.count as count_all, em.count as count_mods, cast(em.count as float)/cast(ea.count as float) as mod_c_share 
from gstats_co_all_by_year ea 
join gstats_co_mod_by_year em on ea.year=em.year 
order by ea.year;

---by month for the years 2017 and 2019---
drop view if exists gstats_co_mod_by_month_2019;
create view gstats_co_mod_by_month_2019 as 
select extract(month from creationdate)as month , count(*) as count_2019 from comments_gis where userid in 
(select mod_id from mod_users) and extract(year from creationdate)=2019 group by extract(month from creationdate) order by month;

drop view if exists gstats_co_mod_by_month_2017;
create view gstats_co_mod_by_month_2017 as 
select extract(month from creationdate)as month , count(*) as count_2017 from comments_gis where userid in 
(select mod_id from mod_users) and extract(year from creationdate)=2017 group by extract(month from creationdate) order by month;

drop view if exists gstats_co_all_by_month_2019;
create view gstats_co_all_by_month_2019 as 
select extract(month from creationdate)as month , count(*) as count_2019 from comments_gis where 
extract(year from creationdate)=2019 group by extract(month from creationdate) order by month;

drop view if exists gstats_co_all_by_month_2017;
create view gstats_co_all_by_month_2017 as 
select extract(month from creationdate)as month , count(*) as count_2017 from comments_gis where 
extract(year from creationdate)=2017 group by extract(month from creationdate) order by month;

drop table if exists gstats_co_all_by_month_1719;
create table gstats_co_all_by_month_1719 as 
select qa.month, qa.count_2017, q7.count_2017 as mod_count_2017, qm.count_2019, q9.count_2019 as mod_count_2019,
cast (qm.count_2019 as float)/qa.count_2017 as ratio_increase_total,
cast (q7.count_2017 as float)/qa.count_2017 as mod_share_2017,
cast (q9.count_2019 as float)/qm.count_2019 as mod_share_2019
from gstats_co_all_by_month_2017 qa 
join gstats_co_all_by_month_2019 qm on qa.month=qm.month
join gstats_co_mod_by_month_2017 q7 on qa.month=q7.month
join gstats_co_mod_by_month_2019 q9 on qa.month=q9.month;

---by month & year for 2017-2019---
drop view if exists gstats_co_mod_by_monthyear;
create view gstats_co_mod_by_monthyear as 
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from comments_gis where userid in 
(select mod_id from mod_users) and extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

drop view if exists gstats_co_all_by_monthyear;
create view gstats_co_all_by_monthyear as 
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from comments_gis 
where extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

drop table if exists gstats_co_share_by_monthyear;
create table gstats_co_share_by_monthyear as 
select mo.year, mo.month, al.count as count_all, mo.count as count_mods, cast(mo.count as float)/cast(al.count as float) as mod_co_share 
from gstats_co_mod_by_monthyear mo 
join gstats_co_all_by_monthyear al on mo.year=al.year and mo.month=al.month
order by mo.year, mo.month;


---votes ---
--- by year ---
drop view if exists gstats_vo_mod_by_year;
create view gstats_vo_mod_by_year as 
select extract(year from creationdate)as year , count(*) from votes_gis where userid in 
(select mod_id from mod_users) group by extract(year from creationdate) order by year;
drop view if exists gstats_vo_all_by_year;
create view gstats_vo_all_by_year as 
select extract(year from creationdate)as year , count(*) from votes_gis group by extract(year from creationdate) order by year;
drop view if exists gstats_vo_mod_share_by_year;
create view gstats_vo_mod_share_by_year as 
select ea.year, ea.count as count_all, em.count as count_mods, cast(em.count as float)/cast(ea.count as float) as mod_v_share 
from gstats_vo_all_by_year ea 
join gstats_vo_mod_by_year em on ea.year=em.year 
order by ea.year;

---by month for the years 2017 and 2019---
drop view if exists gstats_vo_mod_by_month_2019;
create view gstats_vo_mod_by_month_2019 as 
select extract(month from creationdate)as month , count(*) as count_2019 from votes_gis where userid in 
(select mod_id from mod_users) and extract(year from creationdate)=2019 group by extract(month from creationdate) order by month;

drop view if exists gstats_vo_mod_by_month_2017;
create view gstats_vo_mod_by_month_2017 as 
select extract(month from creationdate)as month , count(*) as count_2017 from votes_gis where userid in 
(select mod_id from mod_users) and extract(year from creationdate)=2017 group by extract(month from creationdate) order by month;

drop view if exists gstats_vo_all_by_month_2019;
create view gstats_vo_all_by_month_2019 as 
select extract(month from creationdate)as month , count(*) as count_2019 from votes_gis where 
extract(year from creationdate)=2019 group by extract(month from creationdate) order by month;

drop view if exists gstats_vo_all_by_month_2017;
create view gstats_vo_all_by_month_2017 as 
select extract(month from creationdate)as month , count(*) as count_2017 from votes_gis where 
extract(year from creationdate)=2017 group by extract(month from creationdate) order by month;

drop table if exists gstats_vo_all_by_month_1719;
create table gstats_vo_all_by_month_1719 as 
select qa.month, qa.count_2017, q7.count_2017 as mod_count_2017, qm.count_2019, q9.count_2019 as mod_count_2019,
cast (qm.count_2019 as float)/qa.count_2017 as ratio_increase_total,
cast (q7.count_2017 as float)/qa.count_2017 as mod_share_2017,
cast (q9.count_2019 as float)/qm.count_2019 as mod_share_2019
from gstats_vo_all_by_month_2017 qa 
join gstats_vo_all_by_month_2019 qm on qa.month=qm.month
join gstats_vo_mod_by_month_2017 q7 on qa.month=q7.month
join gstats_vo_mod_by_month_2019 q9 on qa.month=q9.month;

---by month & year for 2017-2019---
drop view if exists gstats_vo_mod_by_monthyear;
create view gstats_vo_mod_by_monthyear as 
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from votes_gis where userid in 
(select mod_id from mod_users) and extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

drop view if exists gstats_vo_all_by_monthyear;
create view gstats_vo_all_by_monthyear as 
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from votes_gis 
where extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

drop table if exists gstats_vo_share_by_monthyear;
create table gstats_vo_share_by_monthyear as 
select mo.year, mo.month, al.count as count_all, mo.count as count_mods, cast(mo.count as float)/cast(al.count as float) as mod_co_share 
from gstats_vo_mod_by_monthyear mo 
join gstats_vo_all_by_monthyear al on mo.year=al.year and mo.month=al.month
order by mo.year, mo.month;

---close/delete/undo votes---
--- by year ---
drop view if exists gstats_cl_mod_by_year cascade;
create view gstats_cl_mod_by_year as 
select extract(year from creationdate)as year , count(*) from edits_gis where posthistorytypeid in (10,11,12,13) and userid in 
(select mod_id from mod_users) group by extract(year from creationdate) order by year;
drop view if exists gstats_cl_all_by_year;
create view gstats_cl_all_by_year as 
select extract(year from creationdate)as year , count(*) from edits_gis where posthistorytypeid in (10,11,12,13) and userid>-1
group by extract(year from creationdate) order by year;
drop view if exists gstats_cl_mod_share_by_year;
create view gstats_cl_mod_share_by_year as 
select ea.year, ea.count as count_all, em.count as count_mods, cast(em.count as float)/cast(ea.count as float) as mod_cl_share 
from gstats_cl_all_by_year ea 
join gstats_cl_mod_by_year em on ea.year=em.year 
order by ea.year;

---by month & year for 2017-2019---
drop view if exists gstats_cl_mod_by_monthyear;
create view gstats_cl_mod_by_monthyear as 
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from  edits_gis 
where posthistorytypeid in (10,11,12,13) and userid in (select mod_id from mod_users) and extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

drop view if exists gstats_cl_all_by_monthyear;
create view gstats_cl_all_by_monthyear as 
select extract(year from creationdate) as year, extract(month from creationdate)as month, count(*) as count from  edits_gis 
where posthistorytypeid in (10,11,12,13) and userid<>-1 and extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by year, month;

drop table if exists gstats_cl_share_by_monthyear;
create table gstats_cl_share_by_monthyear as 
select mo.year, mo.month, al.count as count_all, mo.count as count_mods, cast(mo.count as float)/cast(al.count as float) as mod_co_share 
from gstats_cl_mod_by_monthyear mo 
join gstats_cl_all_by_monthyear al on mo.year=al.year and mo.month=al.month
order by mo.year, mo.month;

---number of new users---
drop table if exists gstats_users_by_month;
create table gstats_users_by_month as
select extract(year from creationdate) as year, extract(month from creationdate) as month, count(*) as users from users_gis where extract(year from creationdate)>2016 group by extract(year from creationdate), extract(month from creationdate) order by extract(year from creationdate), extract(month from creationdate);

--- final aggregations---
---join all by year since 2016---
drop table if exists gstats_yearly_mod_share;
create table gstats_yearly_mod_share as
select q.year, q.mod_q_share, a.mod_a_share, e.mod_e_share, c.mod_c_share, v.mod_v_share, cl.mod_cl_share
from gstats_qs_mod_share_by_year q join gstats_as_mod_share_by_year a on q.year=a.year
join gstats_ed_mod_share_by_year e on q.year=e.year
join gstats_co_mod_share_by_year c on q.year=c.year
join gstats_vo_mod_share_by_year v on q.year=v.year
join gstats_cl_mod_share_by_year cl on q.year=cl.year
order by q.year;

select q.year, q.count as questions, a.count as answers, e.count as edits, c.count as comments, v.count as up_down_votes, cl.count as close_delete_votes
from gstats_qs_all_by_year q join gstats_as_all_by_year a on q.year=a.year
join gstats_ed_all_by_year e on q.year=e.year
join gstats_co_all_by_year c on q.year=c.year 
join gstats_vo_all_by_year v on q.year=v.year
join gstats_cl_all_by_year cl on q.year=cl.year
order by q.year;

---also the total number of edits by moderators decreased more than the number of comments;
---the moderator of comments stays stable even as the number of answers and votes decreased in 2019, similar observation for closing votes---
drop table if exists gstats_yearly_normalized;
create table gstats_yearly_normalized as
select q.year, q.count/15491.0 as questions, a.count/16550.0 as answers, e.count/64339.0 as edits, c.count/51209.0 as comments, v.count/127101.0 as up_down_votes, cl.count/4047.0 as close_delete_votes
from gstats_qs_all_by_year q join gstats_as_all_by_year a on q.year=a.year
join gstats_ed_all_by_year e on q.year=e.year
join gstats_co_all_by_year c on q.year=c.year 
join gstats_vo_all_by_year v on q.year=v.year
join gstats_cl_all_by_year cl on q.year=cl.year
order by q.year;

drop table if exists gstats_month;
create table gstats_month as
select q.year, q.month, q.count as questions, a.count_all as answers_all, a.count_mods as answers_mods, e.count_all as edits, e.count_mods as edits_mod, c.count_all as comments, c.count_mods as comments_mod, v.count_all as up_down_votes, v.count_mods as votes_mod, cl.count_all as close_delete_votes, cl.count_mods as close_delete_mod, u.users
from gstats_qs_all_by_monthyear q join gstats_as_share_by_monthyear a on q.year=a.year and q.month=a.month
join gstats_ed_share_by_monthyear e on q.year=e.year and q.month=e.month
join gstats_co_share_by_monthyear c on q.year=c.year and q.month=c.month
join gstats_vo_share_by_monthyear v on q.year=v.year and q.month=v.month
join gstats_cl_share_by_monthyear cl on q.year=cl.year and q.month=cl.month
join gstats_users_by_month u on q.year=u.year and q.month=u.month
order by q.year, q.month;

--- suspiciously high number of edits in april 2017 ---

select postid, count(*) as n_edits from edits_gis where extract(year from creationdate)=2017 and userid>-1 and extract(month from creationdate)=4 and posthistorytypeid in (4,5,6) group by postid order by n_edits desc;

select count(*) as n_edits from edits_gis where extract(year from creationdate)=2017 and extract(month from creationdate)=2 and posthistorytypeid in (4,5,6) order by n_edits desc;

select * from comments_gis where userid=-1;


