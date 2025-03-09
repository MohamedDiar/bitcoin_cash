select
    `hash`,
    size,
    virtual_size,
    version,
    lock_time,
    block_hash,
    block_number,
    block_timestamp,
    block_timestamp_month,
    input_count,
    output_count,
    input_value,
    output_value,
    is_coinbase,
    fee,
    inputs,
    outputs
    from {{ source('bitcoin_cash', 'transactions') }} as btc_cash
where btc_cash.block_timestamp_month >= date_trunc(date_sub(current_date(), interval {{ var("month_interval") }} month), month) 
order by btc_cash.block_timestamp DESC