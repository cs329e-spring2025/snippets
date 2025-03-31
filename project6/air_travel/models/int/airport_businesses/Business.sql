with sorted_categories as (
    select name, category, count(*) as num_businesses
    from air_travel_int.tmp_business
    group by name, category
),
int_tmp_businesses_with_menus_ranked as (
    select row_number() over (partition by name order by 
        (select num_businesses from sorted_categories s 
         where b. category = s.category and b.name = s.name) desc, 
         length(menu_items) desc) as rank, *
    from {{ ref('tmp_businesses') }} b
    where menu_items is not null
),
int_tmp_businesses_without_menus_ranked as (
    select row_number() over (partition by name order by 
        (select num_businesses from sorted_categories s 
         where b. category = s.category) desc) as rank, *
    from {{ ref('tmp_businesses') }} b
    where menu_items is null
    and name not in (select name from int_tmp_businesses_with_menus_ranked);

-- merge tmp tables and append dining as a calculated field
select name, category, true as dining, menu_items, _data_source, _load_time
from int_tmp_businesses_with_menus_ranked
where rank = 1 and menu_items is not null
union distinct
select name, category, true as dining, menu_items, _data_source, _load_time
from int_tmp_businesses_without_menus_ranked
where rank = 1 and menu_items is not null
union distinct
select name, category, false as dining, menu_items, _data_source, _load_time
from int_tmp_businesses_with_menus_ranked
where rank = 1 and menu_items is null
union distinct
select name, category, false as dining, menu_items, _data_source, _load_time
from int_tmp_businesses_without_menus_ranked
where rank = 1 and menu_items is null
