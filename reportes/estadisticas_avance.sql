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
  select prov, provincia, localidades, covers, c1s
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

*/
