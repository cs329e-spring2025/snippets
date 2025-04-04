with int_tmp_businesses as (
    select distinct business as name, category, menu_items, _data_source, _load_time
    from {{ ref('airport_businesses') }}
    where category not in ('Ticketing', 'Airlines', 'Airline', 'Airport Services', 'Car Rental', 'Cargo Services', 'Baggage Service', 'Baggage Services', 'Services', 'Air Transportation', 'Airline Ticketing', 'Security', 'Management', 'Airline Services', 'Customer Service', 'Administration', 'Other', 'Vacant', 'Government Services', 'Mail Services', 'Airport Security', 'Immigration', 'Information', 'Parking', 'Police Services', 'Public Space', 'Restrooms', 'Seating', 'Observation Point')
    and business not in ('Restaurant', 'Restaurant Pre-Security', 'Restaurant Post-Security', 'Drinking Water', 'Food & Beverage', 'Restaurant-Bar', 'Snacks and drinks')
)

select * 
from int_tmp_businesses