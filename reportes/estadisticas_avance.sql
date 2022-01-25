/*
genera estadísticas de avance de carga de localidades y de segmentación
y radios
autor: -h
fecha: 2022-01-17 Lu
*/

with esquemas as (
  select schema_name as esquema
  from information_schema.schemata 
  where schema_name similar to 'e[0-9]{8}'),
provs_localidades_conteo as (
  select substr(esquema,2,2) prov, count(*) as localidades
  from esquemas
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
locs2010 as (
  select substr(codigo,1,2) prov, count(*) locs2010
  from public.localidad
  group by substr(codigo,1,2)),
radios2010 as (
  select substr(codigo,1,2) prov, 
    count(case when tipo_de_radio_id = 2 then 1 else Null end) r, 
    count(case when tipo_de_radio_id = 1 then 1 else Null end) m,
    count(case when tipo_de_radio_id = 3 then 1 else Null end) u 
  from radio 
  group by substr(codigo,1,2)),
estadisticas as (
  select prov, provincia, 
    localidades, covers, c1s, locs2010, m, u
  from provs_localidades_conteo
  natural full join covers
  natural full join listados
  natural full join provincias
  natural full join locs2010
  natural full join radios2010
)
select prov, provincia, --localidades, covers, c1s, 
  locs2010, m, u
from estadisticas
union
select '', 'total país', --sum(localidades), sum(covers), sum(c1s), 
  sum(locs2010), sum(m), sum(u)
from estadisticas
order by prov
;

/*
-- ver radios segmentados (consulta de Manu)
select substr(codigo,1,2) prov, count(*) radios, 
  count(CASE WHEN resultado is not null then 1 else null end) radios_probados 
from radio 
GROUP BY 1
; 
*/



/*
2022-01-17  7:30
psql -h 10.70.80.82 UATSEG -U halperin
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

psql -h 172.26.68.222 PRODSEG -U halperin
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

Tue Jan 25 07:09:49 -03 2022
 prov |            provincia            | locs2010 |  m   |   u
------+---------------------------------+----------+------+-------
      | total país                      |     1908 | 1174 | 13639
 02   | Ciudad Autónoma de Buenos Aires |          |      |
 06   | Buenos Aires                    |          |      |
 10   | Catamarca                       |       97 |   42 |   365
 14   | Córdoba                         |      241 |  193 |  1438
 18   | Corrientes                      |      120 |  137 |  1174
 22   | Chaco                           |       39 |   21 |   237
 26   | Chubut                          |       78 |   28 |   847
 30   | Entre Ríos                      |          |      |
 34   | Formosa                         |       98 |   83 |   700
 38   | Jujuy                           |          |      |
 42   | La Pampa                        |       39 |   19 |   295
 46   | La Rioja                        |       89 |   25 |   442
 50   | Mendoza                         |       19 |   27 |    91
 54   | Misiones                        |          |      |
 58   | Neuquén                         |          |      |
 62   | Río Negro                       |       40 |   16 |   216
 66   | Salta                           |      186 |  128 |  1412
 70   | San Juan                        |       46 |   37 |    87
 74   | San Luis                        |       52 |   31 |   403
 78   | Santa Cruz                      |          |      |
 82   | Santa Fe                        |      433 |  230 |  4699
 86   | Santiago del Estero             |      192 |  102 |   589
 90   | Tucumán                         |      128 |   47 |   430
 94   | Tierra del Fuego                |       11 |    8 |   214
(25 rows)

*/
