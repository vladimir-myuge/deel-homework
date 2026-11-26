with acceptance as (

    select * from {{ ref('stg_globepay__acceptance') }}

),

chargebacks as (

    select * from {{ ref('stg_globepay__chargebacks') }}

),

joined as (

    select
        -- ids
        acceptance.transaction_id,
        acceptance.event_ref,

        -- timestamps
        acceptance.transaction_at,

        -- transaction attributes
        acceptance.transaction_state,
        acceptance.transaction_state = 'ACCEPTED'           as is_accepted,
        acceptance.is_cvv_provided,

        -- amounts
        acceptance.amount_local,
        acceptance.currency_code,
        acceptance.local_per_usd_rate,
        acceptance.amount_usd,

        -- geography
        acceptance.card_country_code,

        -- chargebacks
        chargebacks.transaction_id is not null              as has_chargeback_record,
        -- a declined payment cannot be charged back: not applicable, not FALSE
        case
            when acceptance.transaction_state = 'ACCEPTED'
                then chargebacks.is_chargeback
        end                                                 as is_chargeback

    from acceptance
    left join chargebacks
        on acceptance.transaction_id = chargebacks.transaction_id

)

select * from joined