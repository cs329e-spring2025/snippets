-- merge airport records into one final table
-- from tmp_airports and tmp_airports_filled_out
-- result count = 6396
with int_merged_airports as (
    select icao, iata, name,
       city, state, country,
       latitude, longitude, altitude, timezone_name, timezone_delta, daylight_savings_time,
       type, source, _data_source, _load_time
    from {{ ref('tmp_airports') }} 
    where icao is not null and iata is not null and name is not null
    union distinct 
    select taf.icao, taf.iata, ta.name, taf.city, taf.state, ta.country, 
       ta.latitude, ta.longitude, ta.altitude, ta.timezone_name, ta.timezone_delta, ta.daylight_savings_time, 
       ta.type, ta.source, ta._data_source, ta._load_time
    from {{ ref('tmp_airports') }} ta 
    join {{ ref('tmp_airports_filled_out') }} taf
    on ta.name = taf.name and ta.country = taf.country
    where ta.icao is null and taf.iata is not null and taf.name is not null and ta.country is not null
),

-- find all the duplicate airport records 
-- result count = 181
int_tmp_airport_duplicates_all as (
   select * from int_merged_airports 
   where icao in (
      select icao
      from int_merged_airports
      group by icao
      having count(*) > 1
   )
   order by icao
), 

-- filter the duplicate records
-- result count = 207
int_tmp_airport_duplicates_filtered as (
   select a1.*
   from int_tmp_airport_duplicates_all a1 join int_tmp_airport_duplicates_all a2
   on a1.icao = a2.icao and a1.iata = a2.iata and a1.name = a2.name and a1.name = a2.name
),

-- rank the filtered duplicate records
-- result count = 207
int_tmp_airport_duplicates_filtered_ranked as (
   select rank() over (partition by icao order by length(concat(icao, iata, name, city, 
                        state, country, cast(latitude as string), 
                        cast(longitude as string), cast(altitude as string))) desc) as rank, *
   from int_tmp_airport_duplicates_filtered
),

-- find remaining duplicates
-- result count = 35
int_tmp_airport_duplicates_filtered_ranked_duplicates as (
   select icao, count(*) 
   from int_tmp_airport_duplicates_filtered_ranked
   where rank = 1
   group by icao
   having count(*) > 1
),

-- merge the tables into one, while disposing of duplicates
-- result count: 6297
int_merged_airports_filtered as (
   select * 
   from int_merged_airports
   where icao not in (select icao from int_tmp_airport_duplicates_all)
   union distinct
   select * except (rank) 
   from int_tmp_airport_duplicates_filtered_ranked
   where rank = 1
   and icao not in (select icao from int_tmp_airport_duplicates_filtered_ranked_duplicates)
)

-- map the country names to Country.name and construct the final table with the results
-- result count: 6237
select *
from int_merged_airports_filtered
where country in (select name from {{ ref('Country') }})
union distinct
select a.icao, a.iata, a.name, a.city, a.state, c.new as country, 
   a.latitude, a.longitude, a.altitude, a.timezone_name, a.timezone_delta, 
   a.daylight_savings_time, a.type, a.source, a._data_source, a._load_time
from int_merged_airports_filtered a join {{ ref('tmp_airports_countries_filtered') }} c
on a.country = c.current
where country not in (select name from {{ ref('Country') }})