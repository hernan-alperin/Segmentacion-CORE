/*
SELECT indec.asignar_viviendas_a_segmento('e0960', 'ARRAY [594, 595, 596]', 10006);
*/

drop function indec.asignar_viviendas_a_segmento(esquema text, viviendas text, segmento_id bigint);
CREATE or replace FUNCTION indec.asignar_viviendas_a_segmento(esquema text, viviendas text, segmento_id bigint) 
RETURNS integer AS $$ 
declare cuantas integer;
begin
execute '
with rows as (
  update ' || esquema || '.segmentacion 
  set segmento_id = ''' || segmento_id || '''
  where listado_id = any (' || viviendas || ')
  returning 1
  )
select count(*) from rows' into cuantas;

return cuantas;
END $$ LANGUAGE plpgsql;
