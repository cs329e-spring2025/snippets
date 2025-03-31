with int_tmp_tsa_traffic as (
    select distinct t.event_date, t.event_hour, a.icao as airport_icao, 
        t.tsa_checkpoint, t.passenger_count, t._data_source, t._load_time
    from {{ ref('Airport') }} a join {{ ref('tsa_traffic') }} t
    on a.iata = t.airport_code
    where a.country = 'United States'
),
    int_tmp_tsa_traffic_duplicates as 
(
    select * 
    from int_tmp_tsa_traffic
    where struct(event_date, event_hour, airport_icao, tsa_checkpoint) in
              (select struct(event_date, event_hour, airport_icao, tsa_checkpoint)
                from int_tmp_tsa_traffic
                group by event_date, event_hour, airport_icao, tsa_checkpoint
                having count(*) > 1)
)

select * 
from int_tmp_tsa_traffic
except distinct
select * 
from int_tmp_tsa_traffic_duplicates
