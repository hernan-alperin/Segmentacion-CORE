/*
titulo: descripcion_segmentos.sql
descripción: 
crea la descripcion de las segmentos en mzas, lados
para agregarse en el mapa del radio

proceso posterior a la segmentación por lado completo
autor: -h
fecha: 2/5/2020

ejemplo:
 ppdddlllffrr | prov | depto | codloc | frac | radio | segmento | seg |                                                                         
                               descripcion                                                                                                      
   
--------------+------+-------+--------+------+-------+----------+-----+-------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------
---
 380280400401 | 38   | 028   | 040    | 04   | 01    | 01       |   1 | manzana 001 completa, manzana 004 completa
 380280400401 | 38   | 028   | 040    | 04   | 01    | 02       |   2 | manzana 002 completa, manzana 021 completa, manzana 022 completa
 380280400401 | 38   | 028   | 040    | 04   | 01    | 03       |   3 | manzana 003 completa
.
.
.
 380280400403 | 38   | 028   | 040    | 04   | 03    | 01       |   1 | manzana 001 completa, manzana 002 lados 6 7 8 9, manzana 005 lados 3 4, 
manzana 006 completa, manzana 018 lados 2 3, manzana 901 completa, manzana 902 completa, manzana 903 completa
 380280400403 | 38   | 028   | 040    | 04   | 03    | 02       |   2 | manzana 002 lado 1, manzana 019 completa
 380280400403 | 38   | 028   | 040    | 04   | 03    | 03       |   3 | manzana 002 lados 2 3 4, manzana 003 completa, manzana 004 lados 1 2 3, 
manzana 008 lado 4, manzana 010 lados 4 1 2
 380280400403 | 38   | 028   | 040    | 04   | 03    | 04       |   4 | manzana 002 lado 5, manzana 004 lado 4
 380280400403 | 38   | 028   | 040    | 04   | 03    | 05       |   5 | manzana 005 lados 1 2, manzana 007 lado 4
 380280400403 | 38   | 028   | 040    | 04   | 03    | 06       |   6 | manzana 007 lado 1, manzana 008 lados 2 3
.
.
.
*/

create or replace function indec.descripcion_segmentos(aglomerado text)
 returns integer
 language plpgsql volatile
set client_min_messages = error
as $function$

begin
execute 'drop view if exists "' || aglomerado || '".descripcion_segmentos;';

execute '
create view "' || aglomerado || '".descripcion_segmentos as 
with 
e00 as (
    select * from
    -------------------- cobertura-------------------------
    "' || aglomerado || '".arc
    -------------------------------------------------------
    ),
seg_mza_lados as (
    select substr(mzai,1,12) as ppdddlllffrr, 
    segi as seg, substr(mzai,13,3) as mza, ladoi as lado
    from e00
    where mzai is not Null and mzai != '''' and ladoi != 0
    union
    select substr(mzad,1,12) as ppdddlllffrr,
    segd as seg, substr(mzad,13,3) as mza, ladod as lado
    from e00
    where mzad is not Null and mzad != '''' and ladod != 0
    ),
lados_por_mza as (
  select ppdddlllffrr, mza, count(*) as cant_lados
  from seg_mza_lados
  group by ppdddlllffrr, mza
  ),
mzas_en_segmentos as (
  select ppdddlllffrr, mza, seg, count(*) as cant_lados_en_seg
  from seg_mza_lados
  group by ppdddlllffrr, mza, seg
  ),
mzas_completas as (
  select *
  from mzas_en_segmentos
  natural join
  lados_por_mza
  where cant_lados = cant_lados_en_seg
  ),
lados_de_mzas_incompletas as (
  select ppdddlllffrr, seg, mza, lado, lado::integer as i
  from seg_mza_lados
  where (ppdddlllffrr, seg, mza) not in (
    select ppdddlllffrr, seg, mza
    from mzas_completas
    )
  ),
serie as (
  select ppdddlllffrr, seg, mza, generate_series(1, cant_lados) as i
  from lados_de_mzas_incompletas
  natural join lados_por_mza
  group by ppdddlllffrr, seg, mza, cant_lados
  ),
junta as (
  select *
  from lados_de_mzas_incompletas
  natural full join
  serie   
  ),
no_estan as (
  select ppdddlllffrr, seg, mza,
    max(i) as max_no_esta, min(i) as min_no_esta
  from junta
  where lado is Null
  group by ppdddlllffrr, seg, mza, lado
  ),
lados_ordenados as (
  select ppdddlllffrr, seg, mza, lado, 
  case
  when lado::integer > max_no_esta then lado::integer - max_no_esta -- el hueco está abajo
  when min_no_esta > lado::integer then cant_lados - max_no_esta + lado::integer -- el hueco está arriba
  when min_no_esta = 1 and max_no_esta = cant_lados then lado::integer -- hay hueco a ambos lados, no empieza en 1 
  end
  as orden
  from no_estan
  natural join
  lados_de_mzas_incompletas
  natural join
  lados_por_mza
  natural join
  mzas_en_segmentos),
descripcion_mza as (
  select ppdddlllffrr, seg, ''manzana ''||mza||'' completa'' as descripcion
  from mzas_completas
  union
  select ppdddlllffrr, seg,
    ''manzana ''||mza||'' ''|| replace(replace(replace(array_agg(lado order by orden)::text, ''{'',
      case
        when cardinality(array_agg(lado)) = 1 then ''lado ''
        else ''lados '' end
                                                  ), ''}'',''''), '','', '', '')
    as descripcion
  from lados_ordenados
  group by ppdddlllffrr, seg, mza
  order by ppdddlllffrr, seg, descripcion
  )
select ppdddlllffrr || lpad(seg::text,2,''0'') as link, 
       substr(ppdddlllffrr,1,2)::char(2) as prov, substr(ppdddlllffrr,3,3)::char(3) as depto, 
       substr(ppdddlllffrr,6,3)::char(3) as codloc, 
       substr(ppdddlllffrr,9,2)::char(2) as frac, substr(ppdddlllffrr,11,2)::char(2) as radio, 
       lpad(seg::text,2,''0'') as segmento, seg,
    string_agg(descripcion,''; '') as descripcion
from descripcion_mza
group by ppdddlllffrr, seg
order by ppdddlllffrr, seg
';

return 1;
end;
$function$
;
----------------------------------------





