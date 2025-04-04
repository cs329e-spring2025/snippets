with int_tmp_route_equipment as (
    select route_id, split(equipment, ' ') as equipment_array
    from {{ ref('tmp_flight_routes') }}
    where equipment is not null
)

select route_id, equipment 
from int_tmp_route_equipment 
cross join unnest(equipment_array) as equipment
where equipment != ''
