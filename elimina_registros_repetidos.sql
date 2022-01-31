/*
titulo: elimina_registros_repetidos.sql
descripción: función plpgsql que elimina registros repetidos de la DB
según prov, dpto, codloc, frac, radio, mza, lado, orden_reco

autor: -h
fecha:2022-1-31 Lu
*/

create or replace function
indec.elimina_registros_repetidos()
    returns integer
    language plpgsql volatile
    set client_min_messages = error
as $function$

declare
  localidades record;
begin
for localidades in
  select table_schema
  from information_schema.tables
  where table_schema similar to 'e[0-9]{8}' and table_name = 'listado'
loop
  execute 'delete from ' || localidades.table_schema || '.listado
    where id not in (select min(id) from ' || localidades.table_schema || '.listado
                     group by prov, dpto, codloc, frac, radio, mza, lado, orden_reco);';
  execute 'select indec.sincro_r3(' || localidades.table_schema || ');'
end loop;

return 1;
end;
$function$
;

