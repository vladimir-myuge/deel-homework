with source as (

    select * from {{ source('globepay', 'acceptance') }}

),

deduplicated as (

    -- RAW keeps every loaded file version; take the latest version of each transaction
    select *
    from source
    qualify row_number() over (
        partition by external_ref
        order by _file_last_modified desc, _loaded_at desc
    ) = 1

),

renamed as (

    select
        -- ids
        external_ref                                  as transaction_id,
        ref                                           as event_ref,

        -- timestamps
        to_timestamp_ntz(date_time)                   as transaction_at,

        -- transaction attributes
        upper(trim(state))                            as transaction_state,
        to_boolean(cvv_provided)                      as is_cvv_provided,

        -- amounts
        to_number(amount, 18, 2)                      as amount_local,
        upper(trim(currency))                         as currency_code,
        -- rates JSON is quoted as local currency units per 1 USD (e.g. EUR 0.926);
        -- keep only the rate of the transaction currency
        parse_json(rates)[upper(trim(currency))]::number(38, 10)
                                                      as local_per_usd_rate,

        -- geography
        case upper(trim(country))
            when 'UK' then 'GB'                       -- normalize to ISO 3166-1
            else upper(trim(country))
        end                                           as card_country_code,

        -- technical
        _load_id,
        _loaded_at

    from deduplicated

),

converted as (

    select
        *,
        (amount_local / local_per_usd_rate)::number(38, 6)   as amount_usd

    from renamed

)

select * from converted