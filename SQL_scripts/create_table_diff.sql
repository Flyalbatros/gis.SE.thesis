SELECT g.displayname, g.reputation as GIS_reputation, e.reputation as ES_reputation, abs(g.reputation-e.reputation) as reputation_diff FROM public.users_gis g join public.users_es e on g.accountid = e.accountid order by reputation_diff desc;
Create TABLE users_diff as 
SELECT ug.accountid, count(pg.*) as number_posts_GIS, ug.reputation as reputation_GIS, ug.reputation/count(pg.*) as rep_ratio_GIS, count(pe.*) as number_posts_ES, ue.reputation as reputation_ES, ue.reputation/count(pe.*) as rep_ratio_ES
FROM posts_gis pg join users_gis ug on pg.owneruserid=ug.row_id join users_es ue on ug.accountid=ue.accountid join posts_es pe on pe.owneruserid=ue.row_id
GROUP BY ug.accountid, ug.reputation, ue.reputation;
------
Create TABLE user_activity_es as SELECT ue.accountid, count(pe.*) as number_posts_ES, ue.reputation as reputation_ES
FROM users_es ue join posts_es pe on pe.owneruserid=ue.row_id
GROUP BY ue.accountid, ue.reputation;
Create TABLE user_activity_gis as SELECT ue.accountid, count(pe.*) as number_posts_GIS, ue.reputation as reputation_GIS
FROM users_gis ue join posts_gis pe on pe.owneruserid=ue.row_id
GROUP BY ue.accountid, ue.reputation;
Create TABLE users_diff as SELECT g.accountid, g.reputation_GIS, g.number_posts_GIS, e.reputation_ES, e.number_posts_ES 
FROM user_activity_gis g join user_activity_es e on g.accountid=e.accountid;

