# Terraform State Migration Guide
## Overview
This script is designed to assist with the migration of a monolithic Terraform state to a modular design. The original implementation provisioned the infrastructure (infra), EKS cluster, and nodes under a single Terraform state. The new design segregates these into three distinct Terraform states: Infrastructure, EKS Cluster, and Nodes.

## Prerequisites
* Terraform installed.
* jq utility installed.
* Ensure you have the correct permissions to read and write to Terraform states.
* Backup your original Terraform state.

## Usage:
Ensure all prerequisites are met.

### Bootstrap the module
* Follow [Module bootstrap](../../README.md#bootstrap-module)
* Ensure `DEPLOY_DIR` is setup in accordance to previous step.

### Set variables
1. Copy Script:
  * Copy the script from bin/state-migration/migrate-states.sh to your deployment directory (DEPLOY_DIR).
  ```bash
  cp bin/state-migration/migrate-states.sh "$DEPLOY_DIR"
  ```
2. Verify Files:
  ```bash
  ls "$DEPLOY_DIR"
  ```
  * Expected scripts (there should also be a directory called `terraform` and a `README.md`):
    * migrate-states.sh
    * tf.sh
    * meta.sh
3. Append Variables to meta.sh:
  * Add the following variables to your meta.sh script:
  ```bash
  export MOD_NAME=""
  export PVT_KEY=""
  export LEGACY_DIR=""
  export LEGACY_PVT_KEY=""
  export LEGACY_STATE=""
  ```
  * Here's a brief description of each variable:
    * **MOD_NAME**: Name assigned to the module during the deployment that needs migration, i.e `module.domino_eks`.
    * **LEGACY_DIR**: The directory containing the deployment you want to migrate.
    * **LEGACY_PVT_KEY**: Path to the SSH private key used during the provisioning of the deployment you're migrating.
    * **PVT_KEY**: Path to the SSH private key. This will be used to create a copy from `LEGACY_PVT_KEY`.
    * **LEGACY_STATE**: Path to the Terraform state file for the deployment you're migrating. This file is typically named `terraform.tfstate`.

4. Run the script:
  * Change into `DEPLOY_DIR` and run the script
  ```bash
  cd $DEPLOY_DIR
  ./migrate-states.sh
  ```

Monitor the output for any errors. Upon successful completion, you should see the message "State migration completed successfully !!!", and a migrated.txt file would be generated.

## Detailed Operation
### Step 1: Migrate the EKS Cluster
In the original monolithic state, the EKS module contained both the EKS cluster configuration and the node groups. The first step of the migration process is to separate out the EKS cluster configuration. This is done by the migrate_cluster_state function.

### Step 2: Migrate Infrastructure
Post the EKS cluster migration, the remaining state primarily consists of infrastructure components. The migrate_infra_state function handles this migration.

**Note**: During the infrastructure state migration, the IAM role policy attachment specific to route53 ('module.infra.aws_iam_role_policy_attachment.route53[0]') is removed. This policy attachment was later integrated into the EKS module by simply adding it to an existing policy list.

### Step 3: Migrate Nodes
Following the migration of the EKS cluster, the nodes' state is yet to be segregated. The migrate_nodes_state function is responsible for this. It uses a list of resource definitions (nodes_resource_definitions) as a filter to selectively pull out node-related resources from the EKS module state, and then transfer them to the separate nodes module.

## Functions:
* **migrate_cluster_state**: Migrates the EKS cluster configuration.
* **migrate_infra_state**: Migrates infrastructure components and removes the route53 IAM role policy attachment.
* **migrate_nodes_state**: Migrates the nodes using a predefined list of resources.
* **copy_files**: Copies essential files, such as private keys.
* **adjust_vars**: Adjusts Terraform variables if necessary.
* **refresh_all**: Refreshes all new Terraform states to ensure they are up-to-date.
* **cleanup**: Deletes any backup files created during the state migration.
* **migrate_all**: A wrapper function to execute the state migration functions.

## Important Note:
Always maintain backups of your original Terraform states before initiating any state migration. There's a potential risk of corruption or data loss during migration. In case of issues, the backup ensures that you can revert to the original state.
