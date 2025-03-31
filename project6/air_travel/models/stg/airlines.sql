with stg_airlines as (
	select airline_id as id,
	  name,
	  case alias
	    when '\\N' then null
	    when '' then null
	    else alias
	    end as alias,
	  case iata
	    when '' then null
	    else iata
	    end as iata,
	  case icao
	    when '' then null
	    else icao
	    end as icao,
	  case callsign
	    when '' then null
	    else callsign
	    end as callsign,
	  case country
	    when '\\N' then null
	    when '' then null
	    else country end as country,
	  active, _data_source, _load_time
	from {{ source('air_travel_raw', 'airlines') }}
)

select *
from stg_airlines