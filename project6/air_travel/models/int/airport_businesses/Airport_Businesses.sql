with int_Airport_Businesses as (
    select distinct a.icao, b.terminal, b.business, b.location
    from {{ ref('airport_businesses') }} b 
    join {{ ref('Airport') }} a
    on upper(b.airport_code) = a.iata
    where a.country = 'United States'
    and category not in ('Ticketing', 'Airlines', 'Airline', 'Airport Services', 'Car Rental', 'Cargo Services', 'Baggage Service', 'Baggage Services', 'Services', 'Air Transportation', 'Airline Ticketing', 'Security', 'Management', 'Airline Services', 'Customer Service', 'Administration', 'Other', 'Vacant', 'Government Services', 'Mail Services', 'Airport Security', 'Immigration', 'Information', 'Parking', 'Police Services', 'Public Space', 'Restrooms', 'Seating', 'Observation Point')
    and business not in ('Restaurant', 'Restaurant Pre-Security', 'Restaurant Post-Security', 'Drinking Water', 'Food & Beverage', 'Restaurant-Bar', 'Snacks and drinks')
    order by b.business
)

select *
from int_Airport_Businesses