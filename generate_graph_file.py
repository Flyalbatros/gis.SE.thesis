import psycopg2 as pg
import networkx as nx
from networkx.algorithms import community

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

    def graph_reader_writer(self, outputfile_name, filter_weight):
        data1 = self.query_and_return("Select subthread_users from question_answer_subthreads_with_edits;")
        data2 = self.query_and_return("Select subthread_users from question_comment_subthreads_with_edits;")
        data3 = self.query_and_return("Select subthread_users from answer_clusters;")
        #print(data)
        graph_dict = dict()
        outfile = open(outputfile_name, "w")
        #outfile.write('start, end, weight\n')
        data = data1+data2+data3
        for subthread in data:
            userlist_no_duplicates = list(set(subthread[0]))
            #print(userlist_no_duplicates)
            if -99 in userlist_no_duplicates:
                #userlist_no_duplicates = userlist_no_duplicates.remove(-99)
                del userlist_no_duplicates[userlist_no_duplicates.index(-99)]
                #print(userlist_no_duplicates)
            for user_idx in range(0, len(userlist_no_duplicates)-1):
                loop_counter = 1
                while loop_counter != len(userlist_no_duplicates)-user_idx:
                    key1 = str(userlist_no_duplicates[user_idx])+' '+str(userlist_no_duplicates[user_idx+loop_counter])
                    key2 = str(userlist_no_duplicates[user_idx+loop_counter]) + ' ' + str(userlist_no_duplicates[user_idx])
                    if key1 in graph_dict:
                        graph_dict[key1] += 1
                    elif key2 in graph_dict:
                        graph_dict[key2] += 1
                    else:
                        graph_dict[key1] = 1
                    loop_counter+=1
        for edge in graph_dict:
            if graph_dict[edge] > filter_weight:
                outfile.write(str(edge)+' '+str(graph_dict[edge])+'\n')
        print("successfully exported graph data from database to: " + outputfile_name)

class graph_partitioner(object):

    def __init__(self, input_filename):
        infile = open(input_filename, 'r')
        self.G = nx.read_edgelist(infile, nodetype=int, data=(('weight',float),))
        print("successfully loaded graph from file: "+input_filename)

    def partition(self, k_size):
        print("starting community partitioning")
        communities_generator = list(community.k_clique_communities(self.G, k_size))
        print(communities_generator)

if __name__=="__main__":
    target_db = DB_connection("SE_GIS", "127.0.0.1")
    #file = open("users.xml", "r")
    #print(file.readline())
    target_db.graph_reader_writer('exports/test_export_graph.txt', 1)
    graph_gis_SE = graph_partitioner('exports/test_export_graph.txt')
    graph_gis_SE.partition(4)
    #print(list(graph_gis_SE.G.edges(data=True)))


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