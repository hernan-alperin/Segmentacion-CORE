/*
SELECT indec.asignar_viviendas_a_segmento('e0960', 'ARRAY [594, 595, 596]', 10006);
*/

drop function indec.asignar_viviendas_a_segmento(esquema text, viviendas text, segmento_id bigint);
CREATE or replace FUNCTION indec.asignar_viviendas_a_segmento(esquema text, viviendas text, segmento_id bigint) 
RETURNS integer AS $$ 
declare 
cuantas_updated integer;
cuantas_viviendas integer;
begin
execute 'select cardinality(' || viviendas || ');' into cuantas_viviendas;
execute '
update ' || esquema || '.segmentacion 
set segmento_id = ''' || segmento_id || '''
where listado_id = any (' || viviendas || ')
';
get diagnostics cuantas_updated = row_count;
if not (cuantas_updated = cuantas_viviendas) then
  RAISE EXCEPTION 'difieren la cantidad de viviendas del array (%) de las que pudo encontrar en esquema.segmentación: %.', cuantas_viviendas, cuantas_updated;
end if;
return cuantas_updated;
END $$ LANGUAGE plpgsql;
