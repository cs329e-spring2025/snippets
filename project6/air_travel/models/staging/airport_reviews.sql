with stg_reviews as (
	select id,
	  threadRef as thread_id,
	  airportRef as airport_id,
	  airportIdent as airport_code,
	  date as date_created,
	  memberNickname as author,
	  subject,
	  body,
	  _data_source,
	  _load_time
	from {{ source('air_travel_raw', 'airport_reviews') }}
)

select *
from stg_reviews