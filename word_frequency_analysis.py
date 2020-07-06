import psycopg2 as pg
import operator

class DB_connection(object):

    def __init__(self, dbname, host, password="1234", username="postgres", port="5432"):
        #creates the connexion to the database
        self.conn = pg.connect("dbname={} user={} password={} host={} port={}".format(dbname, username, password, host, port))
        self.cursor = self.conn.cursor()

    def query_and_return(self,query):
        #sends a query to the database and fetches the result
        self.cursor.execute(query)
        return self.cursor.fetchall()

    def save(self):
        self.conn.commit()

class xml_reader(object):

    def __init__(self, filepath):
        self.file = open(filepath, "r", encoding='utf-8')

    def output_line(self):
        all_lines = self.file.readlines()
        output_strs = []
        for line in all_lines:
            if line[3:6] == "row":
                #prepare data and variables
                str_dict = dict()
                str_dict['Id'] = 'None'
                str_dict['PostId'] = 'None'
                str_dict['Score'] = '-99'
                str_dict['Text'] = 'None'
                str_dict['CreationDate'] = 'None'
                str_dict['UserId'] = '-99'
                first_quote = line.find('"')
                previous_quote = 7
                # now the actual data extraction
                while first_quote != -1:
                    second_quote = line.find('"', first_quote+1)
                    sub_str = line[first_quote+1:second_quote]
                    par_name = line[previous_quote:first_quote-1]
                    #print(par_name)
                    #correct datetime format
                    if len(sub_str) > 10:
                        if sub_str[10] == 'T':
                            sub_str = sub_str[0:10] + ' ' + sub_str[11:-4]
                    #save data in a dictionarry
                    str_dict[par_name] = sub_str.replace("'", "''").replace(",", ",,")
                    first_quote = line.find('"', second_quote+1)
                    previous_quote = second_quote + 2
                #print(str_dict)
                output_strs.append(str_dict)
        return output_strs

def process(agg_data):
    #print(agg_data[1][1])
    word_count_dict = dict()
    outword_dict = dict()
    counter = [0,0]
    for data in agg_data:
        if data[0] == True:
            category = 1
        else:
            category = 0
        remove =[]
        for index in range(0, len(data[1])):
            if data[1][index].find('&lt;code&gt') != -1:
                code_idx_start = index
                for index_bis in range(index, len(data[1])):
                    if data[1][index].find('&lt;/code&gt') != -1:
                        code_idx_end = index_bis
                        remove.append((code_idx_start, code_idx_end))
                        break
        to_process = data[1]
        correction = 0
        for combination in remove:
            to_process = to_process[0:combination[0]-correction]+to_process[combination[1]-correction:-1]
            correction += combination[1]-combination[0]
            #
            #
            # #search for &lt;code&gt and for &lt;/code&gt -> remove that part of the script, then split at spaces to get a list!
            # counter_loop = 0
            # while str_to_process.find('&lt;code&gt') != -1 and str_to_process.find('&lt;/code&gt') != -1:
            #     code_str_start = str_to_process.find('&lt;code&gt')
            #     code_str_end = str_to_process.find('&lt;/code&gt')
            #     str_to_process = str_to_process[0:code_str_start]+str_to_process[code_str_end+len('&lt;/code&gt'):-1]
            #     counter_loop += 1
            #     #if counter_loop>24 and counter_loop<28:
            #         #print(str_to_process)
            #     if counter_loop>30:
            #         print(counter_loop, str_to_process.find('&lt;code&gt'), code_str_start, code_str_end, '\n')
            #         print(len(str_to_process))
            # str_to_process = str_to_process.split()
        for word in to_process:
            if word.find('&') == -1:
                if word not in word_count_dict:
                    word_count_dict[word] = [0,0]
                word_count_dict[word][category]+= 1
                counter[category]+=1

    for word in word_count_dict:
        # word_count_dict[word][0] = word_count_dict[word][0]/counter_nor
        # word_count_dict[word][1] = word_count_dict[word][1]/counter_hi
        outword_dict[word] = word_count_dict[word][0]/counter[0]-word_count_dict[word][1]/counter[1]
    ordered_words = sorted(outword_dict.items(), key=operator.itemgetter(1))
    hi50 = ordered_words[0:50]
    nor50 = ordered_words[-50:-1]
    return(hi50, nor50)

def exporter(result, outfile_nm):
    outfile = open(outfile_nm, "w")
    outfile.write("top 20 words in high interaction questions/answers \n")
    for word in result[0]:
        outfile.write(str(word[0])+','+str(word[1])+'\n')
    outfile.write("top 20 words in regular questions/answers \n")
    for word in result[1]:
        outfile.write(str(word[0]) + ',' + str(word[1]) + '\n')
    outfile.close()

