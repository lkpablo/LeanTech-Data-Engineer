select
    customer_id::number(38, 0) as customer_id,
    name::varchar              as name,
    email::varchar             as email,
    country_iso3::varchar(3)   as country
from {{ ref('stg_customers') }}
where reject_reason is null
  and not is_duplicate
