select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select `hash`
from `bigquery-public-data`.`crypto_bitcoin_cash`.`transactions`
where `hash` is null



      
    ) dbt_internal_test