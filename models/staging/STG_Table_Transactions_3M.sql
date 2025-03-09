-- Model to creates the staging table

-- This staging table creates a filtered view of Bitcoin Cash transactions from the last 3 months.

-- Here I used the query below to maintain the nested structure of inputs and outputs for the reasons state below:

-- QUERY PERFORMANCE: Unnesting large arrays in BigQuery can significantly increase query processing time and resource usage

-- STORAGE EFFICIENCY: While BigQuery storage is relatively inexpensive, the unnested approach would create a very much larger table potentially more than 4x larger 

-- FLEXIBILITY: Also very important, the nested structure allows downstream use cases to unnest only what they need, which is more efficient than having all fields unnested regardless of usage


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


-- An alternative "unnested" approach (which I commented out below) which creates a more direct access to the nested fields but at the cost of increased storage (more than double it).
-- This approach would unnest inputs and outputs into separate columns, which could be useful in specific scenarios such as:

-- When the volume of transactions is relatively small. But with bitcoin transactions, we can have quite a lot in a short time.
-- When the majority of downstream analytics require direct access to unnested fields. But if only one to around four/five fields are needed,then the unnested approach might not be necessary.
-- When query performance (speed) on the unnested fields is more important than storage costs.


-- select
--     `hash`,
--     size,
--     virtual_size,
--     version,
--     lock_time,
--     block_hash,
--     block_number,
--     block_timestamp,
--     block_timestamp_month,
--     input_count,
--     output_count,
--     input_value,
--     output_value,
--     is_coinbase,
--     fee,
--     unnested_inputs.index as input_index,
--     unnested_inputs.spent_transaction_hash as input_spent_tx_hash,
--     unnested_inputs.spent_output_index as input_spent_output_index,
--     unnested_inputs.script_asm as input_script_asm,
--     unnested_inputs.script_hex as input_script_hex,
--     unnested_inputs.sequence as input_sequence,
--     unnested_inputs.required_signatures as input_required_signatures,
--     unnested_inputs.type as input_address_type,
--     unnested_inputs.addresses as input_addresses,
--     unnested_inputs.value as input_amount,
--     unnested_outputs.index as output_index,
--     unnested_outputs.script_asm as output_script_asm,
--     unnested_outputs.script_hex as output_script_hex,
--     unnested_outputs.required_signatures as output_required_signatures,
--     unnested_outputs.type as output_address_type,
--     unnested_outputs.addresses as output_addresses,
--     unnested_outputs.value as output_amount
--    from {{ source('bitcoin_cash', 'transactions') }} as btc_cash
-- left join unnest(btc_cash.inputs) as unnested_inputs
-- left join unnest(btc_cash.outputs) as unnested_outputs
-- where btc_cash.block_timestamp_month >= date_trunc(date_sub(current_date(), interval {{ var("month_interval") }} month), month) 
-- order by btc_cash.block_timestamp DESC
