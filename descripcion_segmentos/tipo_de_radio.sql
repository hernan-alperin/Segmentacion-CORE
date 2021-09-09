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


DROP FUNCTION if exists indec.etiqueta(text, integer, integer, integer);
create or replace function indec.etiqueta(esquema text, _frac integer, _radio integer, _rank integer)
 returns char(2)
 language plpgsql volatile
set client_min_messages = error
as $function$

declare 
loc_rank integer;
etiqueta char(2);

begin

/*


with etiquetas as (
    select generate_series(80,89) as etiqueta
    )
select etiqueta, etiqueta - 79 as orden
from etiquetas
union
select etiqueta - 10, etiqueta - 69 as orden
from etiquetas
union
select etiqueta + 11, etiqueta - 59 as orden
from etiquetas
where etiqueta + 11 < 100
order by orden
;


*/

execute '
with listado as (
    select distinct prov, dpto, codloc, frac, radio
    from "' || esquema || '".listado
  ),
radios_mixtos as (
    select distinct radio.codigo as radio, localidad.codigo as codloc, localidad.nombre
    from radio
    join tipo_de_radio
    on tipo_de_radio_id = tipo_de_radio.id
    join radio_localidad
    on radio_id = radio.id
    join localidad
    on localidad_id = localidad.id
    where tipo_de_radio.nombre = ''M''
    ),
    multiples as (
    select radio, count(*)
    from radios_mixtos
    group by radio
    having count(*) > 1
    )
radio_localidad_rank as (
    select radio cod_radio, localidad, rank() over (partition by radio order by codloc)
    from radios_mixtos
    natural join multiples
select rank
from radio_localidad_rank
join listado
on substr(cod_radio,1,2)::integer = prov::integer and substr(cod_radio,3,3)::integer = dpto
and subtrs(codloc,6,3)::integer = codloc 
and substr(cod_radio,6,2)::integer = frac and and substr(cod_radio,8,2)::integer = listado.radio
;' into loc_rank;

if (loc_rank is Null) then
    etiqueta = lpad(_rank, 2, '0');
elseif (loc_rank = 1) then
    etiqueta = (_rank + 80 - 1)::text;
else if (loc_rank = 2) then
    etiqueta = (_rank + 70 - 1)::text;
else if (loc_rank = 3) then
    etiqueta = (_rank + 90)::text;
else if (loc_rank = 4) then
    etiqueta = (_rank + 95)::text;
else 
    etiqueta = 'XX'
end if;
 
return etiqueta;

end;
$function$
;




*/
