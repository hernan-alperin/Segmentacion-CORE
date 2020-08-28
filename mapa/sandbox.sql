select id, frac, radio, mza, clado, ccalle, ncalle, nrocatastr, edificio, piso, orden_reco, s_id
from e0002.listado_segmentado 
where ccalle not like '0999%'
and nrocatastr != '0'
;




