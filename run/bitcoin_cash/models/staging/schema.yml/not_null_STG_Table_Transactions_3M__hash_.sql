select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select `hash`
from `astrafy-challenge-0001`.`staging_dataset_bitcoin`.`STG_Table_Transactions_3M`
where `hash` is null



      
    ) dbt_internal_test