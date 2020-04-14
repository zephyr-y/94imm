import threading,pymysql,time,requests,os,urllib3

def get_data():
    db = pymysql.connect("127.0.0.1", "root", "fendou2009", "silumz")
    cursor = db.cursor()
    # sqltab="alter table images_page AUTO_INCREMENT=1"
    # cursor.execute(sqltab)
    sql="select * from images_page where id>=46460 and id<=46446"
    cursor.execute(sql)
    i = 50000
    for data in cursor.fetchall():
        sqlupdata="update images_page set id="+"'"+str(i)+"'"+"where id="+"'"+str(data[0])+"'"
        cursor.execute(sqlupdata)
        sqlopimg="update images_image set pageid="+"'"+str(i)+"'"+"where pageid="+"'"+str(data[0])+"'"
        cursor.execute(sqlopimg)
        i=i-1
        print(i)

get_data()