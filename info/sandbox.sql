/*
chequeos de informacion
y estructura de datos
del mapa de CABA

ver estadísticas de manzanas
formas

densidad
x lado
x manzana

manzana abierta por FFCC, etc

*/

/*
------------------------------------- densidad
select distinct prov, dpto
from e0005.listado
;
 prov | dpto
------+------
 02   | 035
(1 row)
*/

drop view comuna cascade;
create view comuna as 
select * from e0002.listado
;

--- densidad por manzana
create view radios as
select frac, radio
from comuna
group by frac, radio
;
select count(*) as total_radios
from radios
;


create view viviendas_por_mza as
select frac, radio, mza, count(indec.contar_vivienda(tipoviv))
from comuna
group by frac, radio, mza
order by frac, radio, mza
;
select count(*) as total_mzas
from viviendas_por_mza
;

create view mzas_densas as
select frac, radio, mza as mzas_densas
from viviendas_por_mza
where count >= 36
group by frac, radio, mza
;
select count(*) as total_mza_densas
from mzas_densas
;

/*
create view radios_densos as
select frac, radio, min(count)
from viviendas_por_mza
group by frac, radio
having min(count) >= 36
order by frac, radio
;


create view radio_esparzos as
select frac, radio, min(count)
from viviendas_por_mza
group by frac, radio
having max(count) < 36
order by frac, radio
;


--- densidad por lado
create view vivendas_por_lado as
select frac, radio, mza, lado, count(indec.contar_vivienda(tipoviv))
from e0005.listado
group by frac, radio, mza, lado
order by frac, radio, mza, lado
;

*/
