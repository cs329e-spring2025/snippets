with int_Airport as (
    select n.icao, n.iata, a.name,
       a.city, a.state, a.country,
       a.latitude, a.longitude, a.altitude, a.timezone_name, a.timezone_delta, a.daylight_savings_time,
       a.type, a.source, a._data_source, a._load_time
    from {{ ref('tmp_airports') }} a 
    join {{ ref('tmp_airport_names') }} n
    on a.name = n.name 
    and a.country = n.country
    where a.icao is null and a.name is not null and a.country is not null
    and n.icao is not null and source != 'User'
    union distinct 
    select icao, iata, name, city, null, country, 
    latitude, longitude, altitude, timezone_name, timezone_delta, daylight_savings_time, 
    type, source, _data_source, _load_time
    from {{ ref('tmp_airports') }} 
    where a.icao is not null and source != 'User'
)

select *
from int_Airport