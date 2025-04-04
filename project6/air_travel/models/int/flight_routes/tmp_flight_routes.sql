
{{ config(
    post_hook = [
        "update {{ this }} set source_airport_icao = 'ZSJA' where source_airport_iata = 'JGS'"
    ]
) }}

with int_tmp_flight_routes as (
    select row_number() over () as route_id, f.airline_id, a1.icao as source_airport_icao, f.source_airport as source_airport_iata,
        a2.icao as dest_airport_icao, f.dest_airport as dest_airport_iata,
        f.codeshare, f.stops, f.equipment, f._data_source, f._load_time
    from {{ ref('flight_routes') }} f join {{ ref('airports') }} a1
    on f.source_airport_id = a1.airport_id
    join {{ ref('airports') }} a2 
    on f.dest_airport_id = a2.airport_id
    where f.airline_id is not null
    and a1.icao is not null
    and a2.icao is not null
)

select * 
from int_tmp_flight_routes