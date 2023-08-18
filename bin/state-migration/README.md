# Terraform State Migration Guide
## Overview
This script is designed to assist with the migration of a monolithic Terraform state to a modular design. The original implementation provisioned the infrastructure (infra), EKS cluster, and nodes under a single Terraform state. The new design segregates these into three distinct Terraform states: Infrastructure, EKS Cluster, and Nodes.

## Prerequisites
* Terraform installed.
* jq utility installed.
* Ensure you have the correct permissions to read and write to Terraform states.
* Backup your original Terraform state.

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

## Usage:
Ensure all prerequisites are met.

Navigate to the directory containing the script.

Run the script:

```bash
./migrate-states.sh
```

Monitor the output for any errors. Upon successful completion, you should see the message "State migration completed successfully !!!", and a migrated.txt file would be generated.

## Important Note:
Always maintain backups of your original Terraform states before initiating any state migration. There's a potential risk of corruption or data loss during migration. In case of issues, the backup ensures that you can revert to the original state.
