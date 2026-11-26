{% test is_positive(model, column_name) %}

-- returns the rows that fail: values that are zero or negative
select *
from {{ model }}
where {{ column_name }} <= 0

{% endtest %}