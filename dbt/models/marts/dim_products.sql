select
    product_id::number(38, 0) as product_id,
    product_name::varchar     as product_name,
    category::varchar         as category,
    price::number(12, 2)      as price
from {{ ref('stg_products') }}
where reject_reason is null
  and not is_duplicate
