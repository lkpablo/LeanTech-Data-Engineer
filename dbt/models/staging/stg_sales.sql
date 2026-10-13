
with source as (
    select * from {{ source('raw', 'sales') }}
),

cleaned as (
    select
        try_to_number(trim(transaction_id))        as transaction_id,
        nullif(trim(sale_date), '')                as sale_date_raw,
        try_to_date(trim(sale_date), 'YYYY-MM-DD') as sale_date,
        try_to_number(trim(customer_id))           as customer_id,
        try_to_number(trim(product_id))            as product_id,
        nullif(trim(amount), '')                   as amount_raw,
        try_to_decimal(trim(amount), 12, 2)        as amount,
        _file,
        _row,
        _loaded_at
    from source
),

known_customers as (
    select distinct customer_id from {{ ref('stg_customers') }} where reject_reason is null
),

known_products as (
    select distinct product_id from {{ ref('stg_products') }} where reject_reason is null
)

select
    s.transaction_id,
    s.sale_date,
    s.customer_id,
    s.product_id,
    s.amount,
    case
        when s.transaction_id is null then 'invalid_transaction_id'
        when s.sale_date_raw is null  then 'missing_date'
        when s.sale_date is null      then 'invalid_date'
        when s.amount_raw is null     then 'missing_amount'
        when s.amount is null         then 'invalid_amount'
        when s.amount < 0             then 'negative_amount'
        when c.customer_id is null    then 'unknown_customer'
        when p.product_id is null     then 'unknown_product'
    end as reject_reason,
    row_number() over (partition by s.transaction_id order by s._loaded_at desc, s._row desc) > 1 as is_duplicate,
    s._file,
    s._row,
    s._loaded_at
from cleaned s
left join known_customers c on c.customer_id = s.customer_id
left join known_products p on p.product_id = s.product_id