if __name__=="__main__":
    target_db = DB_connection("gisSE", "127.0.0.1")
    agg_data = target_db.query_and_return("Select high_interaction, words from q_a_char_interact_output where answer=True")
    #agg_data = [(False, '&lt;p&gt;From the following documentation: &lt;a href=&quot;https://grass.osgeo.org/grass78/manuals/r.mapcalc.html&quot; rel=&quot;nofollow noreferrer&quot;&gt;https://grass.osgeo.org/grass78/manuals/r.mapcalc.html&lt;/a&gt;.  &lt;/p&gt;&#xA;&#xA;&lt;blockquote&gt;&#xA;  &lt;ul&gt;&#xA;  &lt;li&gt;&lt;p&gt;The function isnull() returns 1 if its argument is NULL and 0 otherwise  &lt;/p&gt;&lt;/li&gt;&#xA;  &lt;li&gt;&lt;p&gt;if(x,,a) returns:&lt;br&gt;&#xA;  NULL if &lt;em&gt;x&lt;/em&gt; is NULL; &lt;em&gt;a&lt;/em&gt; if &lt;em&gt;x&lt;/em&gt; is non-zero; &lt;em&gt;0&lt;/em&gt; otherwise&lt;/p&gt;&lt;/li&gt;&#xA;  &lt;li&gt;&lt;p&gt;if(x,,a,,b) returns:&lt;br&gt;&#xA;  NULL if &lt;em&gt;x&lt;/em&gt; is NULL; &lt;em&gt;a&lt;/em&gt; if &lt;em&gt;x&lt;/em&gt; is non-zero; &lt;em&gt;b&lt;/em&gt; otherwise  &lt;/p&gt;&lt;/li&gt;&#xA;  &lt;/ul&gt;&#xA;&lt;/blockquote&gt;&#xA;&#xA;&lt;p&gt;If the value of the pixel in &lt;em&gt;map1&lt;/em&gt; is &lt;em&gt;NULL&lt;/em&gt;,, &lt;code&gt;isnull(map1)&lt;/code&gt; returns &lt;em&gt;1&lt;/em&gt;. Otherwise returns &lt;em&gt;0&lt;/em&gt;.  &lt;/p&gt;&#xA;&#xA;&lt;p&gt;As &lt;code&gt;isnull(map1)&lt;/code&gt; returns non-zero (&lt;em&gt;1&lt;/em&gt;) for &lt;em&gt;NULL&lt;/em&gt; values in &lt;em&gt;map1&lt;/em&gt;,, &lt;code&gt;if(isnull(map1),, 0)&lt;/code&gt; returns &lt;em&gt;0&lt;/em&gt;. Otherwise returns &lt;em&gt;0&lt;/em&gt;,, too.  &lt;/p&gt;&#xA;&#xA;&lt;p&gt;So,, we need a third argument:  &lt;/p&gt;&#xA;&#xA;&lt;ul&gt;&#xA;&lt;li&gt;As &lt;code&gt;isnull(map1)&lt;/code&gt; returns non-zero (&lt;em&gt;1&lt;/em&gt;) for &lt;em&gt;NULL&lt;/em&gt; values in &lt;em&gt;map1&lt;/em&gt;,, &lt;code&gt;if(isnull(map1),, 0,, map1)&lt;/code&gt; returns &lt;em&gt;0&lt;/em&gt;. Otherwise returns &lt;em&gt;map1&lt;/em&gt; value.  &lt;/li&gt;&#xA;&lt;/ul&gt;&#xA;&#xA;&lt;hr&gt;&#xA;&#xA;&lt;p&gt;Seems to me that there are some ways to implement the same logic.  &lt;/p&gt;&#xA;&#xA;&lt;p&gt;But following your expression,, &lt;code&gt;if(isnull(map1),, 0,, map1)&lt;/code&gt; can achieve your goal.&lt;/p&gt;&#xA;'), (False, '&lt;p&gt;It appears that your data frame isn’t sized symmetrically/centered on your page. Select the data frame to bring up the corner anchors,, then resize. &lt;/p&gt;&#xA;'), (False, "&lt;p&gt;There is a specific python library that you need to import:&lt;/p&gt;&#xA;&#xA;&lt;pre&gt;&lt;code&gt;# import the GIS class in gis module&#xA;from arcgis.gis import GIS&#xA;&lt;/code&gt;&lt;/pre&gt;&#xA;&#xA;&lt;p&gt;I suggest for the following code snippets that you use the print function so you know what account you are logging in with,, and what code affects your credentials so you fully understand. &lt;/p&gt;&#xA;&#xA;&lt;p&gt;You can print what your logged in as (just to make sure while testing/troubleshooting):&lt;/p&gt;&#xA;&#xA;&lt;pre&gt;&lt;code&gt;print(&quot;Logged in as &quot; + str(gis.properties.user.username))&#xA;&lt;/code&gt;&lt;/pre&gt;&#xA;&#xA;&lt;p&gt;To log in with a built-in account then use the following code (this for an account that is setup in ArcGIS Server under users and given a role): &lt;/p&gt;&#xA;&#xA;&lt;pre&gt;&lt;code&gt;print(&quot;Portal for ArcGIS as a built in user&quot;)&#xA;gis = GIS(&quot;https://portalname.domain.com/webadapter_name&quot;,, &quot;sharinguser&quot;,, &quot;password&quot;)&#xA;print(&quot;Logged in as: &quot; + gis.properties.user.username)&#xA;&lt;/code&gt;&lt;/pre&gt;&#xA;&#xA;&lt;p&gt;If you want to log in with Web-tier authentication then use the following code:&lt;/p&gt;&#xA;&#xA;&lt;pre&gt;&lt;code&gt;print(&quot;\\n\\nBasic Authentication with LDAP&quot;)    &#xA;ldapbasic = GIS(&quot;https://portalname.domain.com/webadapter_name&quot;,, &quot;amy&quot;,, &quot;password&quot;)&#xA;print(&quot;Logged in as: &quot; + ldapbasic.properties.user.username)&#xA;&lt;/code&gt;&lt;/pre&gt;&#xA;&#xA;&lt;p&gt;If you want to use Portal account log in credentials then use the following code:&lt;/p&gt;&#xA;&#xA;&lt;pre&gt;&lt;code&gt;print(&quot;\\n\\nPortal-tier Authentication with LDAP - enterprise user&quot;)&#xA;gisldap = GIS(&quot;https://portalname.domain.com/webadapter_name&quot;,, &quot;AVWORLD\\\\Publisher&quot;,, &quot;password&quot;)&#xA;print(&quot;Logged in as: &quot; + gisldap.properties.user.username)&#xA;&lt;/code&gt;&lt;/pre&gt;&#xA;&#xA;&lt;p&gt;And if you want to use Portal with LDAP (so your network account that you maybe be referring to) then use this code:&lt;/p&gt;&#xA;&#xA;&lt;pre&gt;&lt;code&gt;print(&quot;\\n\\nPortal-tier Authentication with LDAP - builtin user&quot;)    &#xA;gisldap = GIS(&quot;https://portalname.domain.com/webadapter_name&quot;,, &quot;sharing1&quot;,, &quot;password&quot;)&#xA;print(&quot;Logged in as: &quot; + gisldap.properties.user.username)&#xA;&lt;/code&gt;&lt;/pre&gt;&#xA;&#xA;&lt;p&gt;If you don't have success with the above,, or have a different authorization pattern follow this link:&lt;/p&gt;&#xA;&#xA;&lt;p&gt;&lt;a href=&quot;https://developers.arcgis.com/python/guide/working-with-different-authentication-schemes/&quot; rel=&quot;nofollow noreferrer&quot;&gt;https://developers.arcgis.com/python/guide/working-with-different-authentication-schemes/&lt;/a&gt;&lt;/p&gt;&#xA;")]
    result = process(agg_data)
    exporter(result, "top_words_answers.txt")
    agg_data = target_db.query_and_return("Select high_interaction, words from q_a_char_interact_output where answer=False")
    result = process(agg_data)
    exporter(result, "top_words_questions.txt")

# if __name__=="__main__":
#     target_db = DB_connection("SE_GIS", "127.0.0.1")
#     #file = open("users.xml", "r")
#     #print(file.readline())
#     user_file = xml_reader("Posts.xml")
#     command_strs = user_file.output_line()
#     for data_dict in command_strs:
#         print(data_dict)
#         data_string = "'{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}','{11}','{12}', '{13}'".format(
#              data_dict['Id'], data_dict['PostTypeId'], data_dict['AcceptedAnswerId'],data_dict['CreationDate'],data_dict['Score'],data_dict['ViewCount'],data_dict['Body'],data_dict['OwnerUserId'], data_dict['LastActivityDate'], data_dict['Tags'], data_dict['Title'], data_dict['AnswerCount'], data_dict['CommentCount'], data_dict['FavoriteCount'])
#         print(data_string)
#         target_db.query_and_return("Insert into posts_GIS values ("+data_string+")")
#     target_db.save()