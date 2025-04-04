with int_tmp_country_orphans as (
    select distinct country 
    from {{ ref('airlines') }}
    where country not in (select name from {{ ref('Country') }} )
)

select *
from int_tmp_country_orphans