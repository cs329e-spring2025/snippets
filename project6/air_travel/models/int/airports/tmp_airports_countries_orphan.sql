with int_tmp_airports_countries_orphan as (
    select distinct country 
    from {{ ref('airports') }}
    where country not in (select name from {{ ref('Country') }} )
)

select *
from int_tmp_airports_countries_orphan