-- tmp_businesses contains duplicate businesses 
-- that have variations in their assigned category
-- to decide which category to keep, rank them by
-- popularity and keep the top one

with sorted_categories as (
    select name, category, count(*) as num_businesses
    from {{ ref('tmp_businesses') }}
    group by name, category
),

int_tmp_businesses_ranked as (
    select row_number() over (partition by name order by 
        (select num_businesses from sorted_categories s 
         where b. category = s.category and b.name = s.name) desc, 
         length(menu_items) desc) as rank, *
    from {{ ref('tmp_businesses') }} b
)

-- add the dining flag as a calculated field
select name, category, menu_items, 
    case menu_items when null then False else True end as dining,
    _data_source, _load_time
from int_tmp_businesses_ranked
where rank = 1