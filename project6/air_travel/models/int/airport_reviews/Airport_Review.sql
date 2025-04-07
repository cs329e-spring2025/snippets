with int_Airport_Review as (
    select rev.id, rev.thread_id, rev.icao, rev.date_created, rev.author, rev.subject, rev.body, 
        enc.relevant, enc.sentiment, rev._data_source, rev._load_time
    from {{ ref('tmp_airport_reviews') }} rev
    join {{ ref('tmp_airport_reviews_enriched') }} enc
    on rev.id = enc.id
    where rev.subject is not null 
    and rev.body is not null
    and rev.id not in (select id
        from {{ ref('tmp_airport_reviews_enriched') }}
        group by id
        having count(*) > 1)
)

select *
from int_Airport_Review