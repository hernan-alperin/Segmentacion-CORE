/*
titulo: describe_sin_muestreo_ffrr.sql
descripción:
crea la descripcion de un dado segmento, usando mzas, lados, y desde hasta por lados
para agregarse en el mapa del radio
SÓLO para un SOLO radio
SÓLO sirve si no hay muestreo LACALIDAD de menos de 50 mil
no usa tabla intermedia esquema.segmendo_lado_desde_hasta_ids
autor: -h
fecha: 2021-01-29

*/

DROP FUNCTION if exists indec.describe_sin_muestreo_ffrr(text, integer, integer);
create or replace function indec.describe_sin_muestreo_ffrr(esquema text, _frac integer, _radio integer)
 returns table (
 prov integer, dpto integer, codloc integer, frac integer, radio integer,
 segmento_id bigint, seg text, descripcion text, viviendas numeric
)
 language plpgsql volatile
set client_min_messages = error
as $function$
declare sql text;

begin

sql = '
with
  listado as ( select id, prov, dpto, codloc, frac, radio, mza, lado,
    coalesce(CASE WHEN orden_reco='''' THEN NULL ELSE orden_reco END,''0'')::integer orden_reco,
    tipoviv, sector, edificio, entrada, piso
  from "' || esquema || '".listado where frac::integer = ' || _frac || ' and radio::integer = ' || _radio || '
  ),
  segmentacion as ( select * from "' || esquema || '".segmentacion),
  segmentos_row_number as (
  select prov, dpto, codloc, frac, radio, segmento_id, mza::integer as mza, lado::integer lado, 
    orden_reco::integer orden_reco, sector, edificio, entrada,
    REGEXP_REPLACE(COALESCE(piso::character varying, ''0''), ''[^0-9]*'' ,''0'')::integer as piso,
    row_number () over (
      partition by prov, dpto, codloc, frac, radio, segmento_id
      order by mza::integer, lado::integer, orden_reco::integer, sector, edificio, entrada,
      REGEXP_REPLACE(COALESCE(piso::character varying, ''0''), ''[^0-9]*'' ,''0'')::integer desc
      ) as rnk
  from listado
  join segmentacion
  on listado_id = listado.id
  group by prov, dpto, codloc, frac, radio, segmento_id, mza, lado, orden_reco, sector, edificio, entrada, piso
  ),
etiquetas as (
  select segmento_id, rank() over w as seg
  from segmentos_row_number
  where rnk = 1
  window w as (
    partition by prov, dpto, codloc, frac, radio
    order by mza, lado, orden_reco, sector, edificio, entrada, piso desc
    )
  ),

lados_desde_hasta as ( -- desde hasta por lado
  select prov, dpto, codloc, frac, radio, mza, lado,
    min(listado.orden_reco) as lado_desde, max(listado.orden_reco) as lado_hasta
  from listado
  group by prov, dpto, codloc, frac, radio, mza, lado
  ),
segmentos_lados_desde_hasta as ( -- desde hasta lado por segmento
  select prov, dpto, codloc, frac, radio, mza, lado, segmento_id,
    min(listado.orden_reco) as seg_lado_desde, max(listado.orden_reco) as seg_lado_hasta,
    (min(listado.orden_reco) = lado_desde and max(listado.orden_reco) = lado_hasta) as completo,
    count(indec.contar_vivienda(tipoviv)) as viviendas
  from listado join segmentacion on listado.id = listado_id
  join lados_desde_hasta
  using (prov, dpto, codloc, frac, radio, mza, lado)
  group by prov, dpto, codloc, frac, radio, mza, lado, segmento_id, lado_desde, lado_hasta
  ),
segmentos_lados_desde_hasta_ids as (
  select prov, dpto, codloc, frac, radio, mza, lado, segmento_id, 
    desde_id, hasta_id, seg_lado_desde, seg_lado_hasta,
    completo, viviendas
  from (
    select l.prov, l.dpto, l.codloc, l.frac, l.radio, l.mza, l.lado, s.segmento_id, l.id as desde_id,
    seg_lado_desde, viviendas, completo
    from segmentos_lados_desde_hasta s
    join listado l on s.prov = l.prov and s.dpto = l.dpto and s.codloc = l.codloc
    and s.frac = l.frac and s.radio = l.radio and s.mza = l.mza and s.lado = l.lado
    and seg_lado_desde = orden_reco
    ) as desdes
    natural join (
    select l.prov, l.dpto, l.codloc, l.frac, l.radio, l.mza, l.lado, s.segmento_id, l.id as hasta_id,
    seg_lado_hasta, viviendas, completo
    from segmentos_lados_desde_hasta s
    join listado l on s.prov = l.prov and s.dpto = l.dpto and s.codloc = l.codloc
    and s.frac = l.frac and s.radio = l.radio and s.mza = l.mza and s.lado = l.lado
    and seg_lado_hasta = orden_reco
    ) as hastas
  ),
--------------
-- ordenar los lados como está hecho en descripcion_segmentos.sql
lados_por_mza as (select prov, dpto, codloc, frac, radio, mza, count(*) as cant_lados
  from segmentos_lados_desde_hasta_ids
  group by prov, dpto, codloc, frac, radio, mza
  ),
lados_de_mzas_inc as (select prov, dpto, codloc, segmento_id, mza, lado, lado::integer as i
  from segmentos_lados_desde_hasta_ids
  ),
serie as (select segmento_id, mza, generate_series(1, cant_lados)::integer as i
  from lados_de_mzas_inc
  natural join lados_por_mza
  group by prov, dpto, codloc, segmento_id, mza, cant_lados
  ),
junta as (select * from lados_de_mzas_inc natural full join serie),
no_estan as (select segmento_id, mza,
    max(i) as max_no_esta, min(i) as min_no_esta
  from junta
  where lado is Null
  group by segmento_id, mza, lado
  ),
lados_ordenados_inc as (
  select segmento_id, mza, lado,
  case
  when lado::integer > max_no_esta then lado::integer - max_no_esta -- el hueco está abajo
  when min_no_esta > lado::integer then cant_lados - max_no_esta + lado::integer -- el hueco está arriba
  when min_no_esta = 1 and max_no_esta = cant_lados then lado::integer -- hay hueco a ambos lados, no empieza en 1
  end
  as orden
  from no_estan
  natural join
  lados_de_mzas_inc
  natural join
  lados_por_mza),
lados_ordenados_comp as (
  select segmento_id, mza, lado, lado as orden
  from segmentos_lados_desde_hasta_ids
  where indec.manzana_completa_ffrr(''' || esquema || '''::text, frac::integer, radio::integer, mza::integer)
  group by segmento_id, mza, lado
  ),
lados_ordenados as (
 select segmento_id::bigint, mza::integer, lado::integer, orden::integer from lados_ordenados_inc
 union
 select segmento_id::bigint, mza::integer, lado::integer, orden::integer from lados_ordenados_comp
 ),
--------------

segmentos_descripcion_lado as (
  select prov, dpto, codloc, frac, radio, mza::integer, lado::integer, segmento_id::bigint,
    desde_id, hasta_id, completo,
    concat(''Lado '', lpad(lado::integer::text, 2, ''0''),
      case when completo then '' completo '' else '' '' end,
    indec.descripcion_calle_desde_hasta(''' || esquema || ''', desde_id, hasta_id, completo)::text) as descripcion,
    viviendas
  from segmentos_lados_desde_hasta_ids
  ),
segmentos_descripcion_mza as (
  select prov::integer, dpto::integer, codloc::integer, frac::integer, radio::integer,
    mza::integer, segmento_id::bigint,
    string_agg(descripcion, '', '' order by orden) as descripcion,
    sum(viviendas) as viviendas
  from segmentos_descripcion_lado
  natural join lados_ordenados
  group by prov::integer, dpto::integer, codloc::integer, frac::integer, radio::integer,
    mza::integer, segmento_id::bigint
  ),
hay_colectivas as (
  select prov::integer, dpto::integer, codloc::integer, frac::integer, radio::integer
  from listado
  where tipoviv = ''CO''
  group by prov::integer, dpto::integer, codloc::integer, frac::integer, radio::integer
  limit 1
  )

select prov::integer, dpto::integer, codloc::integer, frac::integer, radio::integer,
  segmento_id::bigint, lpad(seg::text, 2, ''0'') as seg,
  concat(string_agg(concat(''Manzana '',
   lpad(mza::integer::text, 3, ''0''),
    case when indec.manzana_completa_ffrr(''' || esquema || '''::text, frac::integer, radio::integer, mza::integer)
         then '' completa''
         else concat('': '', descripcion)
    end
    ), ''. '' order by mza),
  indec.excluye_colectivas(''' || esquema || ''', segmento_id)) as descripcion,
  sum(viviendas) as viviendas
from segmentos_descripcion_mza
join etiquetas 
using (segmento_id)
group by prov::integer, dpto::integer, codloc::integer, frac::integer, radio::integer,
  segmento_id::bigint, seg::integer, seg::text
union
select
   prov::integer, dpto::integer, codloc::integer, frac::integer, radio::integer,
   Null::bigint, ''90'' as seg, ''Viviendas colectivas'' as descripcion, Null as viviendas
from hay_colectivas
order by seg
;';


return query 
execute sql;

end;
$function$
;


