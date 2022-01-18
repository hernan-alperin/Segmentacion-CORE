/*
reporte de avance
uso sql de Manu
cantidad de segmentaciones cerradas(*) por día
*/

with hechos_por_dia as (
  select substr(codigo,1,2) prov,date(updated_at) hecho,
  count(case when resultado is not null then 1 else null end) cant
  from radio
  where updated_at is not null
  group by 1,date(updated_at)
  )
select hoy.prov, hoy.hecho, sum(antes.cant)
from hechos_por_dia hoy
join hechos_por_dia antes
on hoy.prov = hoy.prov and antes.hecho <= hoy.hecho
group by 1,2
order by 1,2
;

