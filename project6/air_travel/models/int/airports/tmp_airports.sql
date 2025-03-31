with int_tmp_airports as (
    -- US airports 
    select distinct a.icao, a.iata, a.name,
       a.city, tsa.airport_state as state, a.country,
       a.latitude, a.longitude, a.altitude, a.timezone_name, a.timezone_delta, a.daylight_savings_time,
       a.type, a.source, a._data_source, a._load_time
	from {{ ref('airports') }} a
    left join {{ ref('tsa_traffic') }} tsa
    on a.iata = tsa.airport_code
    where a.country = 'United States'
    and a.type in ('airport', NULL)
    union distinct
    -- non-US airports
    select icao, iata, name, city, null, country, 
    latitude, longitude, altitude, timezone_name, timezone_delta, daylight_savings_time, 
    type, source, _data_source, _load_time
    from {{ ref('airports') }}
    where country != 'United States'
    and type in ('airport', NULL)
)

select *
from int_tmp_airports