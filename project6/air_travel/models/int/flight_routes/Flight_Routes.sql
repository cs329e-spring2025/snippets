with int_Flight_Routes as (
    select route_id, airline_id, source_airport_icao, dest_airport_icao, codeshare, stops, 
        _data_source, _load_time
    from {{ ref('tmp_flight_routes') }}
)

select *
from int_Flight_Routes