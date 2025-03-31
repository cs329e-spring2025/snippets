with int_Airline as (
    select id, name, alias, icao, iata, callsign, country, active, _data_source, _load_time
    from {{ ref('airlines') }}
    where country in (select name from {{ ref('Country') }}
    union distinct
    select f.id, f.name, f.alias, f.icao, f.iata, f.callsign, f.country, f.active, a._data_source, a._load_time
    from {{ ref('tmp_airlines_countries_filtered') }} f
    join {{ ref('airlines') }} a on f.id = a.id
    where f.country is not null
    order by country
)

select * 
from int_Airline
