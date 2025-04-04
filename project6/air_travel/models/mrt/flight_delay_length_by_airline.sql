with mrt_flight_delay_length_by_airline as (
  select al.name as airline, ap.name as airport, ap.city, ap.state, sum(fd.arr_delay_min) as delay_minutes
  from {{ ref('Airport') }} ap join {{ ref('Flight_Delays') }} fd
  on ap.icao = fd.airport_icao
  join {{ ref('Airline') }} al
  on fd.airline_id = al.id
  where fd.arr_delay_min is not null
  group by al.name, ap.name, ap.city, ap.state
  order by delay_minutes desc
)

select *
from mrt_flight_delay_length_by_airline