# Terraform Module for EKS Setup. Optimized for Domino Installation

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/dominodatalab/terraform-aws-eks/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/dominodatalab/terraform-aws-eks/tree/main)

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

Always refer to each section's respective README or documentation for detailed information and usage guidelines.

## Prerequisites
* A host with `ssh-keygen` installed
* [awscli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
* [terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started#install-terraform) >= v1.3.0
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) cli >= 1.25.0
* [helm](https://helm.sh/docs/intro/install/) >= 3.9


## Bootstrap module

### Set your desired module version and deployment directory:
Update the following values:
```bash
MOD_VERSION='v3.0.0'
DEPLOY_DIR='domino-deploy'
```
:warning: Ensure the DEPLOY_DIR does not exist or is currently empty.

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

If successful, you should get a structure similar to this:
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

**Note**: It's recommended to go through the README.md within the DEPLOY_DIR for further details.

### Update modules version
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


### Review and Configure `infra.tfvars`
Your initial setup is guided by the Terraform variables in `domino-deploy/terraform/infra.tfvars`. Ensure you review and modify this file as needed.


### Create SSH Key pair
The deployment requires an SSH key. Update the `ssh_pvt_key_path` variable in `domino-deploy/terraform/infra.tfvars` with the full path of your key.

If you don't have an SSH key, you can create one using:
```bash
 ssh-keygen -q -P '' -t rsa -b 4096 -m PEM -f domino.pem && chmod 600 domino.pem
```
