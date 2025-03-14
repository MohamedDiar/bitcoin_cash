# Bitcoin Cash Analysis with dbt and BigQuery

## Table of Contents

1.  [Introduction](#introduction)
2.  [Prerequisites](#prerequisites)
3.  [Project Structure](#project-structure)
    *   [dbt Project Configuration](#dbt-project-configuration)
    *   [Staging Model (`STG_Table_Transactions_3M`)](#staging-model-stg_table_transactions_3m)
    *   [Data Mart Model (`DMT_Adresses_Balance`)](#data-mart-model-dmt_adresses_balance)
4.  [Caveats](#caveats)
5.  [Running It Locally](#running-it-locally)
6.  [Continuous Integration with GitHub Actions](#continuous-integration-with-github-actions)

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

## Caveats <a name="caveats"></a>

It's important to note the last modification date of the `bigquery-public-data.crypto_bitcoin_cash.transactions` table.  As shown in the image below, the table was last modified on **May 14, 2024, 7:39:36 PM UTC+2**:

![Table Info](/image/BCT_dataset_last_edit.png)  

Because the dataset's last update was in May 2024, running the dbt models with the default `month_interval` of 3 (as defined in `dbt_project.yml`) will result in zero rows being processed, given that the current date is in March 2025. The date filtering in `STG_Table_Transactions_3M.sql` will look for transactions within the last 3 months, which won't find anything more recent than May 2024.

To address this and ensure that data is populated in both the staging (`STG_Table_Transactions_3M`) and mart (`DMT_Adresses_Balance`) tables, you need to adjust the `month_interval` variable.  Increase it to at least 10 months to include data from May 2024.

You can do this in two ways:

1.  **Modify `dbt_project.yml` directly:** Change the `month_interval` variable in your `dbt_project.yml` file:

    ```yaml
    vars:
      month_interval: 10
    ```
    Then, run `dbt run` as usual.

2.  **Override the variable during `dbt run`:**  Use the `--vars` flag to override the default value when running dbt:

    ```bash
    dbt run --vars '{month_interval: 10}'
    ```
    Or, if you are targeting a specific model:

    ```bash
     dbt run --models staging --vars '{month_interval: 10}'
     dbt run --models marts --vars '{month_interval: 10}'

    ```

By increasing the `month_interval` to 10 or more, you'll ensure that the queries include the most recent available data from the public Bitcoin Cash dataset.

## Running It Locally <a name="running-it-locally"></a>

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/MohamedDiar/bitcoin_cash.git
    cd https://github.com/MohamedDiar/bitcoin_cash.git
    ```

2.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

3.  **Test the connection:**
    ```bash
    dbt debug
    ```

4.  **Run the staging model:**
    ```bash
    dbt run --models staging
    ```

5.  **Run the data mart model:**
    ```bash
    dbt run --models marts
    ```
    Alternatively, you can also execute all the models with `dbt run`.

6.  Run dbt tests (defined in `schema.yml` files):
    ```bash
    dbt test
    ```

## Continuous Integration with GitHub Actions <a name="continuous-integration-with-github-actions"></a>

This project uses GitHub Actions for continuous integration (CI).  The CI workflow automates the following steps:

1.  **Builds and tests the dbt project:**  This ensures that any changes made to the dbt models do not introduce errors.
2.  **Generates dbt documentation:**  Creates up-to-date documentation for the dbt project.
3.  **Deploys dbt documentation to GitHub Pages:**  Makes the documentation publicly accessible.

### Setting up GitHub Actions

To use the provided GitHub Actions workflow, you'll need to configure secrets and variables in your GitHub repository settings. The workflow is triggered on pull requests and pushes to the `main` or `master` branches.

#### 1. Create `gh-pages` Branch and Enable GitHub Pages

*   **Create the `gh-pages` branch:**
    This branch will host the dbt documentation website. Create the branch and add a sample file such as a Readme.md so that the branch will not be empty.
    ```bash
    git checkout -b gh-pages
    git push origin gh-pages
    ```

*   **Enable GitHub Pages:**
    1.  Go to your repository's settings.
    2.  Click on "Pages" in the left sidebar.
    3.  Under "Source", select the `gh-pages` branch and the `/ (root)` directory.
    4.  Click "Save".
    For detailed instructions, refer to the official GitHub Pages documentation: [Configuring a publishing source for your GitHub Pages site](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)

#### 2. Configure GitHub Secrets and Variables

The workflow uses secrets and variables to access your Google Cloud project and BigQuery dataset.  You'll need to store these securely in your repository's settings.

*   **Secrets:**
    *   `GCP_SA_KEY`:  Your Google Cloud service account key (JSON format). This service account needs permissions to run BigQuery jobs and access your BigQuery datasets.

*   **Variables:**
    *   `GCP_PROJECT_ID`: Your Google Cloud project ID.
    *   `GCP_DATASET_ID`: The name of your BigQuery dataset where the dbt models will be created (e.g., `mart_dataset_bitcoin_cash`).

**Adding Secrets and Variables (Manual Method):**

1.  Go to your repository's settings.
2.  Click on "Secrets and variables" and then "Actions" in the left sidebar.
3.  Click "New repository secret" or "New repository variable".
4.  Enter the name of the secret/variable (e.g., `GCP_SA_KEY`) and its value.
5.  Click "Add secret" or "Add Variable".

For more detailed instructions, refer to the GitHub documentation:
    *   Secrets: [Creating encrypted secrets for a repository](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository)
    *   Variables: [Variables](https://docs.github.com/en/actions/learn-github-actions/variables)

**Adding Secrets and Variables (GitHub CLI - Recommended):**

If you have the GitHub CLI installed, you can add secrets and variables directly from your terminal. This is generally the easiest and most secure method.

1.  **Authenticate with the GitHub CLI:**
    ```bash
    gh auth login
    ```

2.  **Set the service account key secret:**
    Replace `owner/repo` with your GitHub username and repository name, and `service-account-key.json` with the path to your service account key file.
    ```bash
    gh secret set GCP_SA_KEY --repo owner/repo --body "$(base64 -w 0 service-account-key.json)"
    ```

3.  **Set the project ID variable:**
    Replace `owner/repo` with your GitHub username and repository name, and `your_project_id` with your Google Cloud project ID.
    ```bash
    gh variable set GCP_PROJECT_ID --repo owner/repo --body "your_project_id"
    ```
4. **Set the Bigquery staging dataset ID variable.**
   Replace `owner/repo` and `your_dataset_staging_id` accordingly.
    ```bash
    gh variable set GCP_DATASET_ID --repo owner/repo --body "your_dataset_staging_id"
    ```

### GitHub Actions Workflow Explanation (`.github/workflows/dbt.build.yaml`)

The workflow file defines the CI pipeline. Here's a breakdown:

*   **`name: DBT CI`**: The name of the workflow.
*   **`on`**: Specifies the events that trigger the workflow:
    *   `pull_request`: Triggered on any pull request.
    *   `push`: Triggered on pushes to the `main` or `master` branches.
*   **`jobs`**: Defines the jobs to be executed.
    *   **`dbt`**: The name of the job.
        *   **`runs-on: ubuntu-latest`**: Specifies the runner environment (Ubuntu).
        *   **`permissions: contents: write`**:  Grants write access to the repository contents.  This is required for deploying the dbt documentation to GitHub Pages.
        *   **`steps`**:  The sequence of steps to execute:
            1.  **`Checkout code`**: Checks out the repository's code.
            2.  **`Set up Python`**: Sets up Python 3.10.
            3.  **`Install dependencies`**: Installs dbt and its dependencies using `requirements.txt`.
            4.  **`Google Auth`**: Authenticates with Google Cloud using the `GCP_SA_KEY` secret.  This step uses the `google-github-actions/auth@v1` action. The `export_environment_variables: true` is important, as this makes the credentials available to dbt.
            5.  **`Create profiles.yml`**: Creates the `~/.dbt/profiles.yml` file, configuring dbt to connect to BigQuery using OAuth. This utilizes the `GCP_PROJECT_ID` and `GCP_DATASET_ID` variables. The target is set to `ci`.
            6.  **`Debug DBT`**: Runs `dbt debug` to check the connection and configuration.
            7.  **`Run DBT`**: Executes `dbt run` to build the dbt models.
            8.  **`Test DBT`**: Runs `dbt test` to execute the data tests defined in your `schema.yml` files.
            9.  **`Generate dbt docs`**:  Generates the dbt documentation using `dbt docs generate`.
            10. **`Deploy dbt docs to GitHub Pages`**:  Deploys the generated documentation (located in the `target` directory) to GitHub Pages using the `JamesIves/github-pages-deploy-action@v4` action. The `branch: gh-pages` setting specifies the deployment branch, and `clean: true` ensures that deleted files are removed from the `gh-pages` branch.
