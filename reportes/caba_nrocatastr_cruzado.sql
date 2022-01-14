/*
busca numeros catastrales que estén cruzados
autor : -h
2022-01-14
demora 45 minutos
*/

with listado_sin_nulos as (
    select id, prov, dpto, codloc, frac, radio, mza, lado, nrocatastr,
    coalesce(CASE WHEN orden_reco='' THEN NULL ELSE orden_reco END,'0')::integer orden_reco
    from e02014010.listado),
cruzados as (
    select frac, radio, mza, lado, 
      i.nrocatastr nrocatastr_i, j.nrocatastr nrocatastr_j, k.nrocatastr nrocatastr_k,
      i.orden_reco, j.orden_reco, k.orden_reco
    from listado_sin_nulos i
    join listado_sin_nulos j
    using (prov, dpto, codloc, frac, radio, mza, lado)
    join listado_sin_nulos k
    using (prov, dpto, codloc, frac, radio, mza, lado)
    where i.orden_reco <= j.orden_reco and j.orden_reco <= k.orden_reco 
      and not (j.nrocatastr between i.nrocatastr and k.nrocatastr or j.nrocatastr between k.nrocatastr and i.nrocatastr)
      and not (i.nrocatastr = '0' or j.nrocatastr = '0' or k.nrocatastr = '0'))
select distinct frac, radio, mza, lado, nrocatastr_i
from cruzados
;


/*
busca numeros catastrales que estén pares e impares en el mismo lado
autor : -h
2022-01-14
*/

with listado_sin_nulos as (
    select id, prov, dpto, codloc, frac, radio, mza, lado, nrocatastr,
    coalesce(CASE WHEN orden_reco='' THEN NULL ELSE orden_reco END,'0')::integer orden_reco
    from e02014010.listado),
pares_e_impares as (
    select frac, radio, mza, lado,
      i.nrocatastr::integer nrocatastr_i, j.nrocatastr::integer nrocatastr_j
    from listado_sin_nulos i
    join listado_sin_nulos j
    using (prov, dpto, codloc, frac, radio, mza, lado))
select distinct frac, radio, mza, lado
from pares_e_impares
where nrocatastr_i != 0 and nrocatastr_j = 0
and nrocatastr_i % 2 = 0 and nrocatastr_j % 2 = 1
;


