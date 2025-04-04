with mrt_airport_top_food_items as (
    select a.name as airport, menu_item, count(*) as count
    from {{ ref('Menu_Items') }}  m join {{ ref('Business') }} b
    on m.business_name = b.name
    join {{ ref('Airport_Businesses') }} ab on b.name = ab.business
    join {{ ref('Airport') }} a on ab.icao = a.icao
    group by a.name, menu_item
    order by count(*) desc, airport
)

select * 
from mrt_airport_top_food_items