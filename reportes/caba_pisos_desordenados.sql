/*
busca y corrige pisos que estén desordenados
autor : -h
2022-01-06
*/

with listado_sin_nulos as (
    select id, prov, dpto, codloc, frac, radio, mza, lado, nrocatastr,
    coalesce(sector,'') sector, coalesce(edificio,'') edificio, coalesce(entrada,'') entrada, piso as cpiso,
    case when coalesce(piso, '') = '' or upper(piso) = 'PB' then 0 else piso::integer end piso, dpto_habit,
    coalesce(CASE WHEN orden_reco='' THEN NULL ELSE orden_reco END,'0')::integer orden_reco
    from e02014010.listado),
desordenados as (
    select frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, 
        i.cpiso as i_piso, i.orden_reco as i_orden, 
        j.cpiso as j_piso, j.orden_reco as j_orden
    from listado_sin_nulos i
    join listado_sin_nulos j
    using (prov, dpto, codloc, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada)
    where i.piso < j.piso and i.orden_reco <= j.orden_reco),
i as (
    select frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, 
        i_piso, i_orden, min(j_orden) as min_j_orden
    from desordenados
    group by frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, 
        i_piso, i_orden),
j as (
    select frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, 
        j_piso, j_orden
    from desordenados)    
select listado.*, 
    case 
        when coalesce(CASE WHEN orden_reco='' THEN NULL ELSE orden_reco END,'0')::integer = i_orden then min_j_orden
        when coalesce(CASE WHEN orden_reco='' THEN NULL ELSE orden_reco END,'0')::integer = j_orden then j_orden + 1
        else coalesce(CASE WHEN orden_reco='' THEN NULL ELSE orden_reco END,'0')::integer
    end as orden_reco_corregido
from e02014010.listado
natural join i
natural join j
;


/*
 ...

*/

