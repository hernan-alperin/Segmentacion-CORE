/*
censo2020=# \dv e0359.
                 Listado de relaciones
 Esquema |           Nombre            | Tipo  | Dueño 
---------+-----------------------------+-------+-------
 e0359   | descripcion                 | vista | alpe
 e0359   | listado_segmentos           | vista | alpe
 e0359   | listado_segmentos_agrupados | vista | mreta
(3 filas)

Descripción: genera listado de segmentos para planilla
para enviar a la Dirección (pedido de G. Mittas)
esta sí está a nombre de mreta

                Vista «e0359.listado_segmentos_agrupados»
  Columna   |     Tipo     | Modificadores | Almacenamiento | Descripción 
------------+--------------+---------------+----------------+-------------
 prov       | character(2) |               | extended       | 
 depto      | character(3) |               | extended       | 
 frac       | character(2) |               | extended       | 
 radio      | character(2) |               | extended       | 
 tiporad    | character(1) |               | extended       | 
 codloc     | character(3) |               | extended       | 
 seg        | character(2) |               | extended       | 
 cant_mzas  | bigint       |               | plain          | 
 mzas       | text         |               | extended       | 
 cant_lados | bigint       |               | plain          | 
 mza_lados  | text         |               | extended       | 
 vivs       | numeric      |               | main           | 
 final      | character(1) |               | extended       | 
Definición de vista:

Autor: mreta
fecha: Oct/Nov 2019

*/


 WITH 
  e00 AS (
         SELECT arc.codigo10, arc.nomencla, arc.codigo20,
            arc.ancho, arc.anchomed, arc.tipo, arc.nombre,
            arc.ladoi, arc.ladod,
            arc.desdei, arc.desded, arc.hastai, arc.hastad,
            arc.mzai, arc.mzad,
            arc.codloc20, arc.nomencla10,
            arc.nomenclai, arc.nomenclad,
            arc.wkb_geometry,
   ---------------------------------
            'e0359'::text AS cover,
   ---------------------------------
            arc.segi, arc.segd
   ---------------------------------
           FROM e0359.arc
   ---------------------------------
        ),
  lados_de_manzana AS (
         SELECT e00.codigo20,
            (e00.mzai::text || '-'::text) || e00.ladoi AS lado_id,
            e00.mzai AS mza, e00.ladoi AS lado,
            avg(e00.anchomed) AS anchomed,
            st_linemerge(st_union(st_reverse(e00.wkb_geometry))) AS geom,
            e00.cover,
            e00.segi AS seg
           FROM e00
          WHERE e00.mzai IS NOT NULL AND e00.mzai::text <> ''::text
          GROUP BY e00.codigo20, e00.mzai, e00.ladoi, e00.cover, e00.segi
        UNION
         SELECT e00.codigo20,
            (e00.mzad::text || '-'::text) || e00.ladod AS lado_id,
            e00.mzad AS mza, e00.ladod AS lado,
            avg(e00.anchomed) AS anchomed,
            st_linemerge(st_union(e00.wkb_geometry)) AS geom,
            e00.cover,
            e00.segd AS seg
           FROM e00
          WHERE e00.mzad IS NOT NULL AND e00.mzad::text <> ''::text
          GROUP BY e00.codigo20, e00.mzad, e00.ladod, e00.cover, e00.segd
        ), 
  lados_codigos AS (
         SELECT lados_de_manzana.codigo20,
            lados_de_manzana.lado_id,
            lados_de_manzana.mza, lados_de_manzana.lado,
            lados_de_manzana.seg,
            st_simplifyvw(st_linemerge(st_union(lados_de_manzana.geom)), 10::double precision) AS geom,
            lados_de_manzana.cover
           FROM lados_de_manzana
          GROUP BY lados_de_manzana.codigo20, 
           lados_de_manzana.lado_id, 
           lados_de_manzana.mza, lados_de_manzana.lado, 
           lados_de_manzana.cover, lados_de_manzana.seg
        ), 
  lado_manzana AS (
         SELECT "substring"(lados_codigos.mza::text, 1, 2)::integer AS prov,
            "substring"(lados_codigos.mza::text, 3, 3)::integer AS depto,
            "substring"(lados_codigos.mza::text, 6, 3)::integer AS codloc,
            "substring"(lados_codigos.mza::text, 9, 2)::integer AS frac,
            "substring"(lados_codigos.mza::text, 11, 2)::integer AS radio,
            "substring"(lados_codigos.mza::text, 13, 3)::integer AS mza,
            "substring"(lados_codigos.cover, 2, 4) AS codaglo,
            lados_codigos.codigo20,
            lados_codigos.lado_id,
            lados_codigos.mza AS link,
            lados_codigos.lado,
            lados_codigos.seg,
            st_buffer(
              st_offsetcurve(
                st_linesubstring(
                      lados_codigos.geom, 0.10::double precision, 0.90::double precision
                  ), 
                '-6'::integer::double precision
                ), 
              4::double precision, 'endcap=flat join=round'::text
            ) AS geom,
            CASE
              WHEN st_geometrytype(lados_codigos.geom) <> 'ST_LineString'::text THEN 'Lado discontinuo'::text
              ELSE NULL::text
            END AS error_msg,
            row_number() OVER w AS ranking
           FROM lados_codigos
          WINDOW w AS (
            PARTITION 
              BY lados_codigos.mza 
              ORDER BY (st_y(st_startpoint(lados_codigos.geom))) DESC, 
                       (st_x(st_startpoint(lados_codigos.geom)))
            )
          ORDER BY ("substring"(lados_codigos.mza::text, 13, 3)::integer), 
                   lados_codigos.lado
        ), 
  final AS (
         SELECT (
           (
             (
               (
                 (
                   (
                     (
                       (
                         (lado_manzana.prov || '-'::text) 
                           || lado_manzana.depto
                       ) || '-'::text
                     ) || lado_manzana.codloc
                   ) || '-'::text
                 ) || lado_manzana.frac) || '-'::text
             ) || lado_manzana.radio) || '-'::text
         ) || lado_manzana.seg AS gid,
            lado_manzana.prov, 
            lado_manzana.depto,
            lado_manzana.codloc,
            lado_manzana.frac,
            lado_manzana.radio,
            lado_manzana.codaglo,
            lado_manzana.seg,
            lado_manzana.mza,
            lado_manzana.lado,
            sum(conteos.conteo) AS vivseg,
            '*' AS final,
            st_union(lado_manzana.geom) AS geom
           FROM lado_manzana
             LEFT JOIN 
    ---------------------- usa a drepecar segmentacion.conteos
             segmentacion.conteos conteos(tabla, prov, depto, codloc, frac, radio, mza, lado, conteo, id) 
             USING (prov, depto, codloc, frac, radio, mza, lado)
          WHERE lado_manzana.seg <> 0
          GROUP BY ((((((((((lado_manzana.prov || '-'::text) || lado_manzana.depto) || '-'::text) || lado_manzana.codloc) || '-'::text) || lado_manzana.frac) || '-'::text) || lado_manzana.radio) || '-'::text) || lado_manzana.seg), lado_manzana.prov, lado_manzana.depto, lado_manzana.codloc, lado_manzana.frac, lado_manzana.radio, lado_manzana.codaglo, lado_manzana.seg, lado_manzana.mza, lado_manzana.lado
          ORDER BY ((((((((((lado_manzana.prov || '-'::text) || lado_manzana.depto) || '-'::text) || lado_manzana.codloc) || '-'::text) || lado_manzana.frac) || '-'::text) || lado_manzana.radio) || '-'::text) || lado_manzana.seg), lado_manzana.prov, lado_manzana.depto, lado_manzana.codloc, lado_manzana.frac, lado_manzana.radio, lado_manzana.codaglo, lado_manzana.seg, lado_manzana.mza, lado_manzana.lado
        ), mi_tabla AS (
         SELECT lpad(final.prov::text, 2, '0'::text)::character(2) AS prov,
  ------------------------- stuff local...        
            '0357'::character(4) AS codmuni,
            'MU'::character(2) AS catmuni,
            final.codaglo,
            '03'::character(2) AS nroentidad,
  -------------------------
            lpad(final.depto::text, 3, '0'::text)::character(3) AS depto,
            lpad(final.codloc::text, 3, '0'::text)::character(3) AS codloc,
            lpad(final.frac::text, 2, '0'::text)::character(2) AS frac,
            lpad(final.radio::text, 2, '0'::text)::character(2) AS radio,
            'U'::character(1) AS tiporad,
            lpad(final.mza::text, 3, '0'::text)::character(3) AS mza,
            lpad(final.lado::text, 2, '0'::text)::character(2) AS lado,
            NULL::character(1) AS tipoform,
            lpad(final.seg::text, 2, '0'::text)::character(2) AS seg,
            NULL::character(2) AS ve_cc_bc_ca,
                CASE
                    WHEN final.codloc = 0 THEN 1
                    ELSE 0
                END::character(1) AS rural,
            COALESCE(final.vivseg, 0::numeric) AS vivseg,
            final.final::character(1) AS final
           FROM final
        )
 SELECT mi_tabla.prov,
    mi_tabla.depto,
    mi_tabla.frac,
    mi_tabla.radio,
    mi_tabla.tiporad,
    mi_tabla.codloc,
    mi_tabla.seg,
    count(DISTINCT mi_tabla.mza) AS cant_mzas,
    array_to_string(array_agg(DISTINCT mi_tabla.mza ORDER BY mi_tabla.mza), ','::text) AS mzas,
    count(DISTINCT mi_tabla.mza::text || mi_tabla.lado::text) AS cant_lados,
    array_to_string(array_agg(((mi_tabla.mza::text || '('::text) || mi_tabla.lado::text) || ')'::text ORDER BY mi_tabla.mza, mi_tabla.lado), ','::text) AS mza_lados,
    sum(mi_tabla.vivseg) AS vivs,
    mi_tabla.final
   FROM mi_tabla
  GROUP BY mi_tabla.prov, mi_tabla.codmuni, mi_tabla.catmuni, mi_tabla.depto, mi_tabla.frac, mi_tabla.radio, mi_tabla.tiporad, mi_tabla.codloc, mi_tabla.nroentidad, mi_tabla.codaglo, mi_tabla.tipoform, mi_tabla.seg, mi_tabla.ve_cc_bc_ca, mi_tabla.rural, mi_tabla.final;

