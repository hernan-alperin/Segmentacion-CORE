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
  select substr(table_schema,2,2) prov, count(*) as listados
  from information_schema.tables
  where table_schema similar to 'e[0-9]{8}' and table_name = 'listado'
  group by substr(table_schema,2,2))
select * 
from provs_localidades_conteo
natural full join covers
natural full join listados
order by prov
;



/*
2022-01-17  6:40

psql -h 10.70.80.82 UATSEG -U halperin
UATSEG=> \i estadisticas_avance.sql
 prov | localidades | covers | listados
------+-------------+--------+----------
 02   |          15 |      9 |       15
 10   |         116 |    116 |      116
 14   |         452 |    450 |      450
 18   |          41 |     41 |       41
 26   |          46 |     46 |       46
 30   |           2 |      2 |        2
 34   |          34 |     33 |       34
 38   |          48 |     43 |       46
 42   |          22 |     22 |       22
 46   |          17 |     16 |       17
 50   |          16 |     10 |       16
 54   |          36 |     35 |       36
 58   |          23 |     23 |       23
 62   |           9 |      9 |        9
 66   |         158 |    158 |      158
 70   |           7 |      7 |        7
 74   |          15 |     15 |       15
 82   |           4 |      4 |        4
 86   |           1 |      1 |        1
 90   |          49 |     49 |       49
 94   |           6 |      6 |        6
(21 rows)

psql -h 172.26.68.222 PRODSEG -U halperin
PRODSEG=> \i estadisticas_avance.sql
 prov | localidades | covers | listados
------+-------------+--------+----------
 10   |          30 |     28 |       30
 14   |         132 |    132 |      132
 18   |          41 |     41 |       41
 34   |          18 |     18 |       18
 42   |          16 |     16 |       16
 46   |           5 |      5 |        5
 50   |           9 |      9 |        9
 62   |           9 |      9 |        9
 66   |         163 |    163 |      163
 74   |          15 |     15 |       15
 82   |         406 |    406 |      404
 86   |           1 |      1 |        1
 90   |          44 |     44 |       44
(13 rows)

*/
