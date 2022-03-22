/*
function de CORE
2da de enero 2020 
*/

CREATE OR REPLACE FUNCTION indec.generar_adyacencias(aglomerado text)
 RETURNS integer
 LANGUAGE plpgsql volatile
SET client_min_messages = notice
AS $function$
declare
n int;
consulta text;
begin

consulta := 'drop table if exists "' || aglomerado || '".lados_adyacentes cascade;';
execute consulta;
RAISE NOTICE 'Consulta %', consulta;

consulta := '
create table "' || aglomerado || '".lados_adyacentes as 

with 

arcos as (select * from "' || aglomerado || '".arc),

pedacitos_de_lado as (-- mza como PPDDDLLLFFRRMMM select mzad as mza, ladod as lado, avg(anchomed) as anchomed,
    select mzad as mza, ladod as lado,
        array_agg(distinct tipo) as tipos,
        array_agg(distinct codigo20) as codigos,
        array_agg(distinct nombre) as calles,
        ST_Union(wkb_geometry) as geom_pedacito -- ST_Union por ser MultiLineString
    from arcos
    where mzad is not Null and mzad != '''' and ladod != 0
    group by mzad, ladod
    union -- duplica los pedazos de lados a derecha e izquierda
    select mzai as mza, ladoi as lado,
        array_agg(distinct tipo) as tipos,
        array_agg(distinct codigo20) as codigos,
        array_agg(distinct nombre) as calles,
        ST_Union(ST_Reverse(wkb_geometry)) as geom_pedacito -- invierte los de mzai
        -- para respetar sentido hombro derecho
    from arcos
    where mzai is not Null and mzai != '''' and ladoi != 0
    group by mzai, ladoi
    ),
lados_orientados as (
    select mza as ppdddlllffrrmmm,
        substr(mza,1,2)::integer as prov, substr(mza,3,3)::integer as dpto,
        substr(mza,6,3)::integer as codloc,
        substr(mza,9,2)::integer as frac, substr(mza,11,2)::integer as radio,
        substr(mza,13,3)::integer as mza, lado,
        tipos, codigos, calles,
        ST_LineMerge(ST_Union(geom_pedacito)) as wkb_geometry -- une por mza,lado
    from pedacitos_de_lado
    group by mza, lado, tipos, codigos, calles
    ),
lados_de_manzana as (
    select row_number() over() as id, *,
        ST_StartPoint(wkb_geometry) as nodo_i_geom, ST_EndPoint(wkb_geometry) as nodo_j_geom
    from lados_orientados

    ),

---- que se puede hacer al llegar a la esquina

max_lado as (
    select ppdddlllffrrmmm, max(lado) as max_lado
    from lados_de_manzana
    group by ppdddlllffrrmmm
    ),
doblando as (
    select ppdddlllffrrmmm,
        lado as de_lado,
        case when lado < max_lado then lado + 1 else 1 end as lado
        -- lado el lado que dobla de la misma mza
    from max_lado
    join lados_de_manzana l
    using (ppdddlllffrrmmm)
    where lado != 0
    ),
lado_para_doblar as (
    select distinct ppdddlllffrrmmm as mza_i, de_lado as lado_i,
        ppdddlllffrrmmm as mza_j, a.lado as lado_j,
        Null::text as arc_tipo, Null::integer as arc_codigo
    from doblando d
    join lados_de_manzana a
    using(ppdddlllffrrmmm, lado)
    ),

--  adyacencias entre manzanas ------------------------------------
--  para calcular los lados de cruzar y volver

manzanas_adyacentes as (
    select distinct mzad as mza_i, mzai as mza_j, tipo as arc_tipo, codigo20 as arc_codigo
    -- agrega tipo y codigo para calcular costo de pasar a mza adyacente
    from arcos
    where substr(mzad,1,12) = substr(mzai,1,12) -- mismo PPDDDLLLFFRR
        and mzad is not Null and mzad != '''' and ladod != 0
        and mzai is not Null and mzai != '''' and ladod != 0
        and mzai != mzad
    union -- hacer simétrica
    select mzai as mza_i, mzad as mza_j, tipo as arc_tipo, codigo20 as arc_codigo
    from arcos
    where substr(mzad,1,12) = substr(mzai,1,12) -- mismo PPDDDLLLFFRR
        and mzad is not Null and mzad != '''' and ladod != 0
        and mzai is not Null and mzai != '''' and ladod != 0
        and mzad != mzai
    ),

---- "volver" en realidad es que está en frente -------------------
---- fin(lado_i) = inicio(lado_j),
---- mza_i ady mza_j, y
---- la intersección es 1 linea

lado_de_enfrente as (
    select distinct i.ppdddlllffrrmmm as mza_i, i.lado as lado_i,
        j.ppdddlllffrrmmm as mza_j, j.lado as lado_j,
        a.arc_tipo, a.arc_codigo
    from lados_de_manzana i
    join lados_de_manzana j
    on i.codigos = j.codigos -- presume mismo eje xq comparten codigo20
    and i.nodo_j_geom = j.nodo_i_geom -- el lado_i termina donde el lado_j empieza
    -- los lados van de nodo_i a nodo_j
    join manzanas_adyacentes a
    on i.ppdddlllffrrmmm = a.mza_i and j.ppdddlllffrrmmm = a.mza_j -- las manzanas son adyacentes
    and a.arc_codigo = any(j.codigos) -- mismo eje
    where ST_Dimension(ST_Intersection(i.wkb_geometry,j.wkb_geometry)) = 1
    ),

mza_enfrente as (
    select distinct mzai as mza_i, ladoi as lado_i,
        mzad as mza_j, ladod as lado_j,
        tipo as arc_tipo, codigo20 as arc_codigo
    from arcos
    where length(trim(mzai)) >= 15
    and length(trim(mzad)) >= 15
    and mzai != mzad
    and (mzai, mzad) not in (
      select mza_i, mza_j from lado_de_enfrente
      union
      select mza_j, mza_i from lado_de_enfrente
      )
    ),

---- cruzar -----------------------------------------------------------
---- fin(lado_i) = inicio(lado_j),
---- mza_i ady mza_j, y
---- la intersección es 1 punto

lado_para_cruzar as (
    select distinct i.ppdddlllffrrmmm as mza_i, i.lado as lado_i,
        j.ppdddlllffrrmmm as mza_j, j.lado as lado_j,
        a.arc_tipo, a.arc_codigo
    from lados_de_manzana i
    join lados_de_manzana j
    on i.nodo_j_geom = j.nodo_i_geom
    -- el lado_i termina donde el lado_j empieza
    -- los lados van de nodo_i a nodo_j
    and i.codigos = j.codigos -- mismo eje
    join manzanas_adyacentes a
    on i.ppdddlllffrrmmm = a.mza_i and j.ppdddlllffrrmmm = a.mza_j
    -- las manzanas son adyacentes
    and a.arc_codigo = any(j.codigos) -- mismo eje
    where ST_Dimension(ST_Intersection(i.wkb_geometry,j.wkb_geometry)) = 0
    )

select mza_i, lado_i::integer, mza_j, lado_j::integer, arc_tipo, arc_codigo::integer, ''dobla''::text as tipo from lado_para_doblar
union
select mza_i, lado_i::integer, mza_j, lado_j::integer, arc_tipo, arc_codigo::integer, ''enfrente''::text from lado_de_enfrente
union
select mza_i, lado_i::integer, mza_j, lado_j::integer, arc_tipo, arc_codigo::integer, ''mza_enfrente''::text from mza_enfrente
union
select mza_i, lado_i::integer, mza_j, lado_j::integer, arc_tipo, arc_codigo::integer, ''cruza''::text from lado_para_cruzar
;'
;
execute consulta;
RAISE NOTICE 'Consulta %', consulta;

-----------------------------------------------------------------------

consulta := '
delete
from segmentacion.adyacencias
where shape = ''' || aglomerado || '''
;'
;
execute consulta;
RAISE NOTICE 'Consulta %', consulta;

consulta := '
insert into segmentacion.adyacencias (shape, prov, dpto, codloc, frac, radio, mza, lado, mza_ady, lado_ady, tipo)
select ''' || aglomerado || '''::text as shape, substr(mza_i,1,2)::integer as prov,
    substr(mza_i,3,3)::integer as dpto,
    substr(mza_i,6,3)::integer as codloc,
    substr(mza_i,9,2)::integer as frac,
    substr(mza_i,11,2)::integer as radio,
    substr(mza_i,13,3)::integer as mza, lado_i,
    substr(mza_j,13,3)::integer as mza_ady, lado_j as lado_ady,
    tipo
from "' || aglomerado || '".lados_adyacentes;
;'
;
execute consulta;
RAISE NOTICE 'Consulta %', consulta;
get diagnostics n = row_count;
return n;
end;
$function$
;
----------------------------------------


