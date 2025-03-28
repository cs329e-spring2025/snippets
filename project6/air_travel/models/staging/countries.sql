with stg_countries as (
	select country_name as name,
	    case iso_code
	      when '\\N' then null
	      else iso_code
	      end as iso_code,
	    dafif_code,
	    _data_source,
	    _load_time
	from {{ source('air_travel_raw', 'countries') }}
)

select *
from stg_countries