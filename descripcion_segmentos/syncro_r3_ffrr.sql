/*
titulo: syncro_r3_ffrr.sql
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

create or replace function indec.segmentos_desde_hasta(esquema text)
 returns integer
 language plpgsql volatile
set client_min_messages = error
as $function$

begin




return 1;
end;
$function$
;
