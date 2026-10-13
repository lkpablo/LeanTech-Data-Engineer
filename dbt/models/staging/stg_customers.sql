
with source as (
    select * from {{ source('raw', 'customers') }}
),

cleaned as (
    select
        try_to_number(trim(customer_id)) as customer_id,
        nullif(trim(name), '')           as name,
        lower(nullif(trim(email), ''))   as email,
        nullif(trim(country), '')        as country,
        _file,
        _row,
        _loaded_at
    from source
)

select
    c.customer_id,
    c.name,
    case when regexp_like(c.email, '^[^@ ]+@[^@ ]+[.][a-z]{2,}$') then c.email end as email,
    c.country,
    m.iso3 as country_iso3,
    case when c.customer_id is null then 'invalid_customer_id' end as reject_reason,
    array_construct_compact(
        case when c.name is null then 'missing_name' end,
        case when c.email is null then 'missing_email'
             when not regexp_like(c.email, '^[^@ ]+@[^@ ]+[.][a-z]{2,}$') then 'malformed_email' end,
        case when c.country is null then 'missing_country'
             when m.iso3 is null then 'unknown_country' end
    ) as issues,
    -- the same customer delivered twice: the latest version wins
    row_number() over (partition by c.customer_id order by c._loaded_at desc, c._row desc) > 1 as is_duplicate,
    c._file,
    c._row,
    c._loaded_at
from cleaned c
left join {{ ref('country_iso3') }} m on m.country = lower(c.country)
