---count the characters in a post?---
select row_id, body, char_length(body), char_length(replace(body, ' ', '')) from posts_gis limit 10;
---presence of code---
select row_id, body, char_length(body), (char_length(body)-char_length(replace(body, 'code', '')))/char_length('code') from posts_gis limit 10;