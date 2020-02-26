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

    def __init__(self, db_string):
        conn_info = db_string.split(':')
        try:
            len(conn_info) != 3
        except psycopg2.Error as e:
            print ('connection string: "', db_string, '" must be user:pass:db(:server(:port))')
            sys.exit()

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

    def __str__(self):
        pass

#data = DAO()
#data = DAO('a')
#data = DAO('u:p:d')
data = DAO('segmentador:rodatnemges:censo2020:172.26.67.239')


