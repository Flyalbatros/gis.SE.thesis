---620  (out of 394273) edist affected by delete accounts in 2017-2019, 4037 over entire forum existence---
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
create table spstats_reopenened_posts as
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

drop table if exists unlocked_posts;
create table unlocked_posts as
select postid, count(*), array_agg(creationdate) from edits_gis where posthistorytypeid=15 group by postid order by count(*) desc;

---


