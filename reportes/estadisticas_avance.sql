/*
genera estadísticas de avance de carga de localidades y de segmentación
y radios
autor: -h
fecha: 2022-01-17 Lu
*/

with localidades as (
  select schema_name as esquema
  from information_schema.schemata 
  where schema_name similar to 'e[0-9]{8}'),
provs_localidades_conteo as (
  select substr(esquema,2,2) prov, count(*) as localidades
  from localidades
  group by substr(esquema,2,2)),
covers as (
  select substr(table_schema,2,2) prov, count(*) as covers
  from information_schema.tables
  where table_schema similar to 'e[0-9]{8}' and table_name = 'arc'
  group by substr(table_schema,2,2)),
listados as (
  select substr(table_schema,2,2) prov, count(*) as c1s
  from information_schema.tables
  where table_schema similar to 'e[0-9]{8}' and table_name = 'listado'
  group by substr(table_schema,2,2)),
provincias as (
  select codigo prov, nombre provincia
  from public.provincia),
estadisticas as (
  select prov, provincia, 
    localidades, covers, c1s
  from provs_localidades_conteo
  natural full join covers
  natural full join listados
  natural full join provincias
)
select prov, provincia, localidades, covers, c1s
from estadisticas
union
select '', 'total país', sum(localidades), sum(covers), sum(c1s)
from estadisticas
order by prov
;


