with mrt_flight_delay_frequency_by_airline as (
  select airline, airport, city, state, round(avg(delay_frequency), 2) as delay_frequency
  from
    (select al.name as airline, ap.name as airport, ap.city, ap.state, extract(year from fd.event_month) as year, count(fd.arr_delay_min) as delay_frequency
    from {{ ref('Airport') }} ap join {{ ref('Flight_Delays') }} fd
    on ap.icao = fd.airport_icao
    join {{ ref('Airline') }} al
    on fd.airline_id = al.id
    where fd.arr_delay_min > 0
    group by al.name, ap.name, ap.city, ap.state, extract(year from fd.event_month)
    order by delay_frequency desc)
  group by airline, airport, city, state
  order by delay_frequency desc
)

select *
from mrt_flight_delay_frequency_by_airline