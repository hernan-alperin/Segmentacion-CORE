
with localidades as (
  select schema_name as esquema
  from information_schema.schemata 
  where schema_name ~ 'e[0-9]*' and length(schema_name) = 9)
select * 
from localidades
;

