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
        self.conn_info = db_string.split(':')
        if len(self.conn_info) < 3:
            raise Exception('connection string: "' + db_string + '" must be user:pass:db(:server(:port))')

        self.user = self.conn_info[0]
        self.passwd = self.conn_info[1]
        self.dbname = self.conn_info[2]
        self.host = 'localhost'
        self.port = '5432'
        if len(self.conn_info) > 3:
            self.host = self.conn_info[3]
        if len(self.conn_info) > 4:
            self.port = self.conn_info[4]
    
        try:
            self.conn = psycopg2.connect(user=self.user, password=self.passwd,
                dbname=self.dbname, host=self.host, port=self.port)
        except psycopg2.Error as e:
            print ('cannot connect', db_string)
            print (e)
        return self.conn

    def __str__(self):
        return self.conn_info

    def radios(self, region):
        # checkear que region es string y existe como schema, si no raise
        if not isinstance(region, str):
            raise Exception(region + 'debe ser de tipo string')
        sql = ("select distinct prov::integer, dpto::integer, frac::integer, radio::integer"
           " from " + region + ".listado"
           " order by prov::integer, dpto::integer, frac::integer, radio::integer;")
        try:
            cur.execute(sql)
            self.radios = cur.fetchall()
            return self.radios
        except psycopg2.Error as e:
            print ('q cagada :-(', region)
            print (e)
        



dao = DAO()
#conn = dao.db()
#conn = dao.db('a')
#conn = dao.db('u:p:d')
conn = dao.db('segmentador:rodatnemges:censo2020:172.26.67.239')
print (conn) # xq no usa __str__ ?
cur = conn.cursor()
print (cur)

#radios = dao.radios(1)
#radios = dao.radios('1')
radios = dao.radios('e0298')
print (radios)

