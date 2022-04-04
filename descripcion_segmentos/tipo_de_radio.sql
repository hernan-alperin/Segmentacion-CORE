/*
título: tipo_de_radio.sql
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


DROP FUNCTION if exists indec.etiqueta(text, integer, integer, bigint);
create or replace function indec.etiqueta(esquema text, _frac integer, _radio integer, _rank bigint)
 returns char(2)
 language plpgsql volatile
set client_min_messages = error
as $function$

declare 
loc_count integer;
loc_rank integer;
etiqueta char(2);
overflow boolean := false;

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

asigna etiquetas a segmentos de radios mixtos con posibles multilocalidades
(más de 1 localidad x radio, hay casos de hasta 4 localidades 
separadas geográficamente dentro de un mismo radio)
80-89 la 1ra localidad, 70-79 la 2da, 91-95 la 3ra, 96-99 la 4ta
si es una sola localidad, 80-89 los 1eros 10 segmentos, 70-79 los segundos 10
desde el 11avo al 20avo, 91-99 los últimos 9
para la 5ta localidad usa los 60's y también si la 1ra o 2da tiene más de 10
*/

execute '
with listado as (
    select distinct prov, dpto, codloc, frac, radio
    from "' || esquema || '".listado
    where prov != '''' and dpto != '''' and codloc != '''' 
    and frac::integer = ' || _frac || ' and radio::integer = ' || _radio || '
  ),
radios_mixtos as (
    select distinct radio.codigo as cod_radio, localidad.codigo as cod_loc, localidad.nombre
    from radio
    join tipo_de_radio
    on tipo_de_radio_id = tipo_de_radio.id
    join radio_localidad
    on radio_id = radio.id
    join localidad
    on localidad_id = localidad.id
    where tipo_de_radio.nombre = ''M'' and localidad.codigo not like ''%000'' 
    ),
multiples as (
    select cod_radio, count(*)
    from radios_mixtos
    group by cod_radio
    ),
radio_localidad_rank as (
    select cod_radio, cod_loc, 
    count, rank() over (partition by cod_radio order by cod_loc)
    from radios_mixtos
    join multiples
    using (cod_radio)
    )
select count, rank
from radio_localidad_rank
right join listado
on substr(cod_radio,1,2)::integer = prov::integer and substr(cod_radio,3,3)::integer = dpto::integer
and substr(cod_loc,6,3)::integer = codloc::integer
and substr(cod_radio,6,2)::integer = frac::integer and substr(cod_radio,8,2)::integer = listado.radio::integer
;' into loc_count, loc_rank;

if (loc_rank is Null) then
    etiqueta = lpad(_rank::text, 2, '0');
else 
  if (loc_count = 1) then
    if (_rank <= 10) then
      etiqueta = (_rank + 80 - 1)::text;
    elsif (_rank between 11 and 20) then
      etiqueta = (_rank + 70 - 11)::text;
    elsif (_rank between 21 and 29) then
      etiqueta = (_rank + 91 - 21)::text;
    else
      etiqueta = '-1';
    end if;
  elsif (loc_count > 1) then
    if (loc_rank = 1) then
      if (_rank <= 10) then
        etiqueta = (_rank + 80 - 1)::text;
      else
        if (loc_count < 3) then 
          etiqueta = (_rank + 80)::text;
        else 
          etiqueta = (_rank + 60 - 11)::text;
          overflow = true;
        end if;
      end if;
    elsif (loc_rank = 2) then
      if (_rank <= 10) then
        etiqueta = (_rank + 70 - 1)::text;
      elsif (not overflow) then 
        etiqueta = (_rank + 60 - 10)::text;
      else 
        etiqueta = '-3';
      end if;
    elsif (loc_rank = 3) then
      etiqueta = (_rank + 90)::text;
    elsif (loc_rank = 4) then
      etiqueta = (_rank + 95)::text;
    elsif (loc_rank = 5) then
      if (not overflow) then 
        etiqueta = (_rank + 60 - 1)::text;
      else 
        etiqueta = '-3';
      end if;
    elsif (loc_rank = 6) then
      if (not overflow) then 
        etiqueta = (_rank + 65 - 1)::text;
      else 
        etiqueta = '-3';
      end if;
    else 
      etiqueta = '-2';
    end if;
  end if;
end if;
 
return etiqueta;

end;
$function$
;




