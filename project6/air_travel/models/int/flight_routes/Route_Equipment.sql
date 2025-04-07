with int_Route_Equipment as (
    select distinct re.route_id, a.icao as aircraft_icao, a._data_source, a._load_time
    from {{ ref('tmp_route_equipment') }} re join {{ ref('Aircraft') }} a
    on re.equipment = a.iata
)

select *
from int_Route_Equipment