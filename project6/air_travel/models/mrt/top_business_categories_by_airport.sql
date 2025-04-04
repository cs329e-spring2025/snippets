with mrt_top_business_categories_by_airport as (
  select b.category, a.name as airport, count(*) as count
  from {{ ref('Menu_Items') }} m join {{ ref('Business') }} b
  on m.business_name = b.name
  join {{ ref('Airport_Businesses') }} ab on b.name = ab.business
  join {{ ref('Airport') }} a on ab.icao = a.icao
  group by b.category, a.name
  order by count(*) desc, a.name
)

select *
from mrt_top_business_categories_by_airport