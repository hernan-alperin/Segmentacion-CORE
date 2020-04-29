# -*- coding: utf-8 -*-
import unittest
import logging
import psycopg2
from .. import DAO # esto no anda... ver como importar el modulo

logging.basicConfig(filename='unittest.log',
                    format='%(asctime)s %(levelname)s:%(message)s',
                    datefmt='%d/%m/%Y %I:%M:%S %p',
                    level=logging.DEBUG
                    )

class TestDAO(unittest.TestCase):
    dao = DAO()
    def test_connection(self):
        self.assertRaises(psycopg2.Error, dao.db, '')
        self.assertRaises(psycopg2.Error, DAO.__init__, 'a')
        self.assertRaises(psycopg2.Error, DAO.__init__, 'a:b:c')
        self.assertRaises(psycopg2.Error, DAO.__init__, 'segmentador:rodatnemges:censo2020:172.26.67.239')

if __name__ == '__main__':
    unittest.main()