/*
2022-01-17  7:30
psql -h 10.70.80.82 UATSEG
UATSEG=> \i estadisticas_avance.sql
 prov |            provincia            | localidades | covers | c1s
------+---------------------------------+-------------+--------+------
      | total país                      |        1117 |   1095 | 1113
 02   | Ciudad Autónoma de Buenos Aires |          15 |      9 |   15
 06   | Buenos Aires                    |             |        |
 10   | Catamarca                       |         116 |    116 |  116
 14   | Córdoba                         |         452 |    450 |  450
 18   | Corrientes                      |          41 |     41 |   41
 22   | Chaco                           |             |        |
 26   | Chubut                          |          46 |     46 |   46
 30   | Entre Ríos                      |           2 |      2 |    2
 34   | Formosa                         |          34 |     33 |   34
 38   | Jujuy                           |          48 |     43 |   46
 42   | La Pampa                        |          22 |     22 |   22
 46   | La Rioja                        |          17 |     16 |   17
 50   | Mendoza                         |          16 |     10 |   16
 54   | Misiones                        |          36 |     35 |   36
 58   | Neuquén                         |          23 |     23 |   23
 62   | Río Negro                       |           9 |      9 |    9
 66   | Salta                           |         158 |    158 |  158
 70   | San Juan                        |           7 |      7 |    7
 74   | San Luis                        |          15 |     15 |   15
 78   | Santa Cruz                      |             |        |
 82   | Santa Fe                        |           4 |      4 |    4
 86   | Santiago del Estero             |           1 |      1 |    1
 90   | Tucumán                         |          49 |     49 |   49
 94   | Tierra del Fuego                |           6 |      6 |    6
(25 rows)

psql -h 172.26.68.222 PRODSEG
PRODSEG=> \i estadisticas_avance.sql
psql:estadisticas_avance.sql:42: ERROR:  permiso denegado a la tabla provincia

 prov | provincia  | localidades | covers | c1s
------+------------+-------------+--------+-----
      | total país |         891 |    889 | 889
 10   |            |          30 |     28 |  30
 14   |            |         132 |    132 | 132
 18   |            |          42 |     42 |  42
 34   |            |          18 |     18 |  18
 42   |            |          16 |     16 |  16
 46   |            |           5 |      5 |   5
 50   |            |           9 |      9 |   9
 62   |            |          10 |     10 |  10
 66   |            |         163 |    163 | 163
 74   |            |          15 |     15 |  15
 82   |            |         406 |    406 | 404
 86   |            |           1 |      1 |   1
 90   |            |          44 |     44 |  44
(14 rows)


Thu Jan 20 06:23:19 -03 2022
psql -h 10.70.80.82 UATSEG 
 prov |            provincia            | localidades | covers | c1s
------+---------------------------------+-------------+--------+------
      | total país                      |        1304 |   1282 | 1301
 02   | Ciudad Autónoma de Buenos Aires |          15 |      9 |   15
 06   | Buenos Aires                    |             |        |
 10   | Catamarca                       |         127 |    127 |  127
 14   | Córdoba                         |         454 |    453 |  452
 18   | Corrientes                      |          43 |     43 |   43
 22   | Chaco                           |           2 |      2 |    2
 26   | Chubut                          |          47 |     47 |   47
 30   | Entre Ríos                      |          61 |     61 |   61
 34   | Formosa                         |          83 |     81 |   83
 38   | Jujuy                           |          57 |     52 |   56
 42   | La Pampa                        |          22 |     22 |   22
 46   | La Rioja                        |          17 |     16 |   17
 50   | Mendoza                         |          22 |     16 |   22
 54   | Misiones                        |          53 |     52 |   53
 55   | Sin Nombre                      |             |        |
 58   | Neuquén                         |          23 |     23 |   23
 62   | Río Negro                       |           9 |      9 |    9
 66   | Salta                           |         159 |    159 |  159
 70   | San Juan                        |          11 |     11 |   11
 74   | San Luis                        |          15 |     15 |   15
 78   | Santa Cruz                      |             |        |
 82   | Santa Fe                        |           4 |      4 |    4
 86   | Santiago del Estero             |           1 |      1 |    1
 90   | Tucumán                         |          73 |     73 |   73
 94   | Tierra del Fuego                |           6 |      6 |    6

psql -h 172.26.68.222 PRODSEG
 prov | provincia  | localidades | covers | c1s
------+------------+-------------+--------+------
      | total país |        1134 |   1132 | 1132
 10   |            |          32 |     30 |   32
 14   |            |         203 |    203 |  203
 18   |            |          73 |     73 |   73
 26   |            |          29 |     29 |   29
 34   |            |          77 |     77 |   77
 42   |            |          22 |     22 |   22
 46   |            |           5 |      5 |    5
 50   |            |          15 |     15 |   15
 62   |            |          11 |     11 |   11
 66   |            |         163 |    163 |  163
 70   |            |           8 |      8 |    8
 74   |            |          15 |     15 |   15
 82   |            |         406 |    406 |  404
 86   |            |           1 |      1 |    1
 90   |            |          70 |     70 |   70
 94   |            |           4 |      4 |    4
(17 rows)


Sat Jan 22 05:03:29 -03 2022
psql -h 172.26.68.222 PRODSEG

 prov | provincia  | localidades | covers | c1s
------+------------+-------------+--------+------
      | total país |        1240 |   1238 | 1237
 10   |            |          55 |     53 |   55
 14   |            |         209 |    209 |  209
 18   |            |          85 |     85 |   85
 22   |            |          11 |     11 |   11
 26   |            |          29 |     29 |   29
 34   |            |          77 |     77 |   77
 42   |            |          28 |     28 |   28
 46   |            |           5 |      5 |    5
 50   |            |          15 |     15 |   15
 62   |            |          12 |     12 |   12
 66   |            |         163 |    163 |  163
 70   |            |          12 |     12 |   12
 74   |            |          48 |     48 |   47
 82   |            |         406 |    406 |  404
 86   |            |           1 |      1 |    1
 90   |            |          80 |     80 |   80
 94   |            |           4 |      4 |    4
(18 rows)

Mon Jan 24 06:26:08 -03 2022
 prov |            provincia            | localidades | covers | c1s
------+---------------------------------+-------------+--------+------
      | total país                      |        1280 |   1279 | 1278
 02   | Ciudad Autónoma de Buenos Aires |             |        |
 06   | Buenos Aires                    |             |        |
 10   | Catamarca                       |          58 |     57 |   58
 14   | Córdoba                         |         209 |    209 |  209
 18   | Corrientes                      |          88 |     88 |   88
 22   | Chaco                           |          11 |     11 |   11
 26   | Chubut                          |          29 |     29 |   29
 30   | Entre Ríos                      |             |        |
 34   | Formosa                         |          77 |     77 |   77
 38   | Jujuy                           |             |        |
 42   | La Pampa                        |          28 |     28 |   28
 46   | La Rioja                        |           5 |      5 |    5
 50   | Mendoza                         |          15 |     15 |   15
 54   | Misiones                        |             |        |
 58   | Neuquén                         |             |        |
 62   | Río Negro                       |          19 |     19 |   19
 66   | Salta                           |         163 |    163 |  163
 70   | San Juan                        |          39 |     39 |   39
 74   | San Luis                        |          48 |     48 |   48
 78   | Santa Cruz                      |             |        |
 82   | Santa Fe                        |         406 |    406 |  404
 86   | Santiago del Estero             |           1 |      1 |    1
 90   | Tucumán                         |          80 |     80 |   80
 94   | Tierra del Fuego                |           4 |      4 |    4
(25 rows)

*/
