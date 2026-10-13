select
    transaction_id::number(38, 0) as transaction_id,
    sale_date::date               as date_key,
    customer_id::number(38, 0)    as customer_id,
    product_id::number(38, 0)     as product_id,
    amount::number(12, 2)         as amount
from {{ ref('stg_sales') }}
where reject_reason is null
  and not is_duplicate
