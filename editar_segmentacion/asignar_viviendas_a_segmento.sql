CREATE FUNCTION indec.asignar_viviendas_a_segmento(esquema test, vivendas integer[], segmento_id bigint) RETURNS VOID AS $$ 
begin
execute '
update ' || esquema || '.segmentacion 
set segmento_id = ''' || segmento_id || '''
where listado_id = any (viviendas)
';
return
END $$ LANGUAGE plpgsql;
