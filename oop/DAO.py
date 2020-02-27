# -*- coding: utf-8 -*-
"""
título: DAO.py
descripción: Objeto Abstacto de Datos
envuelve la comunicación entre el código los datos
usando classes
fecha: 2020-02-26
autor: -h
"""
from operator import *
import psycopg2
import logging
import sys

class DAO:
    # Data Abract Object
    def __init__(self):
        pass

    def db(self, db_string):
        conn_info = db_string.split(':')
        if len(conn_info) < 3:
            raise Exception('connection string: "' + db_string + '" must be user:pass:db(:server(:port))')

        self.user = conn_info[0]
        self.passwd = conn_info[1]
        self.dbname = conn_info[2]
        self.host = 'localhost'
        self.port = '5432'
        if len(conn_info) > 3:
            self.host = conn_info[3]
        if len(conn_info) > 4:
            self.port = conn_info[4]
    
        try:
            conn = psycopg2.connect(user=self.user, password=self.passwd,
                dbname=self.dbname, host=self.host, port=self.port)
        except psycopg2.Error as e:
            print ('cannot connect', db_string)
            print (e)
        return conn

    def __str__(self):
        pass

dao = DAO()
#conn = dao.db()
#conn = dao.db('a')
#conn = dao.db('u:p:d')
conn = dao.db('segmentador:rodatnemges:censo2020:172.26.67.239')
print (conn)
cur = conn.cursor()
print (cur)


