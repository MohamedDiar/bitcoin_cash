select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select block_timestamp
from `bigquery-public-data`.`crypto_bitcoin_cash`.`transactions`
where block_timestamp is null



      
    ) dbt_internal_test