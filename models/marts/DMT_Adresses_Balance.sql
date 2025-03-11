
-- This model calculates the "current" balance for addresses on the Bitcoin Cash blockchain.
-- It is calculated from the staging table STG_Table_Transactions_3M.
-- It excludes addresses that have participated in coinbase transactions


WITH address_transactions AS (
    -- Flattenning input transactions with addresses
    -- In cryptocurrency, when coins are spent, they become "inputs" to a transaction
    -- These inputs have negative values because they represent coins leaving an address
    SELECT
        address,
        block_timestamp,
        block_timestamp_month,
        -value AS transaction_value,  -- Negative for inputs (spending)
        is_coinbase
    FROM {{ ref('STG_Table_Transactions_3M') }},
    UNNEST(inputs) AS input,
    UNNEST(input.addresses) AS address
    WHERE input.addresses IS NOT NULL

    UNION ALL

    -- Flattenning output transactions with addresses
    -- In cryptocurrency, when coins are received, they become "outputs" to a transaction
    -- These outputs have positive values because they represent coins entering an address
    SELECT
        address,
        block_timestamp,
        block_timestamp_month,
        value AS transaction_value,   -- Positive for outputs (receiving)
        is_coinbase
    FROM {{ ref('STG_Table_Transactions_3M') }},
    UNNEST(outputs) AS output,
    UNNEST(output.addresses) AS address
    WHERE output.addresses IS NOT NULL
),

-- I used a CTE here to identify addresses with any coinbase transactions.
-- Even if an address has even one coinbase transaction it be in the CTE result set.
-- These addresses will be excluded in the main query to ensure that any address with coinbase activity is omitted from the balance calculation.
coinbase_addresses AS (
    SELECT DISTINCT
        address
    FROM address_transactions
    WHERE is_coinbase = TRUE
)

-- Then here, we calculate the current balance for all addresses, excluding those with coinbase transactions
SELECT
    address,
    SUM(transaction_value) AS current_balance,
    block_timestamp_month,
    MIN(block_timestamp) AS first_activity,
    MAX(block_timestamp) AS last_activity,
FROM address_transactions
WHERE address NOT IN (SELECT address FROM coinbase_addresses)
GROUP BY address, block_timestamp_month
ORDER BY current_balance DESC