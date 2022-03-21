/*
titulo: juntar_segmentos.sql
descripción:
junta segmentos de cero viviendas con el segmento contiguo de menor cantidad de viviendas
cambia el código
autor: -h
fecha: 2021-04-11 Do
*/


create or replace function
indec.juntar_segmentos(esquema text)
    returns integer
    language plpgsql volatile
    set client_min_messages = error
as $function$
declare
n int;
consulta text;
begin
RAISE NOTICE 'Juntando segmentos con cero en %', esquema;
consulta:= '
with lados_del_segmento as (
  select prov, dpto, codloc, frac, radio, mza, lado::integer as lado, segmento_id,
    prov || dpto || codloc || frac || radio || mza as ppdddcccffrrmmm
  from "' || esquema || '".segmentacion
  join "' || esquema || '".listado
  on listado_id = listado.id
  ),
  segmentos_contiguos as (
    select i.segmento_id as seg_i, j.segmento_id as seg_j
    from "' || esquema || '".lados_adyacentes a
    join lados_del_segmento i
    on a.mza_i = i.ppdddcccffrrmmm and a.lado_i = i.lado
    join lados_del_segmento j
    on a.mza_j = j.ppdddcccffrrmmm and a.lado_j = j.lado
    where i.segmento_id != j.segmento_id
  ),
  segmentos_viviendas as (
    select segmento_id, count(indec.contar_vivienda(tipoviv)) as vivs
    from "' || esquema || '".listado
    join "' || esquema || '".segmentacion
    on listado.id = segmentacion.listado_id
    group by segmento_id
  ),
  segmentos_contiguos_de_vacios_vivs as (
    select seg_i, i.vivs as vivs_i, seg_j, j.vivs as vivs_j,
      row_number () over (partition by seg_i, i.vivs order by j.vivs) as rnk
    from segmentos_contiguos
    join segmentos_viviendas i on seg_i = i.segmento_id
    join segmentos_viviendas j on seg_j = j.segmento_id
    where i.vivs = 0 and j.vivs > 0
  )

update "' || esquema || '".segmentacion
set segmento_id = seg_j
from segmentos_contiguos_de_vacios_vivs
where segmento_id = seg_i and rnk = 1
';

execute consulta;
RAISE NOTICE 'Consulta %',consulta;
get diagnostics n = row_count;
return n;
end;
$function$
;

create or replace function
indec.juntar_segmentos_ffrr(esquema text, frac integer, radio integer)
    returns integer
    language plpgsql volatile
    set client_min_messages = error
as $function$
declare
n int;
consulta text;
begin
RAISE NOTICE 'Juntando segmentos con cero en %', esquema || ' frac ' || frac::text || ' radio ' || radio::text;
consulta := '
with lados_del_segmento as (
  select prov, dpto, codloc, frac, radio, mza, lado::integer as lado, segmento_id,
    prov || dpto || codloc || frac || radio || mza as ppdddcccffrrmmm
  from "' || esquema || '".segmentacion
  join "' || esquema || '".listado
  on listado_id = listado.id
  where frac::integer = ' || frac || ' and radio::integer = ' || radio || '
  ),
  segmentos_contiguos as (
    select i.segmento_id as seg_i, j.segmento_id as seg_j
    from "' || esquema || '".lados_adyacentes a
    join lados_del_segmento i
    on a.mza_i = i.ppdddcccffrrmmm and a.lado_i = i.lado
    join lados_del_segmento j
    on a.mza_j = j.ppdddcccffrrmmm and a.lado_j = j.lado
    where i.segmento_id != j.segmento_id
  ),
  segmentos_viviendas as (
    select segmento_id, count(indec.contar_vivienda(tipoviv)) as vivs
    from "' || esquema || '".listado
    join "' || esquema || '".segmentacion
    on listado.id = segmentacion.listado_id
    group by segmento_id
  ),
  segmentos_contiguos_de_vacios_vivs as (
    select seg_i, i.vivs as vivs_i, seg_j, j.vivs as vivs_j,
      row_number () over (partition by seg_i, i.vivs order by j.vivs) as rnk
    from segmentos_contiguos
    join segmentos_viviendas i on seg_i = i.segmento_id
    join segmentos_viviendas j on seg_j = j.segmento_id
    where i.vivs = 0 and j.vivs > 0
  )

update "' || esquema || '".segmentacion
set segmento_id = seg_j
from segmentos_contiguos_de_vacios_vivs
where segmento_id = seg_i and rnk = 1
';

execute consulta;
RAISE NOTICE 'Consulta %',consulta;
get diagnostics n = row_count;
return n;
end;
$function$
;


create or replace function
indec.juntar_segmentos_con_menos_de_ffrr(esquema text, frac integer, radio integer, menos_de integer)
    returns integer
    language plpgsql volatile
    set client_min_messages = error
as $function$
declare
n int;
consulta text;
begin
RAISE NOTICE 'Juntando segmentos con menos de %', menos_de::text || ' en ' || esquema || ' frac ' || frac::text || ' radio ' || radio::text;
consulta := '
with lados_del_segmento as (
  select prov, dpto, codloc, frac, radio, mza, lado::integer as lado, segmento_id,
    prov || dpto || codloc || frac || radio || mza as ppdddcccffrrmmm
  from "' || esquema || '".segmentacion
  join "' || esquema || '".listado
  on listado_id = listado.id
  where frac::integer = ' || frac || ' and radio::integer = ' || radio || '
  ),
  segmentos_contiguos as (
    select i.segmento_id as seg_i, j.segmento_id as seg_j
    from "' || esquema || '".lados_adyacentes a
    join lados_del_segmento i
    on a.mza_i = i.ppdddcccffrrmmm and a.lado_i = i.lado
    join lados_del_segmento j
    on a.mza_j = j.ppdddcccffrrmmm and a.lado_j = j.lado
    where i.segmento_id != j.segmento_id
  ),
  segmentos_viviendas as (
    select segmento_id, count(indec.contar_vivienda(tipoviv)) as vivs
    from "' || esquema || '".listado
    join "' || esquema || '".segmentacion
    on listado.id = segmentacion.listado_id
    group by segmento_id
  ),
  segmentos_contiguos_de_vacios_vivs as (
    select seg_i, i.vivs as vivs_i, seg_j, j.vivs as vivs_j,
      row_number () over (partition by seg_i, i.vivs order by j.vivs) as rnk
    from segmentos_contiguos
    join segmentos_viviendas i on seg_i = i.segmento_id
    join segmentos_viviendas j on seg_j = j.segmento_id
    where i.vivs < ' || menos_de || ' and j.vivs > 0
  )

update "' || esquema || '".segmentacion
set segmento_id = seg_j
from segmentos_contiguos_de_vacios_vivs
where segmento_id = seg_i and rnk = 1
';

execute consulta;
RAISE NOTICE 'Consulta %',consulta;
get diagnostics n = row_count;
return n;
end;
$function$
;


