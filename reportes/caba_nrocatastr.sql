/*
busca numeros catastrales que estén cruzados
autor : -h
2022-01-14
demora 45 minutos
*/

with listado_sin_nulos as (
    select id, prov, dpto, codloc, frac, radio, mza, lado, nrocatastr,
    coalesce(CASE WHEN orden_reco='' THEN NULL ELSE orden_reco END,'0')::integer orden_reco
    from e02014010.listado), -- cambiar por e02DDD010
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
 frac | radio | mza | lado | nrocatastr_i
------+-------+-----+------+--------------
(0 rows)

Time: 2655400.480 ms (44:15.400)
*/

/*
busca numeros catastrales no enteros
autor : -h
2022-01-14
*/

select '|' || nrocatastr || '|'
from e02014010.listado
where not nrocatastr ~ '^[0-9]+$'
;
/*
 ?column?
----------
(0 rows)

Time: 148.356 ms
*/


/*
busca numeros catastrales que estén pares e impares en el mismo lado
autor : -h
2022-01-14
*/

with listado_sin_nulos as (
    select id, prov, dpto, codloc, frac, radio, mza, lado, 
    coalesce(CASE WHEN orden_reco='' THEN NULL ELSE nrocatastr END,'0') nrocatastr,
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
/*
 frac | radio | mza | lado
------+-------+-----+------
(0 rows)

Time: 308.315 ms
*/


/*
busca numeros catastrales que estén pares creciendo o impares decreciendo
autor : -h
2022-01-14
*/

with listado_sin_nulos as (
    select id, prov, dpto, codloc, frac, radio, mza, lado,
    coalesce(CASE WHEN nrocatastr='' THEN NULL ELSE nrocatastr END,'0') nrocatastr,
    coalesce(CASE WHEN orden_reco='' THEN NULL ELSE orden_reco END,'0')::integer orden_reco
    from e02014010.listado),
pares_e_impares as (
    select frac, radio, mza, lado,
      i.nrocatastr::integer nrocatastr_i, j.nrocatastr::integer nrocatastr_j,
      i.orden_reco orden_i, j.orden_reco orden_j
    from listado_sin_nulos i
    join listado_sin_nulos j 
    using (prov, dpto, codloc, frac, radio, mza, lado))
select distinct frac, radio, mza, lado
from pares_e_impares
where nrocatastr_i != '0' and nrocatastr_j = '0'
and (
  nrocatastr_i % 2 = 0 and nrocatastr_j % 2 = 0 and nrocatastr_i < nrocatastr_j and orden_i < orden_j
  or 
  nrocatastr_i % 2 = 1 and nrocatastr_j % 2 = 1 and nrocatastr_i > nrocatastr_j and orden_i < orden_j
)
;

/*
 frac | radio | mza | lado
------+-------+-----+------
(0 rows)

Time: 253.422 ms
*/

