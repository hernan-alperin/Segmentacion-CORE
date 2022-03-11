/*
titulo: segmentos_excedidos.sql
descripción: función que devuelve una lista de los segmentos excedidos en el radio
autor: -h
fecha:2020-11
*/

drop function if exists indec.segmentos_excedidos(esquema text, umbral integer);
create or replace function
indec.segmentos_excedidos(esquema text, umbral integer)
    returns table (segmento_id bigint)
    language plpgsql volatile
    set client_min_messages = error
as $function$

begin

return query
execute '
select segmento_id::bigint
from "' || esquema || '".listado
join "' || esquema || '".segmentacion
on listado_id = listado.id
group by segmento_id
having count(indec.contar_vivienda(tipoviv)) > ' || umbral || '
;';
end;
$function$
;

drop function if exists indec.segmentos_excedidos_ffrr(esquema text, ff integer, rr integer, umbral integer);
create or replace function
indec.segmentos_excedidos_ffrr(esquema text, ff integer, rr integer, umbral integer)
    returns table (segmento_id bigint, cantidad bigint)
    language plpgsql volatile
    set client_min_messages = error
as $function$

begin

return query
execute '
select segmento_id::bigint, count(indec.contar_vivienda(tipoviv)) cantidad
from "' || esquema || '".listado
join "' || esquema || '".segmentacion
on listado_id = listado.id
where frac::integer = ' || ff || ' and radio::integer = ' || rr || '
group by segmento_id
having count(indec.contar_vivienda(tipoviv)) > ' || umbral || '
;';
end;
$function$
;


create or replace function
indec.segmentar_excedidos_ffrr(esquema text, ff integer, rr integer, umbral integer, deseado integer)
    returns integer
    language plpgsql volatile
    set client_min_messages = notice
as $function$
declare
  excedidos record;
  segmentar_equilibrados_sql character varying;
  myquery_result character varying;
begin
 RAISE NOTICE 'Segmentar Excedidos FF RR';
for excedidos in
  select segmento_id, cantidad from indec.segmentos_excedidos_ffrr(esquema, ff, rr, umbral)
loop
  segmentar_equilibrados_sql :=  'select indec.segmentar_listado_equilibrado(''' || esquema || ''', 
  ''select * from "' || esquema || '".listado
  join "' || esquema || '".segmentacion
  on listado_id = listado.id
  where segmento_id = ' || excedidos.segmento_id::text || ''', 
  '' mza::integer, lado::integer, orden_reco::integer ''::text, 
  least(' || deseado || ', ' || excedidos.cantidad || '/2))';
  execute segmentar_equilibrados_sql into myquery_result;
RAISE NOTICE 'SQL % .',segmentar_equilibrados_sql;
  
end loop;

return 1;
end;
$function$
;
