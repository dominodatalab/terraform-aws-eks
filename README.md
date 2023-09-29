# Terraform Module for EKS Setup. Optimized for Domino Installation

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/dominodatalab/terraform-aws-eks/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/dominodatalab/terraform-aws-eks/tree/main)

:warning: Important: If you have existing infrastructure created with a version of this module < `v3.0.0` you will need to migrate your state before updating the module to versions >= `v3.0.0`. See [state-migration](./bin/state-migration/README.md#terraform-state-migration-guide) for more details.

:warning: Important: Starting from version v2.0.0, this module has KMS enabled by default. If you utilized a prior version without setting the kms.enabled variable, ensure you define kms.enabled = false to preserve your existing state. Failing to do so will default to kms.enabled = true, potentially causing the destruction of your existing infrastructure and possible data loss.


## Repository Structure

* examples/:
  * Purpose: Acts as an intuitive guide for module users.
  * Contents: Features end-user Terraform configurations along with illustrative `tfvars` samples, showcasing potential setups.

* modules/:
  * Purpose: Houses the primary modules that orchestrate the provisioning process.
  * Contents: These modules act as the main entry points for the setup of the underlying infrastructure beneath the **EKS** cluster and its associated components.

* tests/:
  * Purpose: Ensures the integrity and functionality of the module.
  * Contents: Contains automation-driven tests intended for validation and continuous integration (CI) checks.

* bin/state-migration/:
  * Purpose: Contains automation to perform terraform state migration, from a monolithic module to a multi-module structure.
  * Contents: Script and documentation to perform terraform state migration.

Always refer to each section's respective README or documentation for detailed information and usage guidelines.

## Prerequisites
* A host with `ssh-keygen` installed
* [awscli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started#install-terraform) >= v1.3.0
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) cli >= 1.25.0
* [helm](https://helm.sh/docs/intro/install/) >= 3.9
* [hcledit](https://github.com/minamijoyo/hcledit)
* bash >= 4.0


## Bootstrap module
We first need to setup the module structure.

### 1. Set your desired module version and deployment directory:
Set up the following environment variables.
Update the following values(Using `v3.0.0` and `domino-deploy` as an example):
```bash
MOD_VERSION='v3.0.0'
DEPLOY_DIR='domino-deploy'
```
:warning: Ensure the `DEPLOY_DIR` does not exist or is currently empty.

Create the `DEPLOY_DIR` and use terraform to bootstrap the module from source.

```bash
mkdir -p "$DEPLOY_DIR"
terraform -chdir="$DEPLOY_DIR" init -backend=false -from-module="github.com/dominodatalab/terraform-aws-eks.git//examples/deploy?ref=${MOD_VERSION}"
```
Ignore this message:

```
Terraform initialized in an empty directory!

The directory has no Terraform configuration files. You may begin working
with Terraform immediately by creating Terraform configuration files.
```

:white_check_mark: If successful, you should get a structure similar to this:

```bash
domino-deploy
├── README.md
├── meta.sh
├── set-mod-version.sh
├── terraform
│   ├── cluster
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── cluster.tfvars
│   ├── infra
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── infra.tfvars
│   ├── nodes
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── nodes.tfvars
└── tf.sh
```

**Note**: It's recommended to go through the README.md within the `DEPLOY_DIR` for further details.

### 2. Update modules version
You can update the modules version using a script or manually.

#### Using script
You can update the modules version using the `set-mod-version.sh`

##### Prerequisites
* [hcledit](https://github.com/minamijoyo/hcledit)

#### Command

```bash
./set-mod-version.sh "$MOD_VERSION"
```

#### Manually
Update the modules' source with the `MOD_VERSION` value.

For example if `MOD_VERSION=v3.0.0`

* **infra/main.tf** : Update `module.infra.source` from `"./../../../../modules/infra"` to `github.com/dominodatalab/terraform-aws-eks.git//modules/infra?ref=v3.0.0`
* **cluster/main.tf** : Update `module.eks.source` from `"./../../../../modules/eks"` to `github.com/dominodatalab/terraform-aws-eks.git//modules/eks?ref=v3.0.0`
* **nodes/main.tf** : Update `module.nodes.source` from `"./../../../../modules/nodes"` to `github.com/dominodatalab/terraform-aws-eks.git//modules/nodes?ref=v3.0.0`


### 3. Review and Configure `tfvars`

Consult available variables within each of the modules `variables.tf`

* `domino-deploy/terraform/infra/variables.tf`
  * `deploy_id`
  * `region`
  * `tags`
  * `network`
  * `default_node_groups`
  * `additional_node_groups`
  * `storage`
  * `kms`
  * `eks`
  * `ssh_pvt_key_path`
  * `route53_hosted_zone_name`
  * `bastion`

* `domino-deploy/terraform/cluster/variables.tf`
  * `eks`
  * `kms_info`: :warning: Variable is only intended for migrating infrastructure, it is not recommended to set it.

* `domino-deploy/terraform/nodes/variables.tf`
  * `default_node_groups`
  * `additional_node_groups`

Configure terraform variables at:

* `domino-deploy/terraform/infra.tfvars`
* `domino-deploy/terraform/cluster.tfvars`
* `domino-deploy/terraform/nodes.tfvars`

**NOTE**: The `eks` configuration is required in both the `infra` and `cluster` modules because the Kubernetes version is used for installing the `kubectl` binary on the bastion host. Similarly, `default_node_groups` and `additional_node_groups` must be defined in both the `infra` and `nodes` modules, as the `availability zones` for the `nodes` are necessary for setting up the network infrastructure.


### 4. Create SSH Key pair
The deployment requires an SSH key. Update the `ssh_pvt_key_path` variable in `domino-deploy/terraform/infra.tfvars` with the full path of your key (we recommend you place your key under the `domino-deploy/terraform` directory).

If you don't have an SSH key, you can create one using:
```bash
 ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f domino.pem && chmod 600 domino.pem
```

### 5. Deploy
#### 1. Set `AWS` credentials and verify.
```bash
aws sts get-caller-identity
```

#### 2. Change into `domino-deploy`(or whatever your `DEPLOY_DIR` is)

```bash
cd domino-deploy
```

#### 3. Plan and Apply.
:warning: It is recommended to become familiar with the `tf.sh` [usage](./examples/deploy/README.md#usage).

At this point all requirements should be set to provision the infrastructure.

For each of the modules, run `init`, `plan`, inspect the plan, then `apply` in the following order:

1. `infra`
2. `cluster`
3. `nodes`

Note: You can use `all` instead but it is recommended that the `plan`  and `apply` be done one at a time, so that the plans can be carefully examined.

1. Init all

```bash
./tf.sh all init
```

2. `infra` plan.

```bash
./tf.sh infra plan
```
3. :exclamation: Carefully inspect the actions detailed in the `infra` plan for correctness, before proceeding.

4. `infra` apply

```bash
./tf.sh infra apply
```

5. `cluster` plan

```bash
./tf.sh cluster plan
```

6. :exclamation: Carefully inspect the actions detailed in the `cluster` plan for correctness, before proceeding.

7. `cluster` apply

```bash
./tf.sh cluster apply
```

8. nodes plan

```bash
./tf.sh nodes plan
```
9.  :exclamation: Carefully inspect the actions detailed in the `nodes` plan for correctness, before proceeding.

10.  `nodes` apply

```bash
./tf.sh nodes apply
```

### At this point the infrastructure has been created.


### Interacting with Kubernetes
To interact with the EKS Control Plane using kubectl or helm commands, you'll need to set up both the appropriate AWS credentials and the KUBECONFIG environment variable. If your EKS cluster is private, you can use mechanisms provided by this module to establish an SSH tunnel through a Bastion host. However, if your EKS endpoint is publicly accessible, you only need to follow steps 1-3 below.

For ease of setup, use the k8s-functions.sh script, which contains helper functions for cluster configuration.

#### Steps
1. Verify AWS Credentials: Ensure your AWS credentials are properly configured by running the following command:

```bash
aws sts get-caller-identity
```

2. Import Functions: Source the k8s-functions.sh script to import its functions into your current shell.

```bash
source k8s-functions.sh
```

3. Set `KUBECONFIG`: Use the check_kubeconfig function to set the `KUBECONFIG` environment variable appropriately.

```bash
check_kubeconfig
```

4. Open SSH Tunnel (Optional): If your EKS cluster is private, open an SSH tunnel through the Bastion host by executing:

```bash
open_ssh_tunnel_to_k8s_api
```

5. Close SSH Tunnel: To close the SSH tunnel, run:

```bash
close_ssh_tunnel_to_k8s_api
```

### Retrieve Configuration Values for `domino.yaml`.
Run the command below to generate a list of infrastructure values. These values are necessary for configuring the domino.yaml file, which is in turn used for installing the Domino product.

```bash
./tf.sh infra output domino_config_values
```

This command will output a set of key-value pairs, extracted from the infrastructure setup, that can be used as inputs in the domino.yaml configuration file.


## Domino Backups
If you would like to increase the safety of data stored in AWS S3 and EFS by backing them up into another account (Accounts under same AWS Organization), use the [terraform-aws-domino-backup](https://github.com/dominodatalab/terraform-aws-domino-backup) module:

1. Define another provider for the backup account in `main.tf` for infra module.

Location
```bash
domino-deploy
├── terraform
│   ├── infra
│   │   ├── main.tf
```

Content
```
provider "aws" {
  alias   = "domino-backup"
  region  = <<Backup Account Region>>
}
```

2. Add the following content

```
module "backups" {
  count  = 1
  source = "github.com/dominodatalab/terraform-aws-domino-backup.git?ref=v1.0.10"
  providers = {
    aws.dst = aws.domino-backup
  }
}
```
