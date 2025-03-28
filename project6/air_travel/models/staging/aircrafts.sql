with stg_aircrafts as (
    select aircraft_name as name,
    	case iata_code when '\\N' then null else iata_code end as iata,
    	case icao_code when '\\N' then null else icao_code end as icao,
    	_data_source,
    	_load_time
	from {{ source('air_travel_raw', 'aircrafts') }}
)

select *
from stg_aircrafts