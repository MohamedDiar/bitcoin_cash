# Bitcoin Cash Analysis with dbt and BigQuery

## Table of Contents

1.  [Introduction](#introduction)
2.  [Prerequisites](#prerequisites)
3.  [Project Structure](#project-structure)
    *   [dbt Project Configuration](#dbt-project-configuration)
    *   [Staging Model (`STG_Table_Transactions_3M`)](#staging-model-stg_table_transactions_3m)
    *   [Data Mart Model (`DMT_Adresses_Balance`)](#data-mart-model-dmt_adresses_balance)
4.  [Running It Locally](#running-it-locally)
5.  [Continuous Integration with GitHub Actions](#continuous-integration-with-github-actions)

## Introduction <a name="introduction"></a>

Bitcoin Cash is a cryptocurrency that allows more bytes to be included in each block relative to its common ancestor, Bitcoin. The public dataset ([bigquery-public-data.crypto_bitcoin_cash](https://console.cloud.google.com/marketplace/product/bitcoin-cash/crypto-bitcoin-cash?inv=1&invt=Abr8Hw)) on BigQuery contains the blockchain data in its entirety, with data pre-processed to be human-friendly and to support common use cases such as auditing, investigating, and researching the economic and financial properties of the system.

This repository contains the code and everything needed to extract the last three months of Bitcoin Cash transaction data from the BigQuery public dataset, transform it, and calculate the current balance for all non-Coinbase addresses.  It utilizes dbt (data build tool) for data transformation and modeling, and GitHub Actions for continuous integration.

## Prerequisites

Before you begin, ensure you have the following:

1.  **Google Cloud Account with Infrastructure:**
    *   A Google Cloud Platform (GCP) account.
    *   A GCP project with BigQuery enabled.
    *   BigQuery datasets for staging and data mart.
    *   For setting up the infrastructure, see my other repo [GCP Terraform Setup](https://github.com/MohamedDiar/gcp-terraform-challenge).

2.  **dbt (data build tool):**
    *   You can use either dbt Core (command-line tool) or dbt Cloud.
    *   **dbt Core Installation:**  Follow the instructions for installing dbt Core using pip: [dbt Core Installation Guide](https://docs.getdbt.com/docs/core/pip-install).
    *   **BigQuery Adapter Setup:**  Configure dbt to connect to your BigQuery project. Follow the [BigQuery Setup Guide](https://docs.getdbt.com/docs/core/connect-data-platform/bigquery-setup).  For convenience, create a `.dbt` directory in your home directory and place your `profiles.yml` there.
    
    **Note:** This repository includes a `requirements.txt` file.  After cloning, run `pip install -r requirements.txt` to install dbt Core and the BigQuery adapter. This is explained more in the [Running It Locally](#running-it-locally) section.

3.  **Python:**
    *   Python version 3.9 or higher.

## Project Structure <a name="project-structure"></a>

### dbt Project Configuration <a name="dbt-project-configuration"></a>

The `dbt_project.yml` file configures the dbt project. Key aspects include:

*   **`name: 'bitcoin_cash'`**:  Defines the project name.
*   **`profile: 'bitcoin_cash'`**: Specifies the dbt profile to use (defined in your `profiles.yml`).
*   **`vars: {month_interval: 3}`**:  This variable sets the default time window for data extraction to the last 3 months.  It's used in the staging model to filter transactions. You can override during a run by by adding e.g `--vars '{month_interval: 6}'` to the command.

* **`models`**: The relevant part in `models` is:
    ```yaml
      bitcoin_cash:
        staging:
          materialized: table
        marts:
          +schema: mart_dataset_bitcoin_cash
          materialized: table    
    ```
    This configuration tells dbt to materialize all models within the `staging` and `marts` directories as BigQuery tables.  The `marts` models will be created in a dataset named `mart_dataset_bitcoin_cash`.  This overrides any default dataset specified in your `profiles.yml`.

*   **Macros (`macros/generate_schema_name.sql`):** This macro ensures that if a custom schema is specified in dbt, it uses that exact name instead of attempting to create a new one.  If no custom schema is provided, it uses the default schema from your `profiles.yml`.

### Staging Model (`STG_Table_Transactions_3M`) <a name="staging-model-stg_table_transactions_3m"></a>

*   **File:** `models/staging/STG_Table_Transactions_3M.sql`
*   **Purpose:** Creates a staging table named `STG_Table_Transactions_3M` containing Bitcoin Cash transactions from the last 3 months (configurable via the `month_interval` variable).
*   **Logic:**
    *   Selects data from the `bigquery-public-data.crypto_bitcoin_cash.transactions` table.
    *   Filters data to include only records where `block_timestamp_month` is within the last `month_interval` months.
    *   The nested structure of `inputs` and `outputs` is preserved for performance, storage efficiency, and flexibility. Unnesting is deferred to downstream models as needed.
*  **Schema (`models/staging/schema.yml`):** Defines the schema and includes basic data quality tests:
    *   `hash`: Unique and not null.
    *   `block_hash`, `block_number`, `block_timestamp`, `block_timestamp_month`: Not null.