with source as (
    select * from {{ source('raw', 'products') }}
),

cleaned as (
    select
        try_to_number(trim(product_id))      as product_id,
        nullif(trim(product_name), '')       as product_name,
        nullif(trim(category), '')           as category,
        nullif(trim(price), '')              as price_raw,
        try_to_decimal(trim(price), 12, 2)   as price_parsed,
        _file,
        _row,
        _loaded_at
    from source
)

select
    product_id,
    product_name,
    category,
    case when price_parsed >= 0 then price_parsed end as price,
    case when product_id is null then 'invalid_product_id' end as reject_reason,
    array_construct_compact(
        case when product_name is null then 'missing_product_name' end,
        case when category is null then 'missing_category' end,
        case when price_raw is null then 'missing_price'
             when price_parsed is null then 'invalid_price'
             when price_parsed < 0 then 'negative_price' end
    ) as issues,
    row_number() over (partition by product_id order by _loaded_at desc, _row desc) > 1 as is_duplicate,
    _file,
    _row,
    _loaded_at
from cleaned
