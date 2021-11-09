/*
titulo: describe_segmentos_con_direcciones.sql
descripción:
crea la descripcion de un dado segmento, usando mzas, lados, y desde hasta por lados
para agregarse en el mapa del radio
no usa tabla intermedia esquema.segmendo_lado_desde_hasta_ids
REEMPLAZA A LA ANTERIOR QUE USABA TABLAS INTERMEDIAS segmentos_desde_hasta_ids
autor: -h
fecha: 2021-01-29


descripción:
https://github.com/hernan-alperin/Segmentacion-CORE/issues/52
actualiza r3 del esquema:
indec.sincro_r3_ffrr(esquema,frac,radio)
llamando a
update esquema.r3 con la salida de
describe_segmentos_con_direcciones_ffrr(esquema, frac, radio)
autor: -h
fecha: 2021-11-3

*/

DROP FUNCTION if exists indec.describe_segmentos_con_direcciones(text);
create or replace function indec.describe_segmentos_con_direcciones(esquema text)
 returns table (
 prov integer, dpto integer, codloc integer, frac integer, radio integer,
 segmento_id bigint, seg text, descripcion text, viviendas numeric
)
 language plpgsql volatile
set client_min_messages = error
as $function$
begin

return query
execute '
select * 
from "' || esquema || '".r3
order by prov::integer, dpto::integer, codloc::integer, frac::integer, radio::integer,
  segmento_id::bigint, seg::text
;';
end;
$function$
;


DROP FUNCTION if exists indec.sincro_r3_ffrr(text, integer, integer);
create or replace function indec.sincro_r3_ffrr(esquema text, _frac integer, _radio integer)
 returns integer
 language plpgsql volatile
set client_min_messages = error
as $function$
begin

---- crea la tabla si no existe con una salida nula de describe_segmentos_con_direcciones_ffrr(esquema, frac, radio)
execute '
create table if not exists "' || esquema || '".r3 as
select * 
from indec.describe_segmentos_con_direcciones_ffrr(''' || esquema || ''', 0, 0)
;';


execute '
delete from "' || esquema || '".r3
where frac::integer = ' || _frac || ' and radio::integer = ' || _radio || '
;

insert into "' || esquema || '".r3
select *
from indec.describe_segmentos_con_direcciones_ffrr(''' || esquema || ''', ' || _frac || ', ' || _radio || ')
;';

return 1;

end;
$function$
;


DROP FUNCTION if exists indec.sincro_r3(text);
create or replace function indec.sincro_r3(esquema text)
 returns integer
 language plpgsql volatile
set client_min_messages = error
as $function$

declare 
v_sql_dynamic text;
registro record;

begin
v_sql_dynamic := 'select distinct frac, radio from ' || esquema || '.listado;';

for registro in execute v_sql_dynamic loop
  execute 'select indec.sincro_r3_ffrr(''' || esquema || ''', ' || registro.frac::integer || ', ' || registro.radio::integer || ');';
end loop;

return 1;

end;
$function$
;


