# Terraform Multi-Module Management

## Overview
The `tf.sh` script provides a convenient method to manage multiple Terraform configurations for various components of a system. The primary modules managed by this script include `infra`, `cluster`, and `nodes`. These components might represent different layers of an infrastructure deployment. Similarly the `set-mod-version.sh` script helps to set the source module version on all three modules(`infra`, `cluster`, and `nodes`), see [README](../../README.md#Using_script).

## Pre-requisites
* Ensure that `terraform` is installed and accessible in your path.
* Ensure that `jq`, a command-line JSON processor, is installed.

## Directory Structure
The script expects the following directory structure:
```
deploy
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

* Each subdirectory under `terraform` (e.g., `infra`, `cluster`, `nodes`) should contain its respective Terraform configurations.
* Each component is expected to have a corresponding `.tfvars` file at the `terraform` directory. For instance, for the `infra` component, there should be an `terraform/infra.tfvars` file.
* Each of component's state and output(when the `output` command is invoked) is saved in the `terraform` directory:

```bash
└─ deploy/terraform
   ├── cluster.outputs
   ├── cluster.tfstate
   ├── infra.outputs
   ├── infra.tfstate
   ├── nodes.outputs
   └── nodes.tfstate
```
## Variables structure

See [README](../../README.md#3-review-and-configure-tfvars)

## Usage

To use the script, invoke it with the desired command and component:

```bash
./tf.sh <component> <command>
```

* **component**: The component parameter refers to the specific section of your architecture that you wish to target with a command. Supported components include `infra`, `cluster`, `nodes`, and `all`. Selecting all will execute the command across `infra`, `cluster` and `nodes`.
  The script uses the component parameter to identify corresponding Terraform directories and to name both the Terraform variables file (`terraform/${component}.tfvars`) and the Terraform state file (`terraform/${component}.tfstate`). If you create a custom folder named `mydir` that includes your Terraform configuration, setup a terraform variables file(`terraform/mydir.tfstate`), and state file(`terraform/mydir.tfstate`) if existing, then you can utilize the tf.sh script to execute Terraform commands. For example, running `./tf.sh mydir plan`.

  It's important to note that your custom directory, mydir, ***will not*** be included when using the `all` value for components.

* **command**: Supported commands include:
  * `init`: Initializes the Terraform configurations.
  * `plan`: Shows the execution plan of Terraform.
  * `apply`: Applies the Terraform configurations.
  * `destroy`: Destroys the Terraform resources.
  * `output`: Shows the output values of your configurations.
  * `output` `<myoutput>`: Shows a specific output value.
  * `refresh`: Refreshes the Terraform state file.
  * `plan_out`: Generates a plan and writes it to `terraform/${component}-terraform.plan`.
  * `apply_plan`: Applies plan located at `terraform/${component}-terraform.plan`.
  * `roll_nodes`: (Rollout nodes)Runs apply one at a time on `aws_eks_node_group.node_groups` resources.

## Examples

* To preview the execution plan of the cluster:

```bash
./tf.sh cluster plan
```

* To create all components:

```bash
./tf.sh all apply
```

* To destroy all components:

```bash
./tf.sh all destroy
```

* To perform a plan and write it to a file(the plan file will be stored at: `terraform/${component}-terraform.plan`):

```bash
./tf.sh cluster plan_out
```

* To apply a a previously generated plan stored at `terraform/${component}-terraform.plan` for this example `terraform/cluster-terraform.plan`:

```bash
./tf.sh cluster apply_plan
```

## Common Operations

For some frequently performed operations, follow the steps outlined below:

### Initial install
See the repo's [README](../../README.md#bootstrap-module) for how to bootstrap the module.

### Updating the modules' version
See `README` [Update modules version](../../README.md#2-update-modules-version)

### Kubernetes Upgrade:
In order to update Kubernetes we will need to update the `cluster` and the `nodes`.

1. Set the `eks.k8s_version` variable to desired version(At most it can be 2 minor versions ahead.)
2. Update cluster:
   1. Plan and review the changes:
      ```bash
      ./tf.sh cluster plan
      ```
   2. Apply the changes:
      ```bash
      ./tf.sh cluster apply
      ```
3. Update nodes:
Given that the nodes source the k8s version from `eks` we just need to plan and apply.
   1. Plan and review the changes:
      ```bash
      ./tf.sh nodes plan
      ```
   2. Apply the changes:
      ```bash
      ./tf.sh nodes apply
      ```

### Nodes Upgrade:
Given that the nodes module looks for the latest AMI we just need to plan and apply:

1. Plan and review the changes:

```bash
./tf.sh nodes plan
```

2. :warning: In case of large amount of `node_groups` or if just want to update one `node_group` at a time.

```bash
./tf.sh nodes roll_nodes
```
Otherwise to update all `node_groups` in parallel.

```bash
./tf.sh nodes apply
```

### VPC CNI addon upgrade

If Kubernetes has been upgraded without corresponding VPC CNI addon version updates, it might require multiple jumps. VPC CNI only allows a single minor version update per upgrade:
```
Updating VPC-CNI can only go up or down 1 minor version at a time
```

If the next minor version is not supported, it may require deleting the VPC CNI addon while preserving the actual resources:
```
aws eks delete-addon --cluster-name <cluster name> --addon-name vpc-cni --preserve
```

## FIPS 140-2 Compliance
Provision FIPS-compliant resources by utilizing the `use_fips_endpoint` variable in the modules.

:warning: To ensure FIPS 140-2 Compliance, the Kubernetes nodes' image (AMI) must have FIPS enabled.

By setting `use_fips_endpoint: true` , the modules will:

* Set the Terraform AWS provider [use_fips_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#use_fips_endpoint) attribute, ensuring API calls to AWS are made via the FIPS endpoints.
* Set the shell environment variable `AWS_USE_FIPS_ENDPOINT=true` on `local-exec` resources.
* Enable FIPS mode (fipsMode: enabled) during the installation of Calico (see [documentation](https://docs.tigera.io/calico/latest/operations/fips)).
