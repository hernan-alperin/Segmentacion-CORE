/*
reporte de avance
uso sql de Manu
cantidad de segmentaciones cerradas(*) por día
(*) día de ultima vez que se segmentó
*/

with hechos_por_dia as (
  select substr(codigo,1,2) prov,date(updated_at) hecho,
  count(case when resultado is not null then 1 else null end) cant
  from radio
  where updated_at is not null
  group by 1,date(updated_at)
  ),
avance as (
  select hoy.prov prov, hoy.hecho hecho, sum(antes.cant) cant
  from hechos_por_dia hoy
  join hechos_por_dia antes
  on antes.prov = hoy.prov and antes.hecho <= hoy.hecho
  group by 1,2
  ),
ultimo as (
  select prov, max(hecho) hecho
  from avance
  group by 1
  )
select prov, cant, ultimo.hecho
from avance
natural join ultimo
order by 1
;

/*
Thu Jan 20 07:41:41 -03 2022
UATSEG-> ;
 prov | cant |   hecho
------+------+------------
 02   |    4 | 2022-01-14
 04   |    0 | 2022-01-18
 10   |  203 | 2022-01-19
 14   |  231 | 2022-01-19
 18   |  290 | 2022-01-19
 22   |   68 | 2022-01-19
 26   |  249 | 2022-01-19
 30   |  184 | 2022-01-20
 34   |    0 | 2022-01-10
 38   |  108 | 2022-01-18
 42   |   79 | 2022-01-11
 46   |    0 | 2022-01-07
 50   |   48 | 2022-01-18
 54   |  125 | 2022-01-19
 58   |  250 | 2022-01-19
 62   |   41 | 2021-12-30
 66   |  231 | 2022-01-19
 70   |   11 | 2022-01-19
 74   |   39 | 2022-01-20
 82   |    1 | 2022-01-17
 86   |    3 | 2022-01-18
 90   |   31 | 2022-01-17
 94   |  222 | 2022-01-20
(23 rows)


*/
