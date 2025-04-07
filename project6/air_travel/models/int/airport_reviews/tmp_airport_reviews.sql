-- result count: 7749
with int_tmp_airport_reviews as (
    select distinct id, thread_id, airport_code as icao, date_created, author,
            subject, body, _data_source, _load_time
    from {{ ref('airport_reviews') }}  
    where airport_code in (select icao from {{ ref('Airport') }})
)

select * 
from int_tmp_airport_reviews
    