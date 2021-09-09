/*
titulo: tipo_de_radio.sql
descripción:
devuelve 'U', 'R' o 'M' si el radio es urbano, rural o mixto respect.
autor: -h
fecha: 2021-09-09
*/

DROP FUNCTION if exists indec.tipo_de_radio(text, integer, integer);
create or replace function indec.tipo_de_radio(esquema text, _frac integer, _radio integer)
 returns char(1)
 language plpgsql volatile
set client_min_messages = error
as $function$

declare tipo_de_radio char(1);

begin

execute '
with
  prov_dpto as (
    select distinct prov, dpto
    from "' || esquema || '".listado 
  ) 

select distinct tipo_de_radio.nombre
  from radio
  join tipo_de_radio
  on tipo_de_radio_id = tipo_de_radio.id
  join prov_dpto
  on substr(radio.codigo,1,2)::integer = prov_dpto.prov::integer 
    and substr(radio.codigo,3,3)::integer = prov_dpto.dpto::integer
  where substr(radio.codigo,6,2)::integer = ' || _frac || ' and substr(radio.codigo,8,2)::integer = ' || _radio || '
  limit 1
;' into tipo_de_radio;

return tipo_de_radio;

end;
$function$
;


