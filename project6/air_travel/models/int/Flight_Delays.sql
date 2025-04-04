with int_Flight_Delays as (
    select distinct fd.event_month, al.id as airline_id, ap.icao as airport_icao, fd.arr_total, fd.arr_cancelled,
        fd.arr_diverted, fd.arr_delay_min, fd.weather_delay_min, fd.nas_delay_min, fd.late_aircraft_delay_min,
        fd._data_source, fd._load_time
    from {{ ref('flight_delays') }} fd join {{ ref('Airport') }} ap on fd.airport_code = ap.iata
    join {{ ref('Airline') }} al on fd.carrier = al.iata
    where ap.country = 'United States'
)

select *
from int_Flight_Delays