with int_Aircraft as (
    select icao, iata, name, _data_source, _load_time
    from {{ ref('aircrafts') }}
    where icao is not null
    and iata is not null
    union distinct
    select ta.icao, ta.iata, a.name, a._data_source, a._load_time
    from {{ ref('tmp_aircrafts') }} ta
    join {{ ref('aircrafts') }} a
    on ta.name = a.name
    where ta.icao is not null
    and ta.iata is not null
)

select *
from int_Aircraft