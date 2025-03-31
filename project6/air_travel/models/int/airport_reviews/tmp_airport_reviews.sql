with int_tmp_airport_reviews as (
    select distinct r.id, r.thread_id, r.airport_code as icao, r.date_created, r.author,
            r.subject, r.body, r._data_source, r._load_time
    from {{ ref('airport_reviews') }} r 
    join {{ ref('Airport') }} a
    on a.icao = r.airport_code
)

select * 
from int_tmp_airport_reviews
    