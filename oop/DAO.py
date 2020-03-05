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
        self.cur = self.conn.cursor()
        return 

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
            self.cur.execute(sql)
            self.radios = self.cur.fetchall()
        except psycopg2.Error as e:
            print ('q cagada :-(', region)
            print (e)
        return self.radios

    def get_listado(self, region):
        sql = 'select * from "' + region + '".listado'
        try:
            self.cur.execute(sql)
            listado = self.cur.fetchall()
            return listado
        except psycopg2.Error as e:
            print ('q cagada :-(', region)
            print (e)

    def get_adyacencias(self, region):
        sql = 'select * from "' + region + '".lados_adyacentes'
        try:
            self.cur.execute(sql)
            adyacencias = self.cur.fetchall()
            return adyacencias
        except psycopg2.Error as e:
            print ('q cagada :-(', region)
            print (e)

    def sql_where_PPDDDLLLMMM(prov, depto, frac, radio, cpte, side):
        if type(cpte) is int:
            mza = cpte
        elif type(cpte) is tuple:
            (mza, lado) = cpte
            where_mza = ("\nwhere substr(mza" + side + ",1,2)::integer = " + str(prov)
                + "\n and substr(mza" + side + ",3,3)::integer = " + str(depto)
                + "\n and substr(mza" + side + ",9,2)::integer = " + str(frac)
                + "\n and substr(mza" + side + ",11,2)::integer = " + str(radio)
                + "\n and substr(mza" + side + ",13,3)::integer = " + str(mza)
                )
        if type(cpte) is tuple:
            where_mza = (where_mza 
            + "\n and lado" + side + "::integer = " + str(lado))
        return where_mza

    def set_componente_segmento(self, region, prov, dpto, frac, radio, cpte, seg):
    #------
    # update table = region.arc  (usando lados)
    #------
         sql_i = ("update " + region + '.arc'
            + " set segi = " + str(seg)
            + sql_where_PPDDDLLLMMM(prov, depto, frac, radio, cpte, 'i')
            + " AND mzai is not null AND mzai != ''"
            + "\n;")
         #print "", sql_i
         self.cur.execute(sql_i)
         sql_d = ("update " + region + '.arc'   
            + " set segd = " + str(seg)
            + sql_where_PPDDDLLLMMM(prov, depto, frac, radio, cpte, 'd')
            + " AND mzad is not null AND mzad != ''"
            + "\n;")
         #print " ", sql_d
         self.cur.execute(sql_d)
         self.conn.commit()
        
 

dao = DAO()
#conn = dao.db()
#conn = dao.db('a')
#conn = dao.db('u:p:d')
dao.db('segmentador:rodatnemges:censo2020:172.26.67.239')
print (dao.conn) # xq no usa __str__ ?
print (dao.cur)

#radios = dao.radios(1)
#radios = dao.radios('1')
radios = dao.radios('e0298')
print (radios)

#listado = dao.get_listado('e0298')
#print (listado)

adyacencias = dao.get_adyacencias('0365')
print (adyacencias)



