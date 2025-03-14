select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select address
from `astrafy-challenge-0001`.`mart_dataset_bitcoin_cash`.`DMT_Adresses_Balance`
where address is null



      
    ) dbt_internal_test