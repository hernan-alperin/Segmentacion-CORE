/*
titulo: describe_segmentos_con_direcciones.sql
descripción:
crea la descripcion de un dado segmento, usando mzas, lados, y desde hasta por lados
para agregarse en el mapa del radio
no usa tabla intermedia esquema.segmendo_lado_desde_hasta_ids
REEMPLAZA A LA ANTERIOR QUE USABA TABLAS INTERMEDIAS segmentos_desde_hasta_ids
autor: -h
fecha: 2021-01-29

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



