with payments as (

    select * from {{ ref('int_payments__with_chargebacks') }}

)

select
    -- ids
    transaction_id::varchar                     as transaction_id,
    event_ref::varchar                          as event_ref,

    -- timestamps
    transaction_at::timestamp_ntz               as transaction_at,
    transaction_at::date                        as transaction_date,

    -- transaction attributes
    transaction_state::varchar                  as transaction_state,
    is_accepted::boolean                        as is_accepted,
    (not is_accepted)::boolean                  as is_declined,
    is_cvv_provided::boolean                    as is_cvv_provided,

    -- amounts
    amount_local::number(18, 2)                 as amount_local,
    currency_code::varchar                      as currency_code,
    local_per_usd_rate::number(38, 10)          as local_per_usd_rate,
    amount_usd::number(38, 6)                   as amount_usd,

    -- geography
    card_country_code::varchar                  as card_country_code,

    -- chargebacks
    has_chargeback_record::boolean              as has_chargeback_record,
    is_chargeback::boolean                      as is_chargeback

from payments