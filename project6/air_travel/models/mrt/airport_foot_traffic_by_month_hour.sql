with mrt_airport_foot_traffic_by_month_hour as (
  select case month
        when 1 then 'January'
        when 2 then 'February'
        when 3 then 'March'
        when 4 then 'April'
        when 5 then 'May'
        when 6 then 'June'
        when 7 then 'July'
        when 8 then 'August'
        when 9 then 'September'
        when 10 then 'October'
        when 11 then 'November'
        when 12 then 'December' end as month,
    case hour
        when 0 then '12am'
        when 1 then '1am'
        when 2 then '2am'
        when 3 then '3am'
        when 4 then '4am'
        when 5 then '5am'
        when 6 then '6am'
        when 7 then '7am'
        when 8 then '8am'
        when 9 then '9am'
        when 10 then '10am'
        when 11 then '11am'
        when 12 then '12pm'
        when 13 then '1pm'
        when 14 then '2pm'
        when 15 then '3pm'
        when 16 then '4pm'
        when 17 then '5pm'
        when 18 then '6pm'
        when 19 then '7pm'
        when 20 then '8pm'
        when 21 then '9pm'
        when 22 then '10pm'
        when 23 then '11pm' end as hour,
    business, airport, city, state, terminal, foot_traffic
from
    (select extract(month from t.event_date) as month, t.event_hour as hour,
    b.name as business, a.name as airport, a.city, a.state, ab.terminal,
    round(avg(t.passenger_count), 2) as foot_traffic
    from {{ ref('Airport_Businesses') }} ab join {{ ref('Business') }} b
    on ab.business = b.name
    join {{ ref('Airport') }} a
    on ab.icao = a.icao
    join {{ ref('TSA_Traffic') }} t
    on a.icao = t.airport_icao
    where b.name not in ("Food Court", "Mother's Room", "Conference Center")
    group by extract(month from t.event_date), t.event_hour, b.name, a.name, a.city, a.state, ab.terminal
    order by month, hour, foot_traffic desc)
)

select *
from mrt_airport_foot_traffic_by_month_hour