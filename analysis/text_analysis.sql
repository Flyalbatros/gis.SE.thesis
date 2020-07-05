---count the characters, presence of code snippets, external references and images in code---
select row_id, body, char_length(body), char_length(replace(body, ' ', '')), 
(char_length(body)-char_length(replace(body, ';code', '')))>0 as code_present,
(char_length(body)-char_length(replace(body, '&lt;a href=', '')))>0 as ext_ref_present,
(char_length(body)-char_length(replace(body, 'img src', '')))>0 as img_present
from posts_gis order by row_id desc;
									   