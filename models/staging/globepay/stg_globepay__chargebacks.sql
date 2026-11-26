with source as (

    select * from {{ source('globepay', 'chargebacks') }}

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
        external_ref                    as transaction_id,

        -- chargeback attributes
        to_boolean(chargeback)          as is_chargeback,

        -- technical
        _load_id,
        _loaded_at

    from deduplicated

)

select * from renamed