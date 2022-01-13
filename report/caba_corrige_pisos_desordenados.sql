/*
busca y corrige pisos que estén desordenados
autor : -h
2022-01-13
*/

with listado_sin_nulos as (
    select id, prov, dpto, codloc, frac, radio, mza, lado, nrocatastr,
    coalesce(sector,'') sector, coalesce(edificio,'') edificio, coalesce(entrada,'') entrada, piso,
    case when coalesce(piso, '') = '' or upper(piso) = 'PB' then 0 else piso::integer end piso_int, dpto_habit,
    coalesce(CASE WHEN orden_reco='' THEN NULL ELSE orden_reco END,'0')::integer orden_reco
    from e0002.listado),
desordenados as (
    select frac, radio, mza, lado, nrocatastr, sector, edificio, entrada
    from listado_sin_nulos i
    join listado_sin_nulos j
    using (prov, dpto, codloc, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada)
    where i.piso < j.piso and i.orden_reco <= j.orden_reco),
edificios_desordenados as (
    select frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, 
        min(orden_reco) as min_orden, max(orden_reco) as max_orden, count(*) as cant
    from desordenados
    join listado_sin_nulos
    using (frac, radio, mza, lado, nrocatastr, sector, edificio, entrada)
    group by frac, radio, mza, lado, nrocatastr, sector, edificio, entrada)
select listado.*, 
    case
        when cant = max_orden - min_orden - 1 then 
            row_number() 
            over (partition by prov, dpto, codloc, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada 
                  order by piso desc, dpto_habit) + min_orden - 1
        else Null
    end as orden_corregido
from e0002.listado
join edificios_desordenados
using (frac, radio, mza, lado, nrocatastr, sector, edificio, entrada)
limit 100
;


/*
 ...

*/

