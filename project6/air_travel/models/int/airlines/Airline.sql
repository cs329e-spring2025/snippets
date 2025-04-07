-- the final Airline table is obtained by replacing the countries that don't have referential integrity
-- with the ones collected in tmp_airlines_countries_filtered

{{ config(
    post_hook = [
        "update {{ this }} set country = 'Canada' where country = 'Canadian Territories'",
        "update {{ this }} set country = 'United States' where country = 'ALASKA'",
        "update {{ this }} set country = 'Colombia' where country = 'AVIANCA'",
        "update {{ this }} set country = 'Hong Kong' where country = 'DRAGON'"
    ]
) }}

with int_Airline as (
    select id, name, alias, icao, iata, callsign, country, active, _data_source, _load_time
    from {{ ref('airlines') }}
    where country in (select name from {{ ref('Country') }})
    union distinct
    select a.id, a.name, a.alias, a.icao, a.iata, a.callsign, f.new as country, a.active, a._data_source, a._load_time
    from {{ ref('airlines') }} a
    join {{ ref('tmp_airlines_countries_filtered') }} f on a.country = f.current
    where a.country not in (select name from {{ ref('Country') }})
    order by country
)

select * 
from int_Airline