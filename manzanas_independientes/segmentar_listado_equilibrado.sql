/*
titulo: segmentar_listado_equilibrado.sql
descripción: implementa segmentar_equilibrado(1) sobre un listado
que se pasa como parámetro en forma de query para seleccionar

(1) segmenta en forma equilibrada sin cortar piso, balanceando la
cantidad deseada con la proporcional de viviendas por segmento
usando la cantidad de viviendas en la manzana.
El objetivo es que los segmentos se aparten lo mínimo de la cantidad deseada
y que la carga de los censistas esté lo más balanceado
autor: -h
fecha: 2020-10
*/


create or replace function
indec.segmentar_listado_equilibrado(esquema text, query text, orden_recorrido text, deseado integer)
    returns integer
    language plpgsql volatile
    set client_min_messages = notice
as $function$
declare
n int;
consulta text;
begin
RAISE NOTICE 'Segmentando listado equilibrado %',esquema;
consulta := '
with
parametros as (
    select ' || deseado || '::float as deseado),
listado as (' || query || '),
listado_sin_nulos as (
    select id, prov, dpto, codloc, frac, radio, mza, lado, 
    CASE WHEN trim(nrocatastr) in ('''',null,''S/N'',''S N'') THEN orden_reco else nrocatastr END  nrocatastr ,
    coalesce(sector,'''') sector, coalesce(edificio,'''') edificio, coalesce(entrada,'''') entrada,
     coalesce(piso,'''') piso, coalesce(CASE WHEN orden_reco='''' THEN NULL ELSE orden_reco END,''0'')::integer orden_reco,
      tipoviv

    from listado
    ),

casos as (
    select prov, dpto, codloc, frac, radio, 
           count(*) as registros,
           ceil(count(*)/deseado) as redondeado_arriba,
           greatest(1, floor(count(*)/deseado)) as redondeado_abajo
    from listado_sin_nulos, parametros
    group by prov, dpto, codloc, frac, radio, deseado
    ),

deseado_redondeado as (
    select prov, dpto, codloc, frac, radio, registros,
        case when abs(registros/redondeado_arriba - deseado)
            < abs(registros/redondeado_abajo - deseado) then redondeado_arriba
        else redondeado_abajo end as segs_x_listado
    from casos, parametros
    ),

pisos_abiertos as (
    select id, prov, dpto, codloc, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, piso, orden_reco::integer,
        row_number() over w as row, rank() over w as rank
    from listado_sin_nulos
    window w as (
        partition by prov, dpto, codloc, frac, radio
        order by ' || orden_recorrido || '
        )
    ),

asignacion_segmentos as (
    select id, prov, dpto, codloc, frac, radio, mza, lado,
        nrocatastr, sector, edificio, entrada, piso, orden_reco::integer,
        floor((rank - 1)*segs_x_listado/vivs) + 1 as sgm_listado, rank
    from deseado_redondeado
    join pisos_abiertos
    using (prov, dpto, codloc, frac, radio)
    ),

asignacion_segmentos_pisos_enteros as (
    select prov, dpto, codloc, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, piso, min(sgm_listado) as sgm_listado
    from asignacion_segmentos
    group by prov, dpto, codloc, frac, radio, mza, lado,
        nrocatastr, sector, edificio, entrada, piso
    ),

segmento_id_en_listado as (
  select id, 
    sgm_listado
  from listado_sin_nulos
  full join asignacion_segmentos_pisos_enteros
  using (prov, dpto, codloc, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, piso)
  ),
  
segmentos_id as (
    select
        nextval(''"' || esquema || '".segmentos_seq'')
        as segmento_id,
        sgm_listado
    from segmento_id_en_listado
    group by sgm_listado
    order by sgm_listado
    )

update "' || esquema || '".segmentacion sgm
set segmento_id = j.segmento_id
from (segmentos_id
join segmento_id_en_listado
using (sgm_listado)) j
where listado_id = j.id

';
execute consulta;
RAISE NOTICE 'Consulta %',consulta;
get diagnostics n = row_count;
return n;

end;
$function$
;



