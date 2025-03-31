with stg_flight_routes as (
	select airline_code,
	    safe_cast(airline_id as INTEGER) as airline_id,
	    source_airport,
	    case source_airport_id
	      when '\\N' then null
	      else safe_cast(source_airport_id as INTEGER)
	      end as source_airport_id,
	    dest_airport,
	    case dest_airport_id
	      when '\\N' then null
	      else safe_cast(dest_airport_id as INTEGER)
	      end as dest_airport_id,
	    codeshare,
	    stops,
	    equipment,
	    _data_source,
	    _load_time
	from {{ source('air_travel_raw', 'flight_routes') }}
)

select *
from stg_flight_routes