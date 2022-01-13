/*
busca y corrige pisos que estén desordenados
autor : -h
2022-01-06
*/

with listado_sin_nulos as (
    select id, prov, dpto, codloc, frac, radio, mza, lado, nrocatastr,
    coalesce(sector,'') sector, coalesce(edificio,'') edificio, coalesce(entrada,'') entrada, piso,
    case when coalesce(piso, '') = '' or upper(piso) = 'PB' then 0 else piso::integer end piso_int, dpto_habit,
    coalesce(CASE WHEN orden_reco='' THEN NULL ELSE orden_reco END,'0')::integer orden_reco
    from e02014010.listado),
desordenados as (
    select i.id as i_id, j.id as j_id, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, 
        i.piso_int as i_piso, i.orden_reco as i_orden, 
        j.piso_int as j_piso, j.orden_reco as j_orden
    from listado_sin_nulos i
    join listado_sin_nulos j
    using (prov, dpto, codloc, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada)
    where i.piso < j.piso and i.orden_reco <= j.orden_reco),
i as (
    select i_id as id, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, 
        i_piso, i_orden, min(j_orden) as min_j_orden
    from desordenados
    group by i_id, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, 
        i_piso, i_orden),
j as (
    select j_id as id, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, 
        j_piso, j_orden
    from desordenados)    
select listado_sin_nulos.*, 
    case 
        when orden_reco = i_orden then min_j_orden
        when orden_reco = j_orden then j_orden + 1
        else orden_reco
    end as orden_reco_corregido
from listado_sin_nulos
join i using (id)
join j using (id)
;


/*
 ...

*/

