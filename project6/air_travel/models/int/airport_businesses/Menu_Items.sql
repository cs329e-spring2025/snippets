-- TO DO: add this post-hook: alter table air_travel_int.Business drop column menu_items

with int_Menu_Items as (
    select name as business_name, split(menu_items, ',') as menu_items_array, _data_source, _load_time
    from air_travel_int.Business
    where dining = True
)

select business_name, menu_item, _data_source, _load_time
from int_Menu_Items, unnest(menu_items_array) as menu_item
