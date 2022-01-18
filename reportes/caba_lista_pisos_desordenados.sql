/*
busca pisos que estén desordenados
autor : -h
2022-01-06
*/

\timing

\o e02014010.pisos_desordenados.txt

with listado_sin_nulos as (
    select id, prov, dpto, codloc, frac, radio, mza, lado, nrocatastr,
    coalesce(sector,'') sector, coalesce(edificio,'') edificio, coalesce(entrada,'') entrada, piso as cpiso,
    case when coalesce(piso, '') = '' or upper(piso) = 'PB' then 0 else piso::integer end piso, dpto_habit,
    coalesce(CASE WHEN orden_reco='' THEN NULL ELSE orden_reco END,'0')::integer orden_reco
    from e02014010.listado)
select i.id, frac as ff, radio as rr, mza, lado, nrocatastr as nro, 
--sector, edificio, entrada, 
  i.cpiso as piso, i.orden_reco as orden, 
  array_agg(j.cpiso order by j.orden_reco) as pisos, array_agg(j.orden_reco order by j.orden_reco) as desordenados
from listado_sin_nulos i
join listado_sin_nulos j
using (prov, dpto, codloc, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada)
where i.piso < j.piso and i.orden_reco <= j.orden_reco
--or i.piso = j.piso and i.dpto_habit > j.dpto_habit and i.orden_reco <= j.orden_reco
group by i.id, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, i.cpiso, i.orden_reco
order by frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, i.cpiso desc, i.orden_reco 
;


/*

Time: 5263.465 ms (00:05.263)

*/
