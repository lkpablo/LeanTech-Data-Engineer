
{% set entities = [('customers', 'customer_id'), ('products', 'product_id'), ('sales', 'transaction_id')] %}

{% for entity, key in entities %}
select '{{ entity }}' as entity, {{ key }}::varchar as record_id, reject_reason as issue, 'rejected' as action, _file, _row
from {{ ref('stg_' ~ entity) }}
where reject_reason is not null and not is_duplicate

union all

select '{{ entity }}', {{ key }}::varchar, 'duplicate_id', 'dropped', _file, _row
from {{ ref('stg_' ~ entity) }}
where is_duplicate
{% if entity != 'sales' %}
union all

select '{{ entity }}', s.{{ key }}::varchar, f.value::varchar, 'flagged', s._file, s._row
from {{ ref('stg_' ~ entity) }} s, lateral flatten(input => s.issues) f
where s.reject_reason is null and not s.is_duplicate
{% endif %}
{% if not loop.last %}union all{% endif %}
{% endfor %}
