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
