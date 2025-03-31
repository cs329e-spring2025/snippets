-- merge airport records into one final table
-- from tmp_airports and tmp_airports_filled_out
with int_Airport as (
    select icao, iata, name,
       city, state, country,
       latitude, longitude, altitude, timezone_name, timezone_delta, daylight_savings_time,
       type, source, _data_source, _load_time
    from {{ ref('tmp_airports') }} 
    where icao is not null
    union distinct 
    select taf.icao, taf.iata, ta.name, taf.city, taf.state, ta.country, 
       ta.latitude, ta.longitude, ta.altitude, ta.timezone_name, ta.timezone_delta, ta.daylight_savings_time, 
       ta.type, ta.source, ta._data_source, ta._load_time
    from {{ ref('tmp_airports') }} ta 
    join {{ ref('tmp_airports_filled_out') }} taf
    on ta.name = taf.name and ta.country = taf.country
    where ta.icao is null and ta.name is not null and ta.country is not null
)

select *
from int_Airport