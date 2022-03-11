/*
genera estadísticas de cantidad de segmentos
y radios
autor: -h
fecha: 2022-01-17 Lu
*/

DROP FUNCTION if exists indec.reporte_segmentos(esquema text);
create or replace function indec.reporte_segmentos(esquema text)
 returns table (carga bigint, freq bigint)
language plpgsql volatile
set client_min_messages = error
as $function$

begin

if (SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE  table_schema = esquema
   AND    table_name   = 'r3'))
then
  return query
  execute '
    select viviendas as carga, count(seg) as freq
    from ' || esquema || '.r3
    where seg != ''90''
    group by viviendas
    order by viviendas
  ;';
else
 return query execute 'select Null';
end if;

end;
$function$
;


DROP FUNCTION if exists indec.reporte_segmentos(prov integer);
create or replace function indec.reporte_segmentos(prov integer)
 returns table (carga bigint, freq bigint)
language plpgsql volatile
set client_min_messages = error
as $function$

declare
v_sql_dynamic text;
registro record;
localidad_freq record;

begin

create temp table provincia_freq (carga bigint); 

v_sql_dynamic := '
SELECT table_schema FROM information_schema.tables 
   WHERE  table_schema similar to ''e[0-9]{8}''
   AND    table_name   = ''r3''
   and    substr(table_schema,2,2)::integer = ' || prov || ';'
; -- saca los esquemas con localidades que ya tienen r3  

for registro in execute v_sql_dynamic loop
  execute 'select viviendas as carga 
  from ' || registro.table_schema || '.r3
  where seg != ''90'';'
  into localidad_freq;
  insert into provincia_freq values (localidad_freq.carga);
end loop;

return query
execute 'select carga, count(*) as freq 
  from provincia_freq 
  group by carga
  order by carga;';

end;
$function$
;
