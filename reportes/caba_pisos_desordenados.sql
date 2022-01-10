/*
busca pisos que estén desordenados
autor : -h
2022-01-06
*/

with listado_sin_nulos as (
    select id, prov, dpto, codloc, frac, radio, mza, lado, nrocatastr,
    coalesce(sector,'') sector, coalesce(edificio,'') edificio, coalesce(entrada,'') entrada, piso as cpiso,
    case when coalesce(piso, '') = '' or upper(piso) = 'PB' then 0 else piso::integer end piso, dpto_habit,
    coalesce(CASE WHEN orden_reco='' THEN NULL ELSE orden_reco END,'0')::integer orden_reco
    from e02014010.listado)
select i.id, frac as ff, radio as rr, mza, lado, nrocatastr as nro, 
--sector, edificio, entrada, 
  i.cpiso as piso, i.orden_reco as orden, 
  array_agg(j.cpiso order by j.orden_reco) as pisos, array_agg(j.orden_reco order by j.orden_reco) as desordenados
from listado_sin_nulos i
join listado_sin_nulos j
using (prov, dpto, codloc, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada)
where i.piso < j.piso and i.orden_reco <= j.orden_reco
--or i.piso = j.piso and i.dpto_habit > j.dpto_habit and i.orden_reco <= j.orden_reco
group by i.id, frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, i.cpiso, i.orden_reco
order by frac, radio, mza, lado, nrocatastr, sector, edificio, entrada, i.cpiso desc, i.orden_reco 
;


/*
  id   | ff | rr | mza | lado | nro  | piso | orden |                                                                                                            pisos                                                                                                             |                                                                                                                                                                                       desordenados                                 
-------+----+----+-----+------+------+------+-------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   671 | 02 | 02 | 019 | 001  | 1784 | 9    |     1 | {13,13,12,12,11,11,10,10}                                                                                                                                                                                                    | {2,3,4,5,6,7,8,9}
   823 | 02 | 02 | 019 | 002  | 2666 | PB   |    18 | {15,14,13,12,11,10,9,8,7,6,5,4,3,2,1}                                                                                                                                                                                        | {19,20,21,22,23,24,25,26,27,28,29,30,31,32,33}
  1008 | 02 | 02 | 019 | 003  | 2655 | PB   |    56 | {2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1}                                                                                                                                                                                  | {57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77}
  1651 | 02 | 06 | 029 | 001  | 2524 | PB   |    11 | {10}                                                                                                                                                                                                                         | {12}
  1642 | 02 | 06 | 029 | 001  | 2524 | 9    |     2 | {10}                                                                                                                                                                                                                         | {12}
  1643 | 02 | 06 | 029 | 001  | 2524 | 8    |     3 | {10}                                                                                                                                                                                                                         | {12}
  1644 | 02 | 06 | 029 | 001  | 2524 | 7    |     4 | {10}                                                                                                                                                                                                                         | {12}
  1645 | 02 | 06 | 029 | 001  | 2524 | 6    |     5 | {10}                                                                                                                                                                                                                         | {12}
  1646 | 02 | 06 | 029 | 001  | 2524 | 5    |     6 | {10}                                                                                                                                                                                                                         | {12}
  1647 | 02 | 06 | 029 | 001  | 2524 | 4    |     7 | {10}                                                                                                                                                                                                                         | {12}
  1648 | 02 | 06 | 029 | 001  | 2524 | 3    |     8 | {10}                                                                                                                                                                                                                         | {12}
  1649 | 02 | 06 | 029 | 001  | 2524 | 2    |     9 | {10}                                                                                                                                                                                                                         | {12}
  1650 | 02 | 06 | 029 | 001  | 2524 | 1    |    10 | {10}                                                                                                                                                                                                                         | {12}
  2007 | 02 | 07 | 035 | 002  | 2394 | PB   |    27 | {7,7,6,6,5,5,4,4,3,3,2,2,1,1}                                                                                                                                                                                                | {28,29,30,31,32,33,34,35,36,37,38,39,40,41}
  3972 | 03 | 05 | 010 | 002  | 1640 | PB   |    14 | {1,1}                                                                                                                                                                                                                        | {15,16}
  4196 | 03 | 05 | 010 | 004  | 1655 |      |     0 | {6,6,5,5,5,4,3,3,2,1}                                                                                                                                                                                                        | {80,81,82,83,84,85,86,87,88,89}
  4725 | 03 | 06 | 011 | 002  | 1732 | PB   |   136 | {10,9,8,7,6,5,4,3,2,1}                                                                                                                                                                                                       | {137,138,139,140,141,142,143,144,145,146}
...

*/

