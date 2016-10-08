import datetime
import queue
from datetime import timedelta
import time, threading
import mysql.connector
from tqdm import tqdm
from time import sleep

SOURCE_ENDPOINT = "master.mysql.internal.io"
SOURCE_LOGIN = "mysqladmin"
SOURCE_PASSWORD = "mysqladmin"

DESTINATION_ENDPOINT = "master.mysql.internal.io"
DESTINATION_LOGIN = "mysqladmin"
DESTINATION_PASSWORD = "mysqladmin"

class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[91m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[00m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


class MySQLCompare(object):
    def __init__(self, uri, login, password):
        self.uri = uri
        self.login = login
        self.password = password
        try:
            self.conn = mysql.connector.connect(user=login, password=password, host=uri, database='mysql')
        except Exception as e:
            print(e)

    def getDBList(self):
        blacklist = ['information_schema', 'innodb', 'performance_schema', 'sys', 'teste']

        query = ("SHOW DATABASES")
        cur = self.conn.cursor()
        cur.execute(query)

        dbList = list()
        for Database in cur:
            if Database[0] not in blacklist:
                dbList.append(Database[0])

        cur.close()
        return dbList

    def getTableList(self, dbList):

        whitelist = ('"' + '", "'.join(dbList) + '"')
        query = (
        "select table_name, table_schema from information_schema.tables where table_schema in (%s)" % whitelist)
        cur = self.conn.cursor()
        cur.execute(query)

        tblList = list()
        for (table_name, table_schema) in cur:
            tblList.append("{}.{}".format(table_schema, table_name))

        cur.close()
        return tblList

    def getRows(self, table_name, queue):
        rows = 0
        query = "SELECT count(1) as rows_table FROM {};".format(table_name)
        cur = self.conn.cursor()
        cur.execute(query)
        for rows_table in cur:
            rows = rows_table[0]
        cur.close()
        queue.put(int(rows))
        return int(rows)

    def getViews(self, dbList):
        whitelist = ('"' + '", "'.join(dbList) + '"')
        query = ("SELECT table_name, table_schema FROM INFORMATION_SCHEMA.VIEWS WHERE table_schema in (%s)" % whitelist)
        cur = self.conn.cursor()
        cur.execute(query)
        viewList = list()
        for (table_name, table_schema) in cur:
            viewList.append("{}.{}".format(table_schema, table_name))

        cur.close()
        return viewList

    def getProcs(self, dbList):
        whitelist = ('"' + '", "'.join(dbList) + '"')
        query = ("select db, name from mysql.proc where db not in (%s)" % whitelist)
        cur = self.conn.cursor()
        cur.execute(query)
        procList = list()
        for (db, name) in cur:
            procList.append("{}.{}".format(db, name))
        cur.close()
        return procList


def checkDBs(dbList1, dbList2):
    validation = False
    if len(dbList1) == len(dbList2):
        validation = True
    return (len(dbList1), len(dbList2), validation)


def checkTables(tbList1, tbList2):
    validation = False
    if len(tbList1) == len(tbList1):
        validation = True
    return (len(tbList1), len(tbList1), validation)


def checkViews(viewList1, viewList2):
    validation = False
    if len(viewList1) == len(viewList2):
        validation = True
    return (len(viewList1), len(viewList2), validation)


def checkProc(procList1, procList2):
    validation = False
    if len(procList1) == len(procList2):
        validation = True
    return (len(procList1), len(procList2), validation)


def checkBasic():
    source =  MySQLCompare(uri=SOURCE_ENDPOINT, login=SOURCE_LOGIN, password=SOURCE_PASSWORD)
    destination = MySQLCompare(uri=DESTINATION_ENDPOINT, login=DESTINATION_LOGIN, password=DESTINATION_PASSWORD)

    # List of dbs
    src_dbs = source.getDBList()
    dst_dbs = destination.getDBList()

    # List of tables
    src_tables = source.getTableList(src_dbs)
    dst_tables = destination.getTableList(dst_dbs)

    # List of Views
    src_views = source.getViews(src_dbs)
    dst_views = destination.getViews(dst_dbs)

    # List of Procs
    src_procs = source.getProcs(src_dbs)
    dst_procs = destination.getProcs(dst_dbs)

    # Checagens
    print ("DB-Check: {}".format(checkDBs(src_dbs, dst_dbs)))
    print ("Table-Check: {}".format(checkTables(src_tables, dst_tables)))
    print ("View-Check: {}".format(checkViews(src_views, dst_views)))
    print ("Proc-Check: {}".format(checkProc(src_procs, dst_procs)))



def parallelCheck():
    source = MySQLCompare(uri=SOURCE_ENDPOINT, login=SOURCE_LOGIN, password=SOURCE_PASSWORD)
    destination = MySQLCompare(uri=DESTINATION_ENDPOINT, login=DESTINATION_LOGIN, password=DESTINATION_PASSWORD)

    validation = bcolors.FAIL + "Fail" + bcolors.ENDC
    src_dbs = source.getDBList()
    dst_dbs = destination.getDBList()
    tableList = source.getTableList(src_dbs)
    #pbar = tqdm(sorted(tableList), bar_format='{percentage:3.0f}% - ', position=-2, dynamic_ncols=True, unit_scale=True)
    pbar = sorted(tableList)
    print ("Analysing {} tables".format(len(tableList)))
    sleep(2)
    for table_name in pbar:
            qrow_source =queue.Queue()
            qrow_destination = queue.Queue()
            t1 = threading.Thread(target=source.getRows, args=(table_name, qrow_source,))
            t2 = threading.Thread(target=destination.getRows, args=(table_name, qrow_destination,))
            t1.start()
            t2.start()
            t1.join()
            t2.join()
            row_source = qrow_source.get()
            row_destination = qrow_destination.get()
            if row_source == row_destination:
               validation = bcolors.OKBLUE + "OK" + bcolors.ENDC

            result = (row_source, row_destination)
            print ("Table {}: {} - {}".format(table_name, result, validation))
            #pbar.set_description("Processing %s" % table_name)



if __name__ == "__main__":
    checkBasic()
    parallelCheck()
