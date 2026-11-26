-- A declined payment cannot be charged back: is_chargeback must be NULL for declined rows
select *
from {{ ref('fct_payments') }}
where is_declined
  and is_chargeback is not null