---count the characters, presence of code snippets, external references and images in code---
drop table if exists q_a_characteristics;
create table q_a_characteristics as 
select row_id, body, array_remove(string_to_array(body, ' '), '') as words, array_length(array_remove(string_to_array(body, ' '), ''),1) as word_count, 
(char_length(body)-char_length(replace(body, ';code', '')))>0 as code_present,
(char_length(body)-char_length(replace(body, '&lt;a href=', '')))>0 as ext_ref_present,
(char_length(body)-char_length(replace(body, 'img src', '')))>0 as img_present
from posts_gis order by row_id desc; 

drop table if exists q_a_char_interact_output;
create table q_a_char_interact_output as
select question_id, parentid<>-99 as answer, words, word_count, code_present, ext_ref_present, img_present, question_id in (select parentid from list_splitting_all_high_interact_chains_agg) as high_interaction,
question_id in (select parentid from list_splitting_very_high_interact_chains_agg) as very_high_interaction 
from sampling_qora_co_prep s left join q_a_characteristics q on s.question_id=q.row_id;
									   
drop table if exists q_a_char_bin_analysis_export;								   
create table q_a_char_bin_analysis_export as									   
select answer, high_interaction, very_high_interaction, code_present, ext_ref_present, img_present, count(*) from q_a_char_interact_output group by answer, high_interaction, very_high_interaction, code_present, ext_ref_present, img_present;								   

create table q_a_char_wordcount_stats_answers as
select high_interaction, very_high_interaction, count(*), avg(word_count), stddev(word_count),
percentile_disc(0.1) within group (order by word_count) as percentile_10, percentile_disc(0.9) within group (order by word_count) as percentile_90 
from q_a_char_interact_output where answer is true group by high_interaction, very_high_interaction;

create table q_a_char_wordcount_stats_questions as
select high_interaction, very_high_interaction, count(*), avg(word_count), stddev(word_count),
percentile_disc(0.1) within group (order by word_count) as percentile_10, percentile_disc(0.9) within group (order by word_count) as percentile_90 
from q_a_char_interact_output where answer is false group by high_interaction, very_high_interaction;
									   
---low interaction: average: 107.00 words, stddev:106.99 words---
---high interaction: average: 154.46 words, stddev: 149.45 words---
---very high interaction: average: 174.47 words, stddev: 162.11 words---
								   
									   