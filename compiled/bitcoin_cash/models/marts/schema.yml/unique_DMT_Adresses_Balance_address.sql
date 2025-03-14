
    
    

with dbt_test__target as (

  select address as unique_field
  from `astrafy-challenge-0001`.`mart_dataset_bitcoin_cash`.`DMT_Adresses_Balance`
  where address is not null

)

select
    unique_field,
    count(*) as n_records

from dbt_test__target
group by unique_field
having count(*) > 1


