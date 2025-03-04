# Module Migration Script for terraform-aws-eks

This(`module-update.sh`) script automates the process of updating module versions for infrastructure and EKS clusters. It handles backups, updates to tfvars, and necessary imports and deprecations. It was tested updating from version `v3.0.5` to `v3.22.0`.

## Prerequisites

* Ensure the script is placed in the parent directory of your deployment folder.
* Verify  [hcledit](https://github.com/minamijoyo/hcledit?tab=readme-ov-file#install), [tfvar](https://github.com/shihanng/tfvar?tab=readme-ov-file#installation), [aws-cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions) and [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli#install-terraform) are installed.

* **:warning: IMPORTANT: Make sure to apply all changes in the current configuration to eliminate any drift not related to the module update.**


## Steps

1. Copy the script to the parent folder of your deployment folder.

  ```shell
  tree .
  .
  ├── domino-deploy-dir
  └── module-update.sh
  ```

1. Set environment variables `DEPLOY_DIR`, `AWS_REGION` and `MOD_VERSION`:
   1. `DEPLOY_DIR`: Deployment directory name.
   2. `AWS_REGION`: Region where the module is deployed.
   3. `MOD_VERSION`: the version of the module to upgrade to.

      ```shell
      export DEPLOY_DIR="domino-deploy-dir"
      export AWS_REGION="us-east-1"
      export MOD_VERSION="v3.22.0"
      ```

2. The script will perform the following steps when passing the `update` argument:
   1. Download the new version of the module onto a a new directory which will be later deleted and set the module version to `MOD_VERSION`.
   2. Create a backup copy of the current directory(i.e `domino-deploy-dir-BACKUP-24-10-21`)
   3. Copy the `*.tf` and `*.sh` from the new module onto the existing directory.
   4. Update the `*.tfvars` files with the defaults from the module while preserving existing values.
   5. Attempts to perform corrections needed.
   6. Delete the directory used for the initialization of the new module.
3. Manual actions required.
   1. if your EKS cluster has the `vpc-cni` addon installed, you need to edit `${DEPLOY_DIR}/terraform/cluster.tfvars` and to the list of addons. For example:
   ```hcl
    cluster_addons     = ["coredns", "kube-proxy", "vpc-cni"]
   ```

4. Run the Migration script.

```shell
./module-update.sh update
```
5. Move to the deployment directory and initialize components.
```shell
cd "$DEPLOY_DIR"
./tf.sh all init
```
6. Plan, **Review Plan** and Apply each component.

### Infra

`./tf.sh infra plan`

   * :warning: REVIEW `infra` plan

  **Whats expected**

  Expected Destroys:
  ```shell
  module.infra.module.storage.aws_s3_bucket_ownership_controls.monitoring will be destroyed
  module.infra.module.storage.aws_s3_bucket_acl.monitoring will be destroyed
  ```



  **if MOD_VERSION >= https://github.com/dominodatalab/terraform-aws-eks/releases/tag/v3.25.0**

  The EFS mountpoints will be imported using a different index, `module.infra.module.storage.aws_efs_mount_target.eks[0]` -> `module.infra.module.storage.aws_efs_mount_target.eks_cluster["deployid-private-us-west-2a"]`

```shell
  Terraform will perform the following actions:
 # module.infra.module.storage.aws_efs_mount_target.eks[0] will no longer be managed by Terraform, but will not be destroyed
 # (destroy = false is set in the configuration)
 . resource "aws_efs_mount_target" "eks" {
        id                     = "fsmt-1234556666"
        # (11 unchanged attributes hidden)
    }

 # module.infra.module.storage.aws_efs_mount_target.eks[1] will no longer be managed by Terraform, but will not be destroyed
 # (destroy = false is set in the configuration)
 . resource "aws_efs_mount_target" "eks" {
        id                     = "fsmt-244444444"
        # (11 unchanged attributes hidden)
    }

  # module.infra.module.storage.aws_efs_mount_target.eks_cluster["deployid-private-us-west-2a"] will be imported
    resource "aws_efs_mount_target" "eks_cluster" {
        id                     = "fsmt-1234556666"
    }

  # module.infra.module.storage.aws_efs_mount_target.eks_cluster["deployid-private-us-west-2b"] will be imported
    resource "aws_efs_mount_target" "eks_cluster" {
        id                     = "fsmt-244444444"
    }

# module.infra.module.storage.aws_efs_file_system.eks[0] will be updated in-place
~ resource "aws_efs_file_system" "eks" {
    ~ tags                            = {
        + "migrated" = "aws_efs_mount_target"
      }
    ~ tags_all                        = {
        + "migrated"       = "aws_efs_mount_target"
          # (5 unchanged elements hidden)
      }
      # (13 unchanged attributes hidden)
      # (1 unchanged block hidden)
  }

Plan: 2 to import, 0 to add, 1 to change, 0 to destroy.
```

### :warning: IMPORTANT: There should be no destroys as a result of the aws_efs_mount_target migration.

if there are any errors using the `module-update.sh` to create the `aws_efs_mount_target` imports, just create a file named `imports.tf` on the `terraform/infra/` directory such that it imports each of the EFS mountpoints for example:

```hcl
  import {
    to = module.infra.module.storage.aws_efs_mount_target.eks_cluster["deployid-private-us-west-2a"] ## where deployid-private-us-west-2a is the subnet name for fsmt-1234556666
    id = "fsmt-1234556666"
  }
  import {
    to = module.infra.module.storage.aws_efs_mount_target.eks_cluster["deployid-private-us-west-2b"]
    id = "fsmt-244444444"
  }
```



  **if MOD_VERSION >= https://github.com/dominodatalab/terraform-aws-eks/releases/tag/v3.6.0**

```shell
# │ Warning: Some objects will no longer be managed by Terraform
# │
# │ If you apply this plan, Terraform will discard its tracking information for the following objects, but it will not delete them:
# │  - module.infra.aws_iam_policy.route53[0]

```

### :warning: IMPORTANT: Examine plan for unexpected destroys

* Once the plan has been reviewed and deemed safe proceed to apply:

`./tf.sh infra apply`


### Cluster

`./tf.sh cluster plan`

   * :warning: REVIEW `cluster` plan
  **Whats expected**

  Expected Destroys:

  ```
   # module.eks.aws_eks_addon.vpc_cni will no longer be managed by Terraform, but will not be destroyed
   # module.eks.module.k8s_setup[0].local_file.templates["eni_config"] will be destroyed
  ```

  **if MOD_VERSION >= https://github.com/dominodatalab/terraform-aws-eks/releases/tag/v3.5.0**
  ```shell
  # │ Warning: Some objects will no longer be managed by Terraform
  # │
  # │ If you apply this plan, Terraform will discard its tracking information for the following objects, but it will not delete them:
  # │  - module.eks.aws_eks_addon.vpc_cni
  ```
### :warning: IMPORTANT: Examine plan for unexpected destroys

* Once the plan has been reviewed and deemed safe proceed to apply:

`./tf.sh cluster apply`


### Nodes

`./tf.sh nodes plan`

If you see this error:

```shell
Error: Configuration for import target does not exist
│
│ The configuration for the given import module.nodes.aws_eks_addon.pre_compute_addons["vpc-cni"] does not exist. All target instances must have an associated configuration to be imported.
╵
```

It is because `vpc-cni` is not in the list of EKS addons but there is an import for it.
Add the `vpc-cni` to the list of EKS addons, example(you may have different addons, just make sure `vpc-cni` is in the list):
```hcl
eks = {
  cluster_addons     = ["coredns", "kube-proxy","vpc-cni"]
}
```
After the `terraform/cluster.tfvars` has been updated run `./tf.sh cluster apply` to update the outputs which are leveraged by the `nodes` module.

:warning: In the unlikely scenario that you do not want to delete the `vpc-cni` addon remove the `terraform/nodes/imports.tf` file.



* :warning: REVIEW `nodes` plan

  **Whats expected**

**if MOD_VERSION >= https://github.com/dominodatalab/terraform-aws-eks/releases/tag/v3.5.0**
```shell
# module.nodes.aws_eks_addon.pre_compute_addons["vpc-cni"] will be updated in-place
# (imported from "mhekstest1:vpc-cni")
```

### :warning: IMPORTANT: Examine plan for unexpected destroys

* Once the plan has been reviewed and deemed safe proceed to apply:
`./tf.sh nodes apply`

## Changes

* The configuration behind `route53_hosted_zone_name` has been deprecated in favor or IRSA.
* The `vpc-cni` EKS addon configuration has been moved onto the `nodes` module.


## Manual action required

1. if you were using the `route53_hosted_zone_name`, by default the module will not delete the IAM role and policy attached to the nodes, but in order to complete the setup the following annotation needs to be set in the `external-dns` service account. You can achieve this by adding the following release_overrides in the `domino.yaml`.
    ```yaml
    release_overrides:
      external-dns:
        chart_values:
          serviceAccount:
            annotations:
              eks.amazonaws.com/role-arn: <arn for role named ‘<deploy_id>-external-dns’>
              eks.amazonaws.com/sts-regional-endpoints: 'true'
    ```
   1. The value of the role(`eks.amazonaws.com/role-arn:`) for the `external_dns` service account can be obtained from the `cluster` output.
      ```bash
        ./tf.sh cluster output external_dns_irsa_role_arn
      ```
