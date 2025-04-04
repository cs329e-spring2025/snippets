with int_Country as (
    select name, iso_code, array_agg(ifnull(dafif_code, 'Unknown')) as dafif_codes, 
        _data_source, _load_time
    from {{ ref('countries') }}
    group by name, iso_code, _data_source, _load_time
)

select * 
from int_Country