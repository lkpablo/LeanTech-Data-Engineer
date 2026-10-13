
with bounds as (
    select min(sale_date) as first_day, max(sale_date) as last_day
    from {{ ref('stg_sales') }}
    where reject_reason is null
      and not is_duplicate
),

days as (
    select dateadd(day, row_number() over (order by seq4()) - 1, first_day) as date_key, last_day
    from bounds, table(generator(rowcount => 3660))
)

select
    date_key::date            as date_key,
    year(date_key)::number(4)  as year,
    month(date_key)::number(2) as month,
    day(date_key)::number(2)   as day
from days
where date_key <= last_day
