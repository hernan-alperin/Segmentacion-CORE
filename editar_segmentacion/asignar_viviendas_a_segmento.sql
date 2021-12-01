/*
SELECT indec.asignar_viviendas_a_segmento('e0960', 'ARRAY [594, 595, 596]', 10006);
*/

CREATE or replace FUNCTION indec.asignar_viviendas_a_segmento(esquema text, viviendas text, segmento_id bigint) 
RETURNS VOID AS $$ 
begin
execute '
update ' || esquema || '.segmentacion 
set segmento_id = ''' || segmento_id || '''
where listado_id = any (' || viviendas || ')
';
return;
END $$ LANGUAGE plpgsql;
