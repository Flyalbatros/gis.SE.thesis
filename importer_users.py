import psycopg2 as pg

class DB_connection(object):

    def __init__(self, dbname, host, password="1234", username="postgres", port="5432"):
        #creates the connexion to the database
        self.conn = pg.connect("dbname={} user={} password={} host={} port={}".format(dbname, username, password, host, port))
        self.cursor = self.conn.cursor()

    def query_and_return(self,query):
        #sends a query to the database and fetches the result
        self.cursor.execute(query)
        #return self.cursor.fetchall()

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
                str_dict['Reputation'] = 'None'
                str_dict['CreationDate'] = 'None'
                str_dict['DisplayName'] = 'None'
                str_dict['LastAccessDate'] = 'None'
                str_dict['Location'] = 'None'
                str_dict['AboutMe'] = 'None'
                str_dict['Views'] = 'None'
                str_dict['UpVotes'] = 'None'
                str_dict['DownVotes'] = 'None'
                str_dict['AccountId'] = '-99'
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

if __name__=="__main__":
    target_db = DB_connection("SE_GIS", "127.0.0.1")
    #file = open("users.xml", "r")
    #print(file.readline())
    user_file = xml_reader("Users.xml")
    command_strs = user_file.output_line()
    for data_dict in command_strs:
        print(data_dict)
        data_string = "'{0}','{1}','{2}','{3}','{4}','{5}','{6}','{7}','{8}','{9}','{10}'".format(
             data_dict['Id'], data_dict['Reputation'], data_dict['CreationDate'],data_dict['DisplayName'],data_dict['LastAccessDate'],data_dict['Location'],data_dict['AboutMe'],data_dict['Views'], data_dict['UpVotes'], data_dict['DownVotes'], data_dict['AccountId'])
        print(data_string)
        target_db.query_and_return("Insert into users_GIS values ("+data_string+")")
    target_db.save()