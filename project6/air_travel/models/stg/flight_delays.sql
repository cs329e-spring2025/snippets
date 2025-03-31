with stg_flight_delays as (
	select event_month, carrier, carrier_name, airport_code,
	  split(city_state, ',')[0] as airport_city, split(city_state, ',')[1] as airport_state,
	  airport_name, * except (event_month, carrier, carrier_name, airport_code, airport_name, city_state)
	  from
	    (select date(year, month, 01) as event_month, carrier, carrier_name, airport as airport_code,
	       split(airport_name, ':')[0] as city_state, split(airport_name, ':')[1] as airport_name,
	       safe_cast(arr_flights as INTEGER) as arr_total, safe_cast(arr_cancelled as INTEGER) as arr_cancelled,
	       safe_cast(arr_diverted as INTEGER) as arr_diverted, safe_cast(arr_delay as INTEGER) as arr_delay_min,
	       safe_cast(weather_delay as INTEGER) as weather_delay_min, safe_cast(nas_delay as INTEGER) as nas_delay_min,
	       safe_cast(late_aircraft_delay as INTEGER) as late_aircraft_delay_min, _data_source, _load_time
	       from {{ source('air_travel_raw', 'flight_delays') }})
)

select *
from stg_flight_delays